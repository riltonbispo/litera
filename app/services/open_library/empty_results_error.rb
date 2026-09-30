module OpenLibrary
  class EmptyResultsError < Error
    def initialize
      super(
        "OpenLibrary returned no books",
        code: "empty_results",
        user_message: "Nenhum livro foi encontrado na OpenLibrary. Voce pode cadastrar o livro manualmente."
      )
    end
  end
end
