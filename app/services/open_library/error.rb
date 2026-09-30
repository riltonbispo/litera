module OpenLibrary
  class Error < StandardError
    attr_reader :code, :user_message

    def initialize(message = nil, code:, user_message:)
      @code = code
      @user_message = user_message
      super(message || user_message)
    end
  end
end
