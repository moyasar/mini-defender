# frozen_string_literal: true

require 'countries'

class MiniDefender::Rules::CountryCode < MiniDefender::Rule
  COUNTRIES = ISO3166::Country.pluck(:alpha2).flatten
  COUNTRIES_LOOKUP = COUNTRIES.to_h { |code| [code, true] }.freeze
  private_constant :COUNTRIES_LOOKUP

  def self.signature
    'country_code'
  end

  def coerce(value)
    value.strip.upcase
  end

  def passes?(attribute, value, validator)
    value.is_a?(String) && COUNTRIES_LOOKUP.key?(value.strip.upcase)
  end

  def message(attribute, value, validator)
    'The value must be a valid ISO3166 country code.'
  end
end
