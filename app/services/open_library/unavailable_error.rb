module OpenLibrary
  class UnavailableError < Error
    def initialize(message = "OpenLibrary request failed")
      super(
        message,
        code: "unavailable",
        user_message: "A busca da OpenLibrary esta indisponivel agora. Voce pode cadastrar o livro manualmente."
      )
    end
  end
end
