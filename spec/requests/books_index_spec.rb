require "rails_helper"

RSpec.describe "Books index", type: :request do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123") }
  let(:other_owner) { User.create!(email: "other@example.com", password: "password123") }

  def create_book(attributes = {})
    Book.create!({
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      open_library_key: "/works/OL123W",
      cover_id: 123,
      user: owner
    }.merge(attributes))
  end

  def json_response
    JSON.parse(response.body)
  end

  it "allows anonymous access to the Inertia index" do
    get books_path

    expect(response).to have_http_status(:ok)
  end

  it "allows anonymous access to the JSON index" do
    create_book

    get books_path(format: :json)

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("books").size).to eq(1)
  end

  it "paginates books" do
    create_book(title: "Book 1", created_at: 3.days.ago)
    create_book(title: "Book 2", created_at: 2.days.ago)
    create_book(title: "Book 3", created_at: 1.day.ago)

    get books_path(format: :json), params: { page: 2, per_page: 2 }

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "Book 1" ])
    expect(json_response.fetch("meta")).to include(
      "current_page" => 2,
      "per_page" => 2,
      "total_pages" => 2,
      "total_count" => 3,
      "next_page" => nil,
      "prev_page" => 1
    )
  end


it "normalizes invalid pagination params" do
  create_book

  get books_path(format: :json), params: { page: -5, per_page: 500 }

  expect(json_response.fetch("meta")).to include(
    "current_page" => 1,
    "per_page" => 50
  )
end

it "marks editable books only for their owner" do
  owned_book = create_book(title: "Owned", user: owner)
  other_book = create_book(title: "Other", user: other_owner)
  sign_in owner

  get books_path(format: :json)

  editability = json_response.fetch("books").to_h { |payload| [ payload.fetch("id"), payload.fetch("can_edit") ] }
  expect(editability.fetch(owned_book.id)).to be(true)
  expect(editability.fetch(other_book.id)).to be(false)
end

  it "orders books by creation date descending" do
    create_book(title: "Older", created_at: 2.days.ago)
    create_book(title: "Newer", created_at: 1.day.ago)

    get books_path(format: :json)

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "Newer", "Older" ])
  end

  it "filters by author using partial case-insensitive matching" do
    create_book(title: "Dom Casmurro", author: "Machado de Assis")
    create_book(title: "Mrs Dalloway", author: "Virginia Woolf", first_publish_year: 1925)

    get books_path(format: :json), params: { author: "MACH" }

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "Dom Casmurro" ])
  end

  it "filters by genre" do
    create_book(title: "Dom Casmurro", genre: "Romance")
    create_book(title: "The Hobbit", author: "J. R. R. Tolkien", first_publish_year: 1937, genre: "Fantasy")

    get books_path(format: :json), params: { genre: "Fantasy" }

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "The Hobbit" ])
  end

  it "filters by first publish year" do
    create_book(title: "Dom Casmurro", first_publish_year: 1899)
    create_book(title: "Memorias Postumas", first_publish_year: 1881)

    get books_path(format: :json), params: { first_publish_year: 1881 }

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "Memorias Postumas" ])
  end


it "returns no results for invalid year filters" do
  create_book

  get books_path(format: :json), params: { first_publish_year: "18xx" }

  expect(json_response.fetch("books")).to eq([])
end

  it "combines filters" do
    create_book(title: "Dom Casmurro", author: "Machado de Assis", genre: "Romance", first_publish_year: 1899)
    create_book(title: "Quincas Borba", author: "Machado de Assis", genre: "Romance", first_publish_year: 1891)
    create_book(title: "O Alienista", author: "Machado de Assis", genre: "Satire", first_publish_year: 1882)

    get books_path(format: :json), params: {
      author: "assis",
      genre: "Romance",
      first_publish_year: 1899
    }

    expect(json_response.fetch("books").map { |book| book.fetch("title") }).to eq([ "Dom Casmurro" ])
  end

  it "returns reduced public JSON without owner email" do
    create_book(user: other_owner)

    get books_path(format: :json)

    book = json_response.fetch("books").first
    expect(book).to include(
      "title" => "Dom Casmurro",
      "author" => "Machado de Assis",
      "genre" => "Romance",
      "first_publish_year" => 1899,
      "open_library_key" => "/works/OL123W",
      "cover_id" => 123,
      "owner_id" => other_owner.id
    )
    expect(book).not_to have_key("email")
    expect(book).not_to have_key("user")
    expect(json_response).to have_key("meta")
  end
end
