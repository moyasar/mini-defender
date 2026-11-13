# frozen_string_literal: true

require 'time'

class MiniDefender::Rules::DateFormat < MiniDefender::Rule
  def initialize(format)
    raise ArgumentError, 'Format must be a string' unless format.is_a?(String)
    raise ArgumentError, 'Format is required for this rule' if format.empty?

    @format = format
  end

  def self.signature
    'date_format'
  end

  def self.make(args)
    self.new(args[0])
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
    date = Time.strptime(date, @format) unless date.is_a?(Time)
    date
  end
end
