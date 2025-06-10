require 'digit_patterns'

module PolicyOcr
  class PolicyEntry
    attr_reader :policy_number

    def initialize(lines)
      @policy_number = parse(lines)
    end

    def to_s
      @policy_number
    end

    private

    def parse(lines)
      # Calculate number of digits based on width
      line_width = lines.first.length
      num_digits = (line_width / 3.0).ceil

      digits = []

      num_digits.times do |i|
        # Extract 3-character segments from each line
        start_pos = i * 3
        segments = lines.map { |line| line[start_pos, 3] }

        # Handle nil segments (line too short)
        segments = segments.map { |s| s || "   " }

        # Find the matching digit
        digit = find_digit(segments)
        digits << digit
      end

      digits.join
    end

    def find_digit(segments)
      OCR_DIGITS.each do |digit, pattern|
        return digit if segments == pattern
      end
      '?'
    end
  end

  def self.parse_file(file_path)
    entries = []
    lines = File.readlines(file_path, chomp: true)

    # Process groups of 4 lines (3 for the OCR, 1 blank)
    lines.each_slice(4) do |line_group|
      # Skip empty groups
      next if line_group.all?(&:empty?)
      entries << PolicyEntry.new(line_group[0..2])
    end

    entries
  end
end
