require_relative '../errors'

module PolicyOcr
  module Models
    class PolicyNumber
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_s
        @value
      end

      # Calculate Checksum
      # (d1 + (2 * d2) + (3 * d3) + (4 * d4) + (5 * d5) + (6 * d6) + (7 * d7) + (8 * d8) + (9 * d9)) mod 11 = 0
      #
      # Example:
      # Policy Number: 3 4 5 8 8 2 8 6 5
      # Position Names: d9 d8 d7 d6 d5 d4 d3 d2 d1
      #
      # (5*1 + 6*2 + 8*3 + 2*4 + 8*5 + 8*6 + 5*7 + 4*8 + 3*9) = 220 => 220 % 11 = 0
      def valid_checksum?
        return false if @value.include?('?')

        sum = 0
        digits = @value.chars.map(&:to_i).reverse

        digits.each_with_index do |digit, index|
          sum += digit * (index + 1)
        end

        sum % 11 == 0
      end

      # Format policy number with status for output
      # Append 'ILL' if any digit is illegible (?)
      # Append 'ERR' if checksum is invalid
      # Examples:
      # 457508000
      # 664371495 ERR
      # 86110??36 ILL
      def to_output_line
        if @value.include?('?')
          "#{@value} ILL"
        elsif !valid_checksum?
          "#{@value} ERR"
        else
          @value
        end
      end
    end
  end
end 