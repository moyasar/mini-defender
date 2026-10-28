# frozen_string_literal: true

class MiniDefender::Rules::Boolean < MiniDefender::Rule
  ALLOWED_VALUES = [1, 0, '1', '0', 'yes', 'no', 'on', 'off', 'true', 'false'].freeze

  def self.signature
    'boolean'
  end

  def coerce(value)
    value = value.downcase if value.is_a?(String)
    case value
    when 0, '0', 'no', 'off', 'false'
      false
    when 1, '1', 'yes', 'on', 'true'
      true
    else
      value
    end
  end

  def passes?(attribute, value, validator)
    value = value.downcase if value.is_a?(String)
    value.is_a?(TrueClass) || value.is_a?(FalseClass) ||
      ALLOWED_VALUES.include?(value)
  end

  def message(attribute, value, validator)
    'The value must be a boolean, yes, no, on, off, 0 or 1.'
  end
end
