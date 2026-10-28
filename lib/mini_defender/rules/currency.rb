# frozen_string_literal: true

require 'money'

class MiniDefender::Rules::Currency < MiniDefender::Rule
  CURRENCIES = Money::Currency.map(&:iso_code).map(&:upcase).uniq
  CURRENCIES_LOOKUP = CURRENCIES.to_h { |code| [code, true] }.freeze
  private_constant :CURRENCIES_LOOKUP

  def self.signature
    'currency'
  end

  def coerce(value)
    value.strip.upcase
  end

  def passes?(attribute, value, validator)
    value.is_a?(String) && CURRENCIES_LOOKUP.key?(value.strip.upcase)
  end

  def message(attribute, value, validator)
    'The value must be a valid ISO-4217 currency code.'
  end
end
