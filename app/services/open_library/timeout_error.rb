module OpenLibrary
  class TimeoutError < Error
    def initialize(message = "OpenLibrary request timed out")
      super(
        message,
        code: "timeout",
        user_message: "A OpenLibrary demorou para responder. Voce pode tentar novamente ou cadastrar o livro manualmente."
      )
    end
  end
end
