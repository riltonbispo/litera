require "rails_helper"

RSpec.describe "Book searches", type: :request do
  let(:user) { User.create!(email: "reader@example.com", password: "password123") }
  let(:open_library_url) { "https://openlibrary.org/search.json" }
  let(:query) do
    {
      title: "Dom Casmurro",
      limit: "5",
      fields: "key,title,author_name,first_publish_year,subject,cover_i"
    }
  end

  def json_response
    JSON.parse(response.body)
  end

  it "requires login" do
    get book_search_path(format: :json), params: { title: "Dom Casmurro" }

    expect(response).to have_http_status(:unauthorized)
    expect(json_response).to eq("error" => "You need to sign in or sign up before continuing.")
  end

  it "returns normalized JSON results for logged-in users" do
    sign_in user
    stub_request(:get, open_library_url).with(query: query).to_return(
      status: 200,
      body: {
        docs: [
          {
            key: "/works/OL123W",
            title: "Dom Casmurro",
            author_name: [ "Machado de Assis" ],
            first_publish_year: 1899,
            subject: [ "Fiction" ],
            cover_i: 12345
          }
        ]
      }.to_json
    )

    get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 5 }

    expect(response).to have_http_status(:ok)
    expect(json_response).to eq(
      "results" => [
        {
          "key" => "/works/OL123W",
          "title" => "Dom Casmurro",
          "author" => "Machado de Assis",
          "year" => 1899,
          "subjects" => [ "Fiction" ],
          "cover_id" => 12345,
          "cover_url" => "https://covers.openlibrary.org/b/id/12345-M.jpg"
        }
      ],
      "status" => {
        "code" => "ok",
        "message" => nil
      }
    )
  end


it "clamps large limits" do
  sign_in user
  stub_request(:get, open_library_url).with(query: query.merge(limit: "20")).to_return(status: 200, body: {
    docs: [ { key: "/works/OL123W", title: "Dom Casmurro" } ]
  }.to_json)

  get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 999 }

  expect(response).to have_http_status(:ok)
  expect(json_response.fetch("results").first).to include("key" => "/works/OL123W")
end

it "returns a manual-entry friendly JSON payload for timeouts" do
  sign_in user
  stub_request(:get, open_library_url).with(query: query).to_timeout

  get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 5 }

  expect(response).to have_http_status(:ok)
  expect(json_response.fetch("results")).to eq([])
  expect(json_response.fetch("status")).to include(
    "code" => "timeout",
    "message" => a_string_including("cadastrar o livro manualmente")
  )
end

  it "returns a manual-entry friendly JSON payload when OpenLibrary has no results" do
    sign_in user
    stub_request(:get, open_library_url).with(query: query).to_return(status: 200, body: { docs: [] }.to_json)

    get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 5 }

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("results")).to eq([])
    expect(json_response.fetch("status")).to include(
      "code" => "empty_results",
      "message" => a_string_including("cadastrar o livro manualmente")
    )
  end

  it "does not call OpenLibrary when the title is too short" do
    sign_in user

    get book_search_path(format: :json), params: { title: "D" }

    expect(response).to have_http_status(:ok)
    expect(a_request(:get, open_library_url)).not_to have_been_made
    expect(json_response.fetch("results")).to eq([])
    expect(json_response.fetch("status")).to include(
      "code" => "empty_results",
      "message" => a_string_including("2 letras")
    )
  end

  it "does not call OpenLibrary when the title is missing or blank" do
    sign_in user

    get book_search_path(format: :json), params: { title: "   " }

    expect(a_request(:get, open_library_url)).not_to have_been_made
    expect(json_response.dig("status", "code")).to eq("empty_results")
  end

  it "rate limits repeated searches from the same user" do
    sign_in user
    stub_request(:get, open_library_url).with(query: query).to_return(status: 200, body: {
      docs: [ { key: "/works/OL123W", title: "Dom Casmurro" } ]
    }.to_json)

    30.times do
      get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 5 }
      expect(response).to have_http_status(:ok)
    end

    get book_search_path(format: :json), params: { title: "Dom Casmurro", limit: 5 }

    expect(response).to have_http_status(:too_many_requests)
    expect(json_response.dig("status", "code")).to eq("rate_limited")
  end
end
