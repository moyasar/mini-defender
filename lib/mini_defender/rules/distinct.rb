# frozen_string_literal: true

class MiniDefender::Rules::Distinct < MiniDefender::Rule
  def self.signature
    'distinct'
  end

  def passes?(attribute, value, validator)
    neighbors = validator.neighbors(attribute)
    counts = string_counts(neighbors)

    if counts.nil? || !value.is_a?(String)
      return neighbors.none? { |k, v| k != attribute && v == value }
    end

    # The attribute's own value is part of the counts
    count = counts.fetch(value, 0)
    count -= 1 if neighbors.key?(attribute) && neighbors[attribute] == value
    count == 0
  end

  def message(attribute, value, validator)
    'The value should be unique.'
  end

  private

  # Counts neighbor values when all of them are strings, where counting by hash
  # gives the same result as comparing with ==. The validator hands out the
  # same frozen neighbors to every attribute, so the counts are computed once
  # instead of scanning all neighbors for each attribute.
  def string_counts(neighbors)
    unless neighbors.frozen?
      return nil
    end

    unless @counted.equal?(neighbors)
      @counted = neighbors
      @counts = neighbors.each_value.all? { |v| v.is_a?(String) } ? neighbors.values.tally : nil
    end

    @counts
  end
end
