# frozen_string_literal: true

module Enumerable
  def flatten_keys(keep_roots: false)
    flatten_keys_recurse(self, keep_roots: keep_roots)
  end

  private

  # Walks the tree once, writing every key straight into a single result hash
  # instead of building and merging a sub-hash per level.
  def flatten_keys_recurse(root, keep_roots: false)
    result = {}

    unless root.is_a?(Enumerable)
      return result
    end

    # Top level keys keep their original type
    if root.is_a?(Hash)
      root.each { |k, v| flatten_keys_entry(result, k, v, keep_roots) }
    else
      root.each_with_index { |v, k| flatten_keys_entry(result, k, v, keep_roots) }
    end

    result
  end

  def flatten_keys_entry(result, key, value, keep_roots)
    unless value.is_a?(Enumerable)
      result[key] = value
      return
    end

    result[key] = value if keep_roots

    # Frozen keys are stored as is, saving the copy Hash#[]= makes otherwise
    if value.is_a?(Hash)
      value.each { |k, v| flatten_keys_entry(result, "#{key}.#{k}".freeze, v, keep_roots) }
    else
      value.each_with_index { |v, k| flatten_keys_entry(result, "#{key}.#{k}".freeze, v, keep_roots) }
    end
  end
end
