require "rails_helper"

RSpec.describe Book, type: :model do
  let(:user) { User.create!(email: "owner@example.com", password: "password123") }

  def build_book(attributes = {})
    described_class.new({
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      open_library_key: "/works/OL123W",
      user:
    }.merge(attributes))
  end

  it "is valid with required catalog attributes" do
    expect(build_book).to be_valid
  end

  it "requires title, author, genre, and user" do
    book = build_book(title: "", author: "", genre: "", user: nil)

    expect(book).not_to be_valid
    expect(book.errors[:title]).to be_present
    expect(book.errors[:author]).to be_present
    expect(book.errors[:genre]).to be_present
    expect(book.errors[:user]).to be_present
  end

  it "allows optional OpenLibrary metadata" do
    book = build_book(open_library_key: nil, cover_id: nil)

    expect(book).to be_valid
  end

  it "normalizes text before validation" do
    book = build_book(title: "  Dom   Casmurro  ", author: " Machado   de Assis ", genre: " Fiction ")

    book.valid?

    expect(book.title).to eq("Dom Casmurro")
    expect(book.author).to eq("Machado de Assis")
    expect(book.genre).to eq("Fiction")
  end

  it "blocks duplicate books only within the same user catalog" do
    build_book.save!

    duplicate = build_book(title: "dom casmurro", author: "MACHADO DE ASSIS")
    other_user_book = build_book(user: User.create!(email: "other@example.com", password: "password123"))

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:base]).to include("Book already exists in your catalog")
    expect(other_user_book).to be_valid
  end

  it "treats missing first publish year as part of the duplicate key" do
    build_book(first_publish_year: nil).save!

    duplicate = build_book(first_publish_year: nil)

    expect(duplicate).not_to be_valid
  end


it "rejects invalid optional OpenLibrary metadata" do
  book = build_book(open_library_key: "x" * 256, cover_id: -1)

  expect(book).not_to be_valid
  expect(book.errors[:open_library_key]).to be_present
  expect(book.errors[:cover_id]).to be_present
end

it "allows updating the same book without treating itself as a duplicate" do
  book = build_book
  book.save!

  book.genre = "Classics"

  expect(book).to be_valid
end

  it "rejects future first publish years" do
    book = build_book(first_publish_year: Date.current.year + 1)

    expect(book).not_to be_valid
    expect(book.errors[:first_publish_year]).to be_present
  end
end
