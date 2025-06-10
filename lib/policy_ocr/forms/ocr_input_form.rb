require_relative '../errors'
require_relative '../models/digit_patterns'
require_relative '../models/policy_number'

module PolicyOcr
  module Forms
    class OcrInputForm
      attr_reader :lines

      def initialize(lines)
        @lines = lines
        validate_input_lines
      end

      def to_policy_number
        Models::PolicyNumber.new(parse)
      end

      private

      def validate_input_lines
        unless @lines.is_a?(Array) && @lines.length == 3
          raise MalformedOcrError, "Input must be an array of 3 lines"
        end

        unless @lines.all? { |line| line.is_a?(String) }
          raise MalformedOcrError, "All lines must be strings"
        end

        unless @lines.map(&:length).uniq.length == 1
          raise MalformedOcrError, "All lines must have the same length"
        end

        unless @lines.first.length % 3 == 0
          raise MalformedOcrError, "Line length must be a multiple of 3"
        end
      end

      def parse
        begin
          # Calculate number of digits based on width
          line_width = @lines.first.length
          num_digits = (line_width / 3.0).ceil

          digits = []

          num_digits.times do |i|
            # Extract 3-character segments from each line
            start_pos = i * 3
            segments = @lines.map { |line| line[start_pos, 3] }

            # Handle nil segments (line too short)
            segments = segments.map { |s| s || "   " }

            # Find the matching digit
            digit = Models::DigitPatterns.find_digit(segments)
            digits << digit
          end

          digits.join
        rescue StandardError => e
          raise InvalidInputError, "Failed to parse policy entry: #{e.message}"
        end
      end
    end
  end
end 