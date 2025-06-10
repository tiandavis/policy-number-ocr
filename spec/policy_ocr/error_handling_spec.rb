require 'spec_helper'

RSpec.describe 'PolicyOcr error handling' do
  describe 'PolicyEntry' do
    context 'input validation' do
      it 'raises MalformedOcrError for non-array input' do
        expect {
          PolicyOcr::PolicyEntry.new("not an array")
        }.to raise_error(PolicyOcr::MalformedOcrError, "Input must be an array of 3 lines")
      end

      it 'raises MalformedOcrError for wrong number of lines' do
        expect {
          PolicyOcr::PolicyEntry.new(["line1", "line2"])
        }.to raise_error(PolicyOcr::MalformedOcrError, "Input must be an array of 3 lines")
      end

      it 'raises MalformedOcrError for non-string lines' do
        expect {
          PolicyOcr::PolicyEntry.new([1, 2, 3])
        }.to raise_error(PolicyOcr::MalformedOcrError, "All lines must be strings")
      end

      it 'raises MalformedOcrError for lines of different lengths' do
        expect {
          PolicyOcr::PolicyEntry.new(["123", "1234", "123"])
        }.to raise_error(PolicyOcr::MalformedOcrError, "All lines must have the same length")
      end

      it 'raises MalformedOcrError for line length not multiple of 3' do
        expect {
          PolicyOcr::PolicyEntry.new(["1234", "1234", "1234"])
        }.to raise_error(PolicyOcr::MalformedOcrError, "Line length must be a multiple of 3")
      end

      it 'raises InvalidInputError for other parsing errors' do
        # Simulate an error during form processing
        allow_any_instance_of(PolicyOcr::Forms::OcrInputForm).to receive(:to_policy_number).and_raise(NoMethodError)
        expect {
          PolicyOcr::PolicyEntry.new(["123", "123", "123"])
        }.to raise_error(PolicyOcr::InvalidInputError, /Failed to parse policy entry/)
      end
    end
  end

  describe 'File operations' do
    context '.parse_file' do
      it 'raises FileOperationError when input file does not exist' do
        expect {
          PolicyOcr.parse_file('nonexistent_file.txt')
        }.to raise_error(PolicyOcr::FileOperationError, /Failed to read file 'nonexistent_file.txt'/)
      end

      it 'raises FileOperationError when input file is not readable' do
        # Create a file and make it unreadable
        test_file = fixture_path('test_unreadable')
        FileUtils.touch(test_file)
        FileUtils.chmod(0o000, test_file)

        expect {
          PolicyOcr.parse_file(test_file)
        }.to raise_error(PolicyOcr::FileOperationError, /Failed to read file/)

        # Clean up
        FileUtils.chmod(0o644, test_file)
        FileUtils.rm(test_file)
      end

      it 'raises MalformedOcrError for invalid OCR format in file' do
        # Create a file with invalid OCR format
        test_file = fixture_path('test_invalid_format')
        File.write(test_file, "invalid\nformat\nhere\n\n")

        expect {
          PolicyOcr.parse_file(test_file)
        }.to raise_error(PolicyOcr::MalformedOcrError, /Error in entry 1/)

        # Clean up
        FileUtils.rm(test_file)
      end
    end

    context '.write_output_file' do
      let(:entries) do
        [
          instance_double(PolicyOcr::PolicyEntry, to_output_line: '123456789'),
          instance_double(PolicyOcr::PolicyEntry, to_output_line: '111111111 ERR')
        ]
      end

      it 'raises FileOperationError when output directory does not exist' do
        expect {
          PolicyOcr.write_output_file(entries, '/nonexistent/dir/output.txt')
        }.to raise_error(PolicyOcr::FileOperationError, /Failed to write to file/)
      end

      it 'raises FileOperationError when output file is not writable' do
        # Create a file and make it unwritable
        test_file = fixture_path('test_unwritable')
        FileUtils.touch(test_file)
        FileUtils.chmod(0o444, test_file)

        expect {
          PolicyOcr.write_output_file(entries, test_file)
        }.to raise_error(PolicyOcr::FileOperationError, /Failed to write to file/)

        # Clean up
        FileUtils.chmod(0o644, test_file)
        FileUtils.rm(test_file)
      end
    end
  end
end 