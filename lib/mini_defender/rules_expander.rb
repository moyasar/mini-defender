# frozen_string_literal: true

require 'concurrent/map'

module MiniDefender
  class RulesExpander
    PATTERNS_CACHE_LIMIT = 1024

    @patterns = Concurrent::Map.new

    # Compiles a key containing wildcards into an anchored pattern, where each
    # wildcard matches an array index and everything else matches literally,
    # along with the literal text before the first and after the last wildcard.
    # @param [String] key
    # @return [Array(Regexp, String, String)]
    def self.wildcard(key)
      @patterns.fetch(key) do
        # Keep the cache bounded in case keys are built dynamically
        @patterns.clear if @patterns.size >= PATTERNS_CACHE_LIMIT

        parts = key.split('*', -1)
        source = parts.map { |part| Regexp.escape(part) }.join('\d+')

        @patterns.compute_if_absent(key) do
          [Regexp.new("\\A#{source}\\z"), parts.first.freeze, parts.last.freeze].freeze
        end
      end
    end

    # @param [Hash] rules
    # @param [Hash] flat_data
    # @return [Hash]
    def expand(rules, flat_data)
      result = {}
      keys_by_depth = nil

      rules.each do |rule_key, rule_set|
        unless rule_key.include?('*')
          result[rule_key] = rule_set
          next
        end

        # Wildcards never match a dot, so only keys of the same depth can match
        keys_by_depth ||= group_by_depth(flat_data)
        pattern, prefix, suffix = RulesExpander.wildcard(rule_key)
        matched = false

        keys_by_depth[rule_key.count('.')]&.each do |value_key|
          # Cheap checks on the literal ends before running the pattern
          next unless value_key.start_with?(prefix) && value_key.end_with?(suffix) && pattern.match?(value_key)

          result[value_key] = rule_set
          matched = true
        end

        unless matched
          result[rule_key.gsub('*', '0')] = rule_set
        end
      end

      result
    end

    def array_patterns(rules)
      unless rules.is_a?(Hash)
        raise ArgumentError, 'Rules must be a Hash'
      end

      result = rules.keys.filter { |key| key.include?('*') }

      # If the user hasn't add a rule for each of the array elements, add it manually
      rules.each_key do |key|
        next unless key.include?('*')

        current = []
        key.split('.').each do |section|
          current << section
          result << current.join('.') if section == '*'
        end
      end

      result.uniq.map { |key| RulesExpander.wildcard(key).first }
    end

    private

    def group_by_depth(flat_data)
      groups = {}

      flat_data.each_key do |key|
        depth = key.is_a?(String) ? key.count('.') : key.to_s.count('.')
        (groups[depth] ||= []) << key
      end

      groups
    end
  end
end
