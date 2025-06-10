module PolicyOcr
  # Custom error classes for better error categorization
  class PolicyOcrError < StandardError; end
  class FileOperationError < PolicyOcrError; end
  class InvalidInputError < PolicyOcrError; end
  class MalformedOcrError < PolicyOcrError; end
end 