module PolicyOcr
  module Models
    class DigitPatterns
      # Hash mapping OCR patterns to digits
      OCR_DIGITS = {
        "0" => [
            " _ ",
            "| |",
            "|_|"],
        "1" => [
            "   ",
            "  |",
            "  |"],
        "2" => [
            " _ ",
            " _|",
            "|_ "],
        "3" => [
            " _ ",
            " _|",
            " _|"],
        "4" => [
            "   ",
            "|_|",
            "  |"],
        "5" => [
            " _ ",
            "|_ ",
            " _|"],
        "6" => [
            " _ ",
            "|_ ",
            "|_|"],
        "7" => [
            " _ ",
            "  |",
            "  |"],
        "8" => [
            " _ ",
            "|_|",
            "|_|"],
        "9" => [
            " _ ",
            "|_|",
            " _|"]
      }
      
      def self.find_digit(segments)
        OCR_DIGITS.each do |digit, pattern|
          return digit if segments == pattern
        end
        '?'
      end
    end
  end
end 