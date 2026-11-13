# frozen_string_literal: true

require 'time'

class MiniDefender::Rules::Date < MiniDefender::Rule
  def self.signature
    'date'
  end

  def passes?(attribute, value, validator)
    parse_date(value).is_a?(Time)
  rescue ArgumentError, TypeError
    false
  end

  def message(attribute, value, validator)
    'The given value is not a valid date.'
  end

  protected

  def parse_date(date)
    date = date.to_time if date.is_a?(Date)
    date = Time.parse(date) unless date.is_a?(Time)
    date
  end
end
