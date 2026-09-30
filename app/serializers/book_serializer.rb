class BookSerializer
  def self.collection(books)
    books.map { |book| new(book).as_json }
  end

  def initialize(book)
    @book = book
  end

  def as_json(*)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      genre: book.genre,
      first_publish_year: book.first_publish_year,
      open_library_key: book.open_library_key,
      cover_id: book.cover_id,
      owner_id: book.user.id,
      created_at: book.created_at.iso8601
    }
  end

  private

  attr_reader :book
end
