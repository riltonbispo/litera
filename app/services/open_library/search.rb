module OpenLibrary
  class Search
    DEFAULT_LIMIT = Client::DEFAULT_LIMIT

    def initialize(client: Client.new)
      @client = client
    end

    def call(title:, limit: DEFAULT_LIMIT)
      payload = client.search(title:, limit:)
      documents = payload.fetch("docs") { raise InvalidResponseError, "OpenLibrary response is missing docs" }
      raise InvalidResponseError, "OpenLibrary docs is not an array" unless documents.is_a?(Array)
      raise EmptyResultsError if documents.empty?

      documents.map { |document| Result.from_document(document) }
    end

    private

    attr_reader :client
  end
end
