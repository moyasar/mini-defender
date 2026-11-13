# frozen_string_literal: true

require_relative 'date_eq'

class MiniDefender::Rules::DateGte < MiniDefender::Rules::DateEq
  def self.signature
    'date_gte'
  end

  def passes?(attribute, value, validator)
    value = parse_date(value)
    @valid_value = true

    value >= @target_date
  rescue ArgumentError, TypeError
    false
  end

  def message(attribute, value, validator)
    return "The given value is not a valid date." unless @valid_value

    "The value must be greater than or equal to #{@target_date}."
  end
end
