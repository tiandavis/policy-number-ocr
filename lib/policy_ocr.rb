require_relative 'policy_ocr/errors'
require_relative 'policy_ocr/models/digit_patterns'
require_relative 'policy_ocr/models/policy_number'
require_relative 'policy_ocr/forms/ocr_input_form'
require_relative 'policy_ocr/services/file_parser_service'
require_relative 'policy_ocr/services/file_writer_service'

module PolicyOcr
  class PolicyEntry
    attr_reader :policy_number

    def initialize(lines)
      begin
        @policy_number = Forms::OcrInputForm.new(lines).to_policy_number
      rescue MalformedOcrError => e
        raise e
      rescue StandardError => e
        raise InvalidInputError, "Failed to parse policy entry: #{e.message}"
      end
    end

    def to_s
      @policy_number.to_s
    end

    def valid_checksum?
      @policy_number.valid_checksum?
    end

    def to_output_line
      @policy_number.to_output_line
    end
  end

  # Parse policy entries from a file
  def self.parse_file(file_path)
    parser = Services::FileParserService.new(file_path)
    parser.parse
  end

  # Write policy entries to output file
  def self.write_output_file(entries, output_file_path)
    writer = Services::FileWriterService.new(output_file_path)
    writer.write(entries)
  end
end
