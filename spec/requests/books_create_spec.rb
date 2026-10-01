require "rails_helper"

RSpec.describe "Books create", type: :request do
  let(:user) { User.create!(email: "reader@example.com", password: "password123") }

  let(:valid_params) do
    {
      book: {
        title: "Dom Casmurro",
        author: "Machado de Assis",
        first_publish_year: 1899,
        genre: "Romance",
        open_library_key: "/works/OL123W",
        cover_id: 123
      }
    }
  end

  it "requires authentication to create" do
    expect {
      post books_path, params: valid_params
    }.not_to change(Book, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "requires authentication for the new page" do
    get new_book_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the Inertia new page for authenticated users" do
    sign_in user

    get new_book_path

    expect(response).to have_http_status(:ok)
    expect(inertia.component).to eq("Books/New")
  end

  it "creates a book for the current user" do
    sign_in user

    expect {
      post books_path, params: valid_params
    }.to change(user.books, :count).by(1)

    book = user.books.last
    expect(response).to redirect_to(books_path)
    expect(book).to have_attributes(
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      open_library_key: "/works/OL123W",
      cover_id: 123
    )
  end

  it "renders validation errors without creating a book" do
    sign_in user

    expect {
      post books_path, params: { book: valid_params[:book].merge(title: "") }
    }.not_to change(Book, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.component).to eq("Books/New")
    expect(inertia.props[:errors]).to include("book.title")
  end

  it "exposes the year error when the year is not a number" do
    sign_in user

    expect {
      post books_path, params: { book: valid_params[:book].merge(first_publish_year: "abcd") }
    }.not_to change(Book, :count)

    expect(inertia.props[:errors]).to include("book.first_publish_year")
  end

  it "does not create a duplicate for the same user" do
    sign_in user
    user.books.create!(valid_params.fetch(:book))

    expect {
      post books_path, params: valid_params
    }.not_to change(Book, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia.component).to eq("Books/New")
    expect(inertia.props[:errors]).to include("book.base")
  end
end
