# frozen_string_literal: true

require 'test_helper'

class DefaultTest < Minitest::Test
  def setup
    @validator = MiniDefender::Validator.new({
      'name' => 'required|string|max:255',

      'laptop' => 'string|default:macbook',

      'address' => 'required|hash',
      'address.street' => 'required|string|max:255',
      'address.additional' => 'string|max:255',
      'address.country' => 'required|string|max:2',
      'address.components' => 'required|hash',
      'address.components.c1' => 'required|string',
      'address.components.c2' => 'string|default:None',

      'dependents' => 'array',
      'dependents.*.name' => 'string|max:255',
      'dependents.*.needs' => 'array',
      'dependents.*.needs.*.id' => 'integer|min:0',
      'dependents.*.needs.*.description' => 'string|default:None',
    }, {
      'name' => 'John Doe',
      'address' => {
        'street' => '123 Main St',
        'country' => 'SA',
        'components' => {
          'c1' => '1234567890',
        }
      },
      'dependents' => [
        { 'name' => 'Jane Doe', 'needs' => [{ 'id' => 1, 'description' => 'Need 1' }] },
        {
          'name' => 'Jonny Doe', 'needs' => [
            { 'id' => 2, 'description' => 'Need 2' },
            { 'id' => 3, },
          ]
        },
        { 'name' => 'Mary Doe' },
      ]
    })

    @validator.validate!
    @validated = @validator.validated
  end

  def test_default_value_for_root_element_must_be_set
    assert_equal('macbook', @validated['laptop'])
  end

  def test_default_value_for_nested_element_must_be_set
    assert_equal('None', @validated['address']['components']['c2'])
  end

  def test_default_value_for_array_element_must_be_set
    assert_equal('None', @validated['dependents'][1]['needs'][1]['description'])
  end

  def test_default_value_for_array_element_where_parent_does_not_exist_must_not_be_set
    assert_nil(@validated['dependents'][2]['needs'])
  end

  def test_default_value_must_be_set_for_all_array_indexes
    validator = MiniDefender::Validator.new(
      { 'items' => 'array', 'items.*' => 'hash', 'items.*.flag' => 'boolean|default:false' },
      { 'items' => Array.new(12) { {} } }
    )

    assert_equal [false] * 12, validator.coerced['items'].map { |item| item['flag'] }
  end
end
