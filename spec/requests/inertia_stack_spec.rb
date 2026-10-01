require "rails_helper"

RSpec.describe "Inertia-only JS stack", type: :request do
  let(:user) { User.create!(email: "reader@example.com", password: "password123") }

  def create_book(attributes = {})
    Book.create!({
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      open_library_key: "/works/OL123W",
      user: user
    }.merge(attributes))
  end

  describe "GET / (root)" do
    before { get root_path }

    it "renders successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "serves the Inertia page shell" do
      expect(response.body).to include('id="app"')
      expect(response.body).to include("data-inertia")
    end

    it "does not load an import map" do
      expect(response.body).not_to include("javascript_importmap_tags")
      expect(response.body).not_to include('type="importmap"')
      expect(response.body).not_to include("/assets/application")
    end

    it "does not load Turbo or Stimulus" do
      expect(response.body).not_to include("@hotwired/turbo")
      expect(response.body).not_to include("turbo.min.js")
      expect(response.body).not_to include("@hotwired/stimulus")
      expect(response.body).not_to include("stimulus-loading")
      expect(response.body).not_to include("hello_controller")
      expect(response.body).not_to include("data-turbo-track")
    end
  end

  describe "GET /books with the X-Inertia header" do
    let(:inertia_headers) do
      { "X-Inertia" => "true", "X-Inertia-Version" => InertiaRails.configuration.version }
    end

    before do
      3.times do |index|
        create_book(title: "Livro #{index + 1}", created_at: (3 - index).days.ago)
      end
    end

    it "responds with the Inertia component and pagination props" do
      get books_path(page: 2, per_page: 2), headers: inertia_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(response.headers["X-Inertia"]).to eq("true")

      payload = JSON.parse(response.body)

      expect(payload.fetch("component")).to eq("Books/Index")
      expect(payload.fetch("props").fetch("meta")).to include(
        "current_page" => 2,
        "per_page" => 2,
        "total_pages" => 2,
        "total_count" => 3,
        "next_page" => nil,
        "prev_page" => 1
      )
      expect(payload.fetch("props").fetch("books").map { |book| book.fetch("title") }).to eq([ "Livro 1" ])
    end

    it "responds with an HTML shell when the header is absent" do
      get books_path(page: 2, per_page: 2)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.headers["X-Inertia"]).to be_nil
    end
  end
end
