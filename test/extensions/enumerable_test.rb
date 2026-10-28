# frozen_string_literal: true

require 'test_helper'

class EnumerableTest < Minitest::Test
  def test_flatten_keys_should_flatten_nested_hashes_and_arrays
    data = { 'a' => { 'b' => [1, { 'c' => 2 }] }, 'd' => 3 }

    assert_equal({ 'a.b.0' => 1, 'a.b.1.c' => 2, 'd' => 3 }, data.flatten_keys)
  end

  def test_flatten_keys_should_keep_roots_in_order
    data = { 'a' => { 'b' => [1] }, 'd' => [] }
    expected = { 'a' => data['a'], 'a.b' => [1], 'a.b.0' => 1, 'd' => [] }

    assert_equal expected.to_a, data.flatten_keys(keep_roots: true).to_a
  end

  def test_flatten_keys_should_keep_top_level_key_types
    assert_equal({ 0 => 'a', '1.b' => 'c' }, ['a', { 'b' => 'c' }].flatten_keys)
    assert_equal({ a: 1, 'b.c' => 2 }, { a: 1, b: { c: 2 } }.flatten_keys)
  end
end
