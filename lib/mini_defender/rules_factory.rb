# frozen_string_literal: true

module MiniDefender
  class RulesFactory
    def self.blueprints
      @@blueprints ||= []
    end

    def self.register(klass)
      blueprints << klass
    end

    # Finds the first available blueprint registered under the given signature.
    # The signature index is rebuilt whenever the blueprints list changes size,
    # so rules registered at any time are picked up.
    def self.find_blueprint(name)
      list = blueprints

      if @index_size != list.length
        @index = list.group_by(&:signature)
        @index_size = list.length
      end

      candidates = @index[name]
      return nil if candidates.nil?

      candidates.each { |b| return b if b.available? }
      nil
    end

    def init_set(rule_set)
      if rule_set.is_a?(String)
        rule_set = rule_set.split('|')
      end

      unless rule_set.is_a?(Array)
        raise ArgumentError, 'Rule set must be a string or an array'
      end

      rule_set = rule_set.map do |rule|
        unless rule.is_a?(String) || rule.is_a?(Rule)
          raise ArgumentError, 'Rule must be a string or an instance of MiniDefender::Rule'
        end

        rule.is_a?(String) ? init_rule(rule) : rule
      end

      # Equal priorities would come back from sort_by! unchanged, skip the work
      priority = rule_set.first&.priority

      if rule_set.all? { |r| r.priority == priority }
        return rule_set
      end

      rule_set.sort_by! { |r| r.priority }
    end

    def init_rule(signature)
      separator = signature.index(':')
      name = separator.nil? ? signature : signature[0, separator]

      blueprint = RulesFactory.find_blueprint(name)
      raise ArgumentError, "The rule name #{name} is invalid or not available" if blueprint.nil?

      if separator.nil?
        return blueprint.make([])
      end

      args = signature[separator + 1, signature.length]

      # Match String#split semantics, which drop trailing empty arguments
      args = args.sub(/:+\z/, '') if args.end_with?(':')

      blueprint.make(args.split(','))
    end
  end
end
