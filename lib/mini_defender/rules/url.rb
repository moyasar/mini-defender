# frozen_string_literal: true

require 'uri'
require 'ipaddr'
require 'public_suffix'

class MiniDefender::Rules::Url < MiniDefender::Rule
  ALLOWED_MODIFIERS = %w[https public not_ip not_private]
  ALLOWED_SCHEMES = %w[http https].freeze

  def initialize(modifiers = [])
    @modifiers = Array(modifiers).map(&:to_s)

    unless @modifiers.empty?
      validate_modifiers!
    end

    @validation_error = nil
  end

  def self.signature
    'url'
  end

  def self.make(modifiers) # no need to raise an error when no modifier is entered; as 'url' rule checks URL structure on its own
    new(modifiers)
  end

  def passes?(attribute, value, validator)
    unless value.is_a?(String)
      return false
    end

    begin
      uri = URI.parse(value)

      if uri.host.blank? || uri.scheme.blank?
        return false
      end

      unless ALLOWED_SCHEMES.include?(uri.scheme)
        @validation_error = 'URL protocol must be HTTP or HTTPS.'
        return false
      end

      if @modifiers.empty?
        return true
      end

      if @modifiers.include?('https') && uri.scheme != 'https'
        @validation_error = 'The URL must use HTTPS.'
        return false
      end

      if @modifiers.include?('public') && (!PublicSuffix.valid?(uri.host) || private_network?(uri.host))
        @validation_error = 'The URL must use a valid public domain.'
        return false
      end

      if @modifiers.include?('not_ip') && ip_address?(uri.host)
        @validation_error = 'IP addresses are not allowed in URLs.'
        return false
      end

      if @modifiers.include?('not_private') && private_network?(uri.host)
        @validation_error = 'Private or reserved resources are not allowed.'
        return false
      end

      true
    rescue URI::InvalidURIError
      @validation_error = 'The field must contain a valid URL.'
      false
    rescue PublicSuffix::Error
      false
    end
  end

  def message(attribute, value, validator)
    @validation_error || 'The field must contain a valid URL.'
  end

  def private_network?(host)
    unless host
      return false
    end

    host = host.downcase

    private_patterns.any? { |pattern| pattern.match?(host) }
  end

  private

  def validate_modifiers!
    invalid_modifiers = @modifiers - ALLOWED_MODIFIERS
    if invalid_modifiers.empty?
      return
    end

    raise ArgumentError, "Invalid URL modifiers: #{invalid_modifiers.join(', ')}"
  end

  def ip_address?(host)
    unless host
      return false
    end

    begin
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end

  def private_patterns
    # Cache the result in class variable to avoid loading again
    # across multiple instances
    @@private_patterns ||= begin
      pattern_file = File.expand_path('../data/private_network_patterns.txt', __dir__)

      File.readlines(pattern_file).filter_map do |line|
        line = line.strip

        if line.empty? || line.start_with?('#')
          next
        end

        # Pattern => regex (once)
        pattern = line
          .gsub('.', '\.')           # escape dots
          .gsub('*', '.*')           # wildcards => regex
          .gsub('[0-9]+', '\d+')     # convert number ranges
          .gsub(/\[(.+?)\]/, '(\1)') # convert chars classes

        Regexp.new("^#{pattern}$", Regexp::IGNORECASE)
      end
    end
  end
end
