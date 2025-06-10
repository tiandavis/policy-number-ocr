require 'spec_helper'

RSpec.describe PolicyOcr do
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
end 