class BookSerializer
  COVER_BASE_URL = "https://covers.openlibrary.org/b/id"

  def self.collection(books, user: nil)
    books.map { |book| new(book, user:).as_json }
  end

  def initialize(book, user: nil)
    @book = book
    @user = user
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
      cover_url: cover_url,
      owner_id: book.user.id,
      can_edit: BookPolicy.new(user, book).update?,
      created_at: book.created_at.iso8601
    }
  end

  private

  attr_reader :book, :user

  def cover_url
    return if book.cover_id.blank?

    "#{COVER_BASE_URL}/#{book.cover_id}-M.jpg"
  end
end
