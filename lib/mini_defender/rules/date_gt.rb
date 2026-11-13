# frozen_string_literal: true

require_relative 'date_eq'

class MiniDefender::Rules::DateGt < MiniDefender::Rules::DateEq
  def self.signature
    'date_gt'
  end

  def passes?(attribute, value, validator)
    value = parse_date(value)
    @valid_value = true

    value > @target_date
  rescue ArgumentError, TypeError
    false
  end

  def message(attribute, value, validator)
    return "The given value is not a valid date." unless @valid_value

    "The value must be greater than #{@target_date}."
  end
end
