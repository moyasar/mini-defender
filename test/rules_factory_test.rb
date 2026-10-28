# frozen_string_literal: true

require 'test_helper'

class RulesFactoryTest < Minitest::Test
  def setup
    @factory = MiniDefender::RulesFactory.new
  end

  def test_factory_should_split_and_init_string_rule_sets
    result = @factory.init_set('required|string|max:255')

    assert_equal 3, result.length

    assert_kind_of MiniDefender::Rules::Required, result[0]
    assert_kind_of MiniDefender::Rules::String, result[1]
    assert_kind_of MiniDefender::Rules::Max, result[2]

    assert_equal 255, result[2].instance_variable_get('@size')
  end

  def test_factory_should_init_textual_rules_in_an_array_rule_set
    rules = [
      MiniDefender::Rules::Required.new,
      MiniDefender::Rules::String.new,
      'max:255'
    ]

    result = @factory.init_set(rules)

    assert_equal 3, result.length

    assert_kind_of MiniDefender::Rules::Required, result[0]
    assert_kind_of MiniDefender::Rules::String, result[1]
    assert_kind_of MiniDefender::Rules::Max, result[2]

    assert_equal 255, result[2].instance_variable_get('@size')
  end

  def test_factory_should_find_rules_registered_later
    rule = Class.new(MiniDefender::Rule) do
      def self.signature
        'factory_test_rule'
      end
    end

    assert_raises(ArgumentError) { @factory.init_rule('factory_test_rule') }

    MiniDefender::RulesFactory.register(rule)

    assert_kind_of rule, @factory.init_rule('factory_test_rule')
  ensure
    MiniDefender::RulesFactory.blueprints.delete(rule)
  end

  def test_factory_should_pass_arguments_like_split
    assert_equal %w[a b], @factory.init_rule('in:a,b').instance_variable_get('@values')
    assert_equal %w[a b], @factory.init_rule('in:a,b::').instance_variable_get('@values')
    assert_equal %w[a:b c], @factory.init_rule('in:a:b,c').instance_variable_get('@values')
  end
end
