require_relative '../lib/policy_ocr'

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
end
