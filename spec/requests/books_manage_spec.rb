require "rails_helper"

RSpec.describe "Books manage", type: :request do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password123") }
  let!(:book) { create_book(user: owner) }

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

  def valid_params(attributes = {})
    {
      book: {
        title: "Memorias Postumas",
        author: "Machado de Assis",
        first_publish_year: 1881,
        genre: "Romance",
        open_library_key: "/works/OL456W",
        cover_id: 456
      }.merge(attributes)
    }
  end

  it "requires authentication for edit" do
    get edit_book_path(book)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the edit page for the owner" do
    sign_in owner

    get edit_book_path(book)

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Books/Edit")
    expect(inertia.props.fetch("book")).to include("id" => book.id, "can_edit" => true)
  end

  it "redirects a non-owner away from edit" do
    sign_in other_user

    get edit_book_path(book)

    expect(response).to redirect_to(books_path)
  end

  it "updates the owner's book" do
    sign_in owner

    patch book_path(book), params: valid_params

    expect(response).to redirect_to(books_path)
    expect(book.reload).to have_attributes(
      title: "Memorias Postumas",
      first_publish_year: 1881,
      open_library_key: "/works/OL456W",
      cover_id: 456
    )
  end

  it "does not update another user's book" do
    sign_in other_user

    patch book_path(book), params: valid_params(title: "Quincas Borba")

    expect(response).to redirect_to(books_path)
    expect(book.reload.title).to eq("Dom Casmurro")
  end

  it "renders validation errors without updating" do
    sign_in owner

    patch book_path(book), params: valid_params(title: "")

    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.component).to eq("Books/Edit")
    expect(book.reload.title).to eq("Dom Casmurro")
  end

  it "destroys the owner's book" do
    sign_in owner

    expect {
      delete book_path(book)
    }.to change(Book, :count).by(-1)

    expect(response).to redirect_to(books_path)
  end

  it "does not destroy another user's book" do
    sign_in other_user

    expect {
      delete book_path(book)
    }.not_to change(Book, :count)

    expect(response).to redirect_to(books_path)
  end
end
