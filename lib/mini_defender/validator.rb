# frozen_string_literal: true

module MiniDefender
  class Validator
    INDEX_PATTERN = /\A\d+\z/
    MISSING = Object.new.freeze

    attr_reader :rules, :data, :errors

    def initialize(rules, data)
      @rules = rules
      @data = data.flatten_keys(keep_roots: true)
      @errors = nil
      @validated = {}
      @coerced = {}
      @expander = RulesExpander.new
      @factory = RulesFactory.new
      @array_patterns = @expander.array_patterns(rules)
      @neighbors_cache = nil
    end

    def validate
      unless @errors.nil?
        return
      end

      @errors = {}

      data_rules = {}
      @rules.each { |k, set| data_rules[k] = @factory.init_set(set) }

      # Set default values for missing data key compared to rules
      defaults_rules = data_rules.filter { |k, set| set.any? { |r| r.defaults?(self) } }
      defaults_rules.each do |key_pattern, set|
        # If element is not inside an array
        unless key_pattern.match?(/\*/)
          if missing_value?(@data[key_pattern])
            @data[key_pattern] = set.map { |r| r.default_value(self) }.reject(&:nil?).first
          end

          next
        end

        parent, sep, child_key = key_pattern.rpartition('*')
        parent += sep

        # If parent or a sibling exists, add the default value
        pattern = RulesExpander.wildcard(parent).first
        additions = {}
        @data.each do |k, _|
          unless k.match?(pattern)
            next
          end

          current_child_key = "#{k}#{child_key}"

          unless missing_value?(@data[current_child_key])
            next
          end

          additions[current_child_key] = set.map { |r| r.default_value(self) }.reject(&:nil?).first
        end

        @data.merge!(additions)
      end

      data_rules = @expander.expand(data_rules, @data)

      # Data does not change from here on, so rules can share neighbor lookups
      @neighbors_cache = {}
      current = errors = nil

      data_rules.each do |k, rule_set|
        current = k
        errors = nil
        value = coerced = @data.fetch(k, MISSING)

        if MISSING.equal?(value)
          if rule_set.any? { |r| r.implicit?(self) }
            @errors[k] = ['This field is missing.']
          end

          next
        end

        value_included = true
        force_coerce = false

        rule_set.each do |rule|
          next unless rule.active?(self)

          value_included &= !rule.excluded?(self)

          if rule.passes?(k, coerced, self)
            coerced = rule.coerce(coerced)
            force_coerce = rule.force_coerce?
          else
            (errors ||= []) << rule.error_message(k, coerced, self)
          end
        end

        unless errors.nil?
          @errors[k] = errors
          next
        end

        if force_coerce
          value = coerced
        end

        if value_included
          @validated[k] = value
          @coerced[k] = coerced
        end
      end
    rescue Exception
      # Only failing keys are recorded, but when a rule raises, leave an entry
      # for every key reached so far, so the validator does not pass afterwards
      unless current.nil?
        partial = {}

        data_rules.each_key do |k|
          if k.equal?(current)
            partial[k] = errors || []
            break
          end

          partial[k] = @errors[k] || []
        end

        @errors = partial
      end

      raise
    ensure
      @neighbors_cache = nil
    end

    def validate!
      validate if @errors.nil?

      unless @errors.empty?
        raise ValidationError.new('Data validation failed', @errors)
      end
    end

    def passes?
      validate if @errors.nil?
      @errors.empty?
    end

    def fails?
      !passes?
    end

    def validated
      validate! if @errors.nil?
      @validated_compacted ||= compact_expanded(@validated)
    end

    def coerced
      validate! if @errors.nil?
      @coerced_compacted = compact_expanded(@coerced)
    end

    # @return [Hash]
    def neighbors(key, level = 1)
      source = leveled_search_source(key, level)

      if @neighbors_cache.nil?
        return find_neighbors(source)
      end

      # Frozen since the same hash is handed to every rule during validation
      @neighbors_cache[source] ||= find_neighbors(source).freeze
    end

    # @return [Array]
    def neighbor_values(key, level = 1)
      neighbors(key, level).values
    end

    private

    def find_neighbors(source)
      pattern = Regexp.compile(source)
      @data.filter { |k, _| k.match?(pattern) }
    end

    def leveled_search_source(key, level = 1)
      search_key = key.split('.').map{ |part| Regexp.quote(part) }.reverse

      # Change array indexes to digits pattern according to the desired level
      while level > 0
        target_index = search_key.index { |p| p.match?(/\A\d+\z/) }
        break if target_index.nil?
        search_key[target_index] = '\d+'
        level -= 1
      end

      "\\A#{search_key.reverse.join('\.')}\\z"
    end

    def compact_expanded(hash)
      expanded = {}

      # Nodes by their key, so that sibling keys do not walk the tree from the
      # root again. Cleared whenever a node gets replaced.
      nodes = {}

      hash.each do |k, v|
        # String#split drops trailing empty keys, which slicing does not
        unless k.is_a?(String) && !k.empty? && !k.end_with?('.')
          expand_key(expanded, k, v)
          nodes.clear
          next
        end

        dot = k.rindex('.')

        if dot.nil?
          nodes.clear if expanded[k].is_a?(Hash)
          expanded[k] = v
          next
        end

        node = expanded_node(expanded, nodes, k[0, dot].freeze)

        if node.nil?
          expand_key(expanded, k, v)
          nodes.clear
          next
        end

        leaf = k[dot + 1, k.length]
        nodes.clear if node[leaf].is_a?(Hash)
        node[leaf] = v
      end

      compact_keys(expanded, [])
    end

    # Finds or creates the hash at the given key, nil when a value that is
    # not a hash is in the way.
    def expanded_node(expanded, nodes, key)
      node = nodes[key]
      return node unless node.nil?

      dot = key.rindex('.')
      parent = dot.nil? ? expanded : expanded_node(expanded, nodes, key[0, dot].freeze)
      return nil if parent.nil?

      child_key = dot.nil? ? key : key[dot + 1, key.length]
      node = (parent[child_key] ||= {})

      if node.is_a?(Array)
        parent[child_key] = node = indexed_hash(node)
      end

      return nil unless node.is_a?(Hash)

      nodes[key] = node
    end

    # Walks the tree from the root, for keys the fast path does not cover
    def expand_key(expanded, k, v)
      keys = k.split('.')
      node = expanded

      while keys.length > 1
        next_key = keys.shift
        next_node = (node[next_key] ||= {})

        if next_node.is_a?(Array)
          node[next_key] = next_node = indexed_hash(next_node)
        end

        node = next_node
      end

      node[keys.shift] = v
    end

    def indexed_hash(array)
      result = {}
      array.each_with_index { |value, index| result[index.to_s] = value }
      result
    end

    # Copies the tree, turning hashes that hold array elements back into arrays.
    # @param [Array] path Keys leading to the current hash
    def compact_keys(hash, path)
      result = {}
      indexes = true

      hash.each do |k, v|
        if v.is_a?(Hash)
          path.push(k)
          v = compact_keys(v, path)
          path.pop
        end

        result[k] = v
        indexes &&= (k.is_a?(String) || k.is_a?(Symbol)) && k.match?(INDEX_PATTERN)
      end

      if result.empty? || !indexes
        return result
      end

      element_key = "#{key_prefix(path)}#{result.each_key.first}"

      unless @array_patterns.any? { |p| p.match?(element_key) }
        return result
      end

      result.values
    end

    def key_prefix(path)
      path.reduce('') { |prefix, k| prefix == '' && k == '' ? '' : "#{prefix}#{k}." }
    end

    def missing_value?(value)
      value.nil? ||
        value.is_a?(String) && value.strip.empty? ||
        value.is_a?(Hash) && value.empty? ||
        value.is_a?(Array) && value.empty?
    end
  end
end
