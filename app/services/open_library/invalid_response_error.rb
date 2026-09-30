module OpenLibrary
  class InvalidResponseError < Error
    def initialize(message = "OpenLibrary returned an invalid response")
      super(
        message,
        code: "invalid_response",
        user_message: "Nao foi possivel ler a resposta da OpenLibrary. Voce pode cadastrar o livro manualmente."
      )
    end
  end
end
