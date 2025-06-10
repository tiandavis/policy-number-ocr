require_relative 'digit_patterns'

module PolicyOcr
  class PolicyEntry
    attr_reader :policy_number

    def initialize(lines)
      @policy_number = parse(lines)
    end

    def to_s
      @policy_number
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
      return false if @policy_number.include?('?')

      sum = 0
      digits = @policy_number.chars.map(&:to_i).reverse

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
      if @policy_number.include?('?')
        "#{@policy_number} ILL"
      elsif !valid_checksum?
        "#{@policy_number} ERR"
      else
        @policy_number
      end
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

  # Write policy entries to output file
  # Each entry is formatted according to PolicyEntry#to_output_line
  def self.write_output_file(entries, output_file_path)
    File.open(output_file_path, 'w') do |file|
      entries.each do |entry|
        file.puts entry.to_output_line
      end
    end
  end
end
