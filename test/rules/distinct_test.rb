# frozen_string_literal: true

require 'test_helper'

class DistinctTest < Minitest::Test
  def validate(values)
    v = MiniDefender::Validator.new({ 'items' => 'array', 'items.*' => 'distinct' }, { 'items' => values })
    v.validate
    v
  end

  def test_unique_strings_pass
    assert validate(%w[a b c]).passes?
  end

  def test_duplicate_strings_fail
    v = validate(%w[a b a c])

    assert_equal %w[items.0 items.2], v.errors.keys
  end

  def test_mixed_values_compare_with_equality
    v = validate([1, 1.0, '1', 2])

    assert_equal %w[items.0 items.1], v.errors.keys
  end

  def test_neighbors_are_scoped_to_the_same_parent
    v = MiniDefender::Validator.new(
      { 'groups.*.items.*' => 'distinct' },
      { 'groups' => [{ 'items' => %w[a b] }, { 'items' => %w[a a] }] }
    )
    v.validate

    assert_equal %w[groups.1.items.0 groups.1.items.1], v.errors.keys
  end
end
