# frozen_string_literal: true

class MiniDefender::Rules::Iban < MiniDefender::Rule
  LENGTH_MATRIX = {
    'SA' => 24
  }

  REPLACEMENTS = {
    'A' => '10', 'B' => '11', 'C' => '12', 'D' => '13', 'E' => '14', 'F' => '15',
    'G' => '16', 'H' => '17', 'I' => '18', 'J' => '19', 'K' => '20', 'L' => '21',
    'M' => '22', 'N' => '23', 'O' => '24', 'P' => '25', 'Q' => '26', 'R' => '27',
    'S' => '28', 'T' => '29', 'U' => '30', 'V' => '31', 'W' => '32', 'X' => '33',
    'Y' => '34', 'Z' => '35'
  }

  REPLACEMENTS_PATTERN = Regexp.union(REPLACEMENTS.keys)

  def self.signature
    'iban'
  end

  def coerce(value)
    value.to_s.upcase.gsub(/\s/, '')
  end

  def passes?(attribute, value, validator)
    value = coerce(value)
    value.match?(/[A-Z]{2}\d+/i) && valid_length?(value) && valid_checksum?(value)
  end

  def valid_checksum?(iban)
    iban = "#{iban[4..]}#{iban[0..1]}#{iban[2..3]}"
    iban = iban.gsub(REPLACEMENTS_PATTERN, REPLACEMENTS)
    iban.to_i % 97 === 1
  end

  def valid_length?(iban)
    iban.length == (LENGTH_MATRIX[iban[0..1]] || iban.length)
  end

  def message(attribute, value, validator)
    "The value should be a valid IBAN."
  end
end
