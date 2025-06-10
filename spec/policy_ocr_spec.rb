require 'policy_ocr'
require 'fileutils'

def fixture(name)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', "#{name}.txt"))
end

def fixture_path(name)
  File.join(File.dirname(__FILE__), 'fixtures', "#{name}.txt")
end

describe PolicyOcr do
  it "loads" do
    expect(PolicyOcr).to be_a Module
  end

  it 'loads the sample.txt' do
    expect(fixture('sample').lines.count).to eq(44)
  end

  describe '.parse_file' do
    it 'parses policy numbers from a file' do
      sample_path = fixture_path('sample')
      entries = PolicyOcr.parse_file(sample_path)

      expect(entries.size).to eq(11)
      expect(entries.first.to_s).to eq('000000000')
      expect(entries[1].to_s).to eq('111111111')
      expect(entries[2].to_s).to eq('222222222')
      expect(entries[3].to_s).to eq('333333333')
      expect(entries[4].to_s).to eq('444444444')
      expect(entries[5].to_s).to eq('555555555')
      expect(entries[6].to_s).to eq('666666666')
      expect(entries[7].to_s).to eq('777777777')
      expect(entries[8].to_s).to eq('888888888')
      expect(entries[9].to_s).to eq('999999999')
      expect(entries[10].to_s).to eq('123456789')
    end
  end

  describe '.write_output_file' do
    it 'writes policy entries to output file' do
      # Prepare test data
      entries = [
        instance_double(PolicyOcr::PolicyEntry, to_output_line: '123456789'),
        instance_double(PolicyOcr::PolicyEntry, to_output_line: '111111111 ERR'),
        instance_double(PolicyOcr::PolicyEntry, to_output_line: '1234?6789 ILL')
      ]

      output_path = fixture_path('test_output')

      # Write to output file
      PolicyOcr.write_output_file(entries, output_path)

      # Verify the file was created
      expect(File.exist?(output_path)).to be true

      # Read the output file
      content = File.read(output_path)

      # Verify the content of the output file
      expect(content).to eq("123456789\n111111111 ERR\n1234?6789 ILL\n")

      # Clean up
      File.delete(output_path)
    end

    it 'processes policy_numbers_in.txt and writes to policy_numbers_out.txt' do
      input_path = fixture_path('policy_numbers_in')
      output_path = fixture_path('policy_numbers_out')

      # Parse the input file
      entries = PolicyOcr.parse_file(input_path)

      # Write to output file
      PolicyOcr.write_output_file(entries, output_path)

      # Verify file was created
      expect(File.exist?(output_path)).to be true

      # Read the output file
      output_lines = File.readlines(output_path, chomp: true)

      # Verify expected number of entries
      expect(output_lines.size).to eq(3)

      # Verify the content of the output file
      expect(output_lines).to eq([
        '457508000',
        '664371495 ERR',
        '86110??36 ILL'
      ])
    end
  end

  describe 'error handling' do
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
          # Simulate an error in parse method by passing nil
          allow_any_instance_of(PolicyOcr::PolicyEntry).to receive(:parse).and_raise(NoMethodError)
          expect {
            PolicyOcr::PolicyEntry.new(["123", "123", "123"])
          }.to raise_error(PolicyOcr::InvalidInputError, /Failed to parse policy entry/)
        end
      end
    end

    describe '.parse_file' do
      context 'file operations' do
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
    end

    describe '.write_output_file' do
      context 'file operations' do
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
end

describe PolicyOcr::PolicyEntry do
  context 'parsing OCR digits' do
    it 'recognizes digit 0' do
      lines = [
        " _ ",
        "| |",
        "|_|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('0')
    end

    it 'recognizes digit 1' do
      lines = [
        "   ",
        "  |",
        "  |"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('1')
    end

    it 'recognizes digit 2' do
      lines = [
        " _ ",
        " _|",
        "|_ "
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('2')
    end

    it 'recognizes digit 3' do
      lines = [
        " _ ",
        " _|",
        " _|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('3')
    end

    it 'recognizes digit 4' do
      lines = [
        "   ",
        "|_|",
        "  |"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('4')
    end

    it 'recognizes digit 5' do
      lines = [
        " _ ",
        "|_ ",
        " _|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('5')
    end

    it 'recognizes digit 6' do
      lines = [
        " _ ",
        "|_ ",
        "|_|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('6')
    end

    it 'recognizes digit 7' do
      lines = [
        " _ ",
        "  |",
        "  |"
      ]
    end

    it 'recognizes digit 8' do
      lines = [
        " _ ",
        "|_|",
        "|_|"
      ]
    end

    it 'recognizes digit 9' do
      lines = [
        " _ ",
        "|_|",
        " _|"
      ]
    end

    it 'recognizes all digits' do
      lines = [
        "    _  _     _  _  _  _  _ ",
        "  | _| _||_||_ |_   ||_||_|",
        "  ||_  _|  | _||_|  ||_| _|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('123456789')
    end

    it 'handles unknown patterns with a question mark' do
      lines = [
        "   ",
        "   ",
        "   "
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('?')
    end

    it 'marks illegible digits with question marks in policy numbers' do
      lines = [
        " _  _  _ ",
        "|_||  | |",
        "|_||  |_|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('8?0')
    end
  end

  context 'checksum validation' do
    it 'validates policy numbers with a valid checksum' do
      # 345882865 is a valid number: (5*1 + 6*2 + 8*3 + 2*4 + 8*5 + 8*6 + 5*7 + 4*8 + 3*9) = 220 => 220 % 11 = 0
      lines = [
        " _     _  _  _  _  _  _  _ ",
        " _||_||_ |_||_| _||_||_ |_ ",
        " _|  | _||_||_||_ |_||_| _|"
      ]

      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('345882865')
      expect(entry.valid_checksum?).to be true
    end

    it 'identifies policy numbers with an invalid checksum' do
      # 111111111 is not a valid number: (1*1 + 1*2 + 1*3 + 1*4 + 1*5 + 1*6 + 1*7 + 1*8 + 1*9) = 45 => 45 % 11 = 1
      lines = [
        "                           ",
        "  |  |  |  |  |  |  |  |  |",
        "  |  |  |  |  |  |  |  |  |"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('111111111')
      expect(entry.valid_checksum?).to be false
    end

    it 'handles policy numbers with illegible digits' do
      lines = [
        " _  _  _  _  _  _  _  _    ",
        "| || || || || || || || |  |",
        "|_||_||_||_||_||_||_||_|   "
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('00000000?')
      expect(entry.valid_checksum?).to be false
    end

    it 'validates 000000000 as having a valid checksum' do
      # 000000000 is a valid number: (0*1 + 0*2 + 0*3 + 0*4 + 0*5 + 0*6 + 0*7 + 0*8 + 0*9) = 0 => 0 % 11 = 0
      lines = [
        " _  _  _  _  _  _  _  _  _ ",
        "| || || || || || || || || |",
        "|_||_||_||_||_||_||_||_||_|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('000000000')
      expect(entry.valid_checksum?).to be true
    end

    it 'validates 123456789 as having a valid checksum' do
      # 123456789 is a valid number: (9*1 + 8*2 + 7*3 + 6*4 + 5*5 + 4*6 + 3*7 + 2*8 + 1*9) = 165 => 165 % 11 = 0
      lines = [
        "    _  _     _  _  _  _  _ ",
        "  | _| _||_||_ |_   ||_||_|",
        "  ||_  _|  | _||_|  ||_| _|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to eq('123456789')
      expect(entry.valid_checksum?).to be true
    end
  end

  context 'output formatting' do
    it 'formats valid policy numbers with no status' do
      lines = [
        "    _  _     _  _  _  _  _ ",
        "  | _| _||_||_ |_   ||_||_|",
        "  ||_  _|  | _||_|  ||_| _|"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_output_line).to eq('123456789')
    end

    it 'appends ERR to policy numbers with invalid checksum' do
      lines = [
        "                           ",
        "  |  |  |  |  |  |  |  |  |",
        "  |  |  |  |  |  |  |  |  |"
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_output_line).to eq('111111111 ERR')
    end

    it 'appends ILL to policy numbers with illegible digits' do
      lines = [
        " _  _  _  _  _  _  _  _    ",
        "| || || || || || || || |  |",
        "|_||_||_||_||_||_||_||_|   "
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_output_line).to eq('00000000? ILL')
    end

    it 'prioritizes ILL over ERR when both conditions are present' do
      # Create a policy number with an illegible digit
      # Even if the checksum would be invalid, ILL takes precedence
      lines = [
        " _  _        _     _  _    ",
        "|_ |_   |  || |  ||_   |  |",
        "|_||_|  |  ||_|  ||_|  |   "
      ]
      entry = PolicyOcr::PolicyEntry.new(lines)
      expect(entry.to_s).to include('?')
      expect(entry.valid_checksum?).to be false
      expect(entry.to_output_line).to end_with(' ILL')
    end
  end
end
