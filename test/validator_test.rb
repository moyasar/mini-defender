# frozen_string_literal: true

require 'test_helper'

class ValidatorTest < Minitest::Test
  def test_should_report_errors_for_invalid_data_1
    v = MiniDefender::Validator.new(
      { 'username' => 'required|string' },
      { 'username' => 123123 }
    )

    assert v.fails?
  end

  def test_should_report_errors_for_invalid_data_2
    v = MiniDefender::Validator.new(
      { 'username' => 'required|string' },
      {  }
    )

    assert v.fails?
  end

  def test_should_report_errors_for_invalid_data_3
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.city' => 'required|string'
      },
      {  }
    )

    assert v.fails?
    assert_equal 2, v.errors.length
  end

  def test_should_report_errors_for_invalid_data_4
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.city' => 'required|string'
      },
      { 'address' => {} }
    )

    assert v.fails?
    assert_equal 2, v.errors.length
  end

  def test_should_report_errors_for_invalid_data_5
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.streets' => 'required|array|size:3',
        'address.streets.*' => 'required|string'
      },
      { 'address' => {} }
    )

    assert v.fails?
    assert_equal 3, v.errors.length
  end

  def test_should_report_errors_for_invalid_data_6
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.streets' => 'required|array|size:3',
        'address.streets.*' => 'required|string'
      },
      {
        'address' => {
          'streets' => [1, '2']
        }
      }
    )

    assert v.fails?
    assert_equal 2, v.errors.length
  end

  def test_should_succeed_when_non_implicit_is_missing
    v = MiniDefender::Validator.new(
      { 'username' => 'string' },
      {  }
    )

    assert v.passes?
  end

  def test_should_report_no_errors_for_valid_data
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.streets' => 'required|array|size:3',
        'address.streets.*' => 'required|integer|distinct'
      },
      {
        'address' => {
          'streets' => ['1', '2', '3']
        }
      }
    )

    assert v.passes?
  end

  def test_should_return_neighbors_of_key_in_array
    v = MiniDefender::Validator.new(
      {},
      {
        'address' => {
          'streets' => ['1', '2', '3']
        }
      }
    )
  end

  def test_only_validated_data_should_be_returned
    v = MiniDefender::Validator.new(
      {
        'address' => 'required|hash',
        'address.is_personal' => 'required|boolean|default:true',
      },
      {
        'address' => {
          'is_personal' => false
        },
        'name' => 'John Doe'
      }
    )

    v.validate!
    data = v.validated

    assert_equal 1, data.length
    assert data['address'].is_a?(Hash)
    assert data['address'].key?('is_personal')
    assert data['address']['is_personal'].is_a?(FalseClass)
  end

  def test_should_not_pass_after_a_rule_raises
    rule = Class.new(MiniDefender::Rule) do
      def passes?(attribute, value, validator)
        raise 'boom'
      end
    end

    v = MiniDefender::Validator.new({ 'a' => 'string', 'b' => [rule.new] }, { 'a' => 'x', 'b' => 'y' })

    assert_raises(RuntimeError) { v.validate }
    assert v.fails?
    assert_equal({ 'a' => [], 'b' => [] }, v.errors)
  end

  def test_should_rebuild_arrays_in_validated_data
    v = MiniDefender::Validator.new(
      { 'items' => 'array', 'items.*' => 'hash', 'items.*.tags' => 'array', 'items.*.tags.*' => 'string' },
      { 'items' => [{ 'tags' => %w[a b] }, { 'tags' => [] }], 'extra' => 1 }
    )

    assert_equal({ 'items' => [{ 'tags' => %w[a b] }, { 'tags' => [] }] }, v.validated)
  end

  def test_should_nest_validated_keys_with_empty_segments
    v = MiniDefender::Validator.new({ 'a.' => 'integer', 'b..c' => 'integer' }, { 'a' => { '' => 1 }, 'b' => { '' => { 'c' => 2 } } })

    assert_equal({ 'a' => 1, 'b' => { '' => { 'c' => 2 } } }, v.validated)
  end
end
