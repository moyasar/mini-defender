# frozen_string_literal: true

module MiniDefender::ValidatesInput
  extend ActiveSupport::Concern

  def validate!(rules, coerced = false)
    data = cleanse_data(params.to_unsafe_hash.deep_stringify_keys)
    validator = MiniDefender::Validator.new(rules, data)
    validator.validate!
    coerced ? validator.coerced : validator.validated
  end

  private

  def cleanse_data(data, depth = 1)
    return data if depth > 16

    # Build each result once instead of copying it again to drop nil values
    case data
      when Array
        result = data.map{ |v| cleanse_data(v, depth + 1) }
        result.compact!
        result
      when Hash
        result = {}
        data.each do |k, v|
          v = cleanse_data(v, depth + 1)
          result[k] = v unless v.nil?
        end
        result
      when String
        data = data.strip
        data = nil if data == ''
        data
      else
        data
    end
  end
end
