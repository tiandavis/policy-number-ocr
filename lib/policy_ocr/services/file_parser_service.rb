require_relative '../errors'
require_relative '../forms/ocr_input_form'

module PolicyOcr
  module Services
    class FileParserService
      def initialize(file_path)
        @file_path = file_path
      end

      def parse
        entries = []
        begin
          lines = File.readlines(@file_path, chomp: true)
        rescue SystemCallError => e
          raise FileOperationError, "Failed to read file '#{@file_path}': #{e.message}"
        end

        # Process groups of 4 lines (3 for the OCR, 1 blank)
        lines.each_slice(4).with_index do |line_group, index|
          # Skip empty groups
          next if line_group.all?(&:empty?)

          begin
            ocr_form = Forms::OcrInputForm.new(line_group[0..2])
            entries << ocr_form.to_policy_number
          rescue PolicyOcrError => e
            raise MalformedOcrError, "Error in entry #{index + 1}: #{e.message}"
          end
        end

        entries
      end
    end
  end
end 