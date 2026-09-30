require "json"

module OpenLibrary
  class Client
    BASE_URL = "https://openlibrary.org"
    SEARCH_PATH = "/search.json"
    SEARCH_FIELDS = "key,title,author_name,first_publish_year,subject,cover_i"
    DEFAULT_LIMIT = 10
    DEFAULT_TIMEOUT = 2
    DEFAULT_OPEN_TIMEOUT = 1

    def initialize(connection: nil)
      @connection = connection || default_connection
    end

    def search(title:, limit: DEFAULT_LIMIT)
      response = connection.get(SEARCH_PATH, search_params(title:, limit:))
      handle_response(response)
    rescue Faraday::TimeoutError
      raise TimeoutError
    rescue Faraday::ConnectionFailed => e
      raise TimeoutError if timeout_connection_error?(e)

      raise UnavailableError, e.message
    end

    private

    attr_reader :connection

    def default_connection
      Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.timeout = DEFAULT_TIMEOUT
        faraday.options.open_timeout = DEFAULT_OPEN_TIMEOUT
      end
    end

    def search_params(title:, limit:)
      {
        title: title.to_s,
        limit: limit.to_i,
        fields: SEARCH_FIELDS
      }
    end

    def timeout_connection_error?(error)
      error.message.include?("execution expired") || error.cause.is_a?(Timeout::Error)
    end

    def handle_response(response)
      raise ServerError, response.status if response.status >= 500
      raise UnavailableError, "OpenLibrary returned HTTP #{response.status}" unless response.success?

      parse_json(response.body)
    end

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise InvalidResponseError, e.message
    end
  end
end
