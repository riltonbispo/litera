module OpenLibrary
  class ServerError < Error
    def initialize(status)
      super(
        "OpenLibrary returned HTTP #{status}",
        code: "server_error",
        user_message: "A OpenLibrary retornou um erro temporario. Voce pode cadastrar o livro manualmente."
      )
    end
  end
end
