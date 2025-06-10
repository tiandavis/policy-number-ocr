require_relative '../errors'

module PolicyOcr
  module Services
    class FileWriterService
      def initialize(output_file_path)
        @output_file_path = output_file_path
      end

      def write(entries)
        begin
          File.open(@output_file_path, 'w') do |file|
            entries.each do |entry|
              file.puts entry.to_output_line
            end
          end
        rescue SystemCallError => e
          raise FileOperationError, "Failed to write to file '#{@output_file_path}': #{e.message}"
        end
      end
    end
  end
end 