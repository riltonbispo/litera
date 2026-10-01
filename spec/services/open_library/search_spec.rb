require "rails_helper"

RSpec.describe OpenLibrary::Search do
  subject(:search) { described_class.new }

  let(:open_library_url) { "https://openlibrary.org/search.json" }
  let(:default_query) do
    {
      title: "Dom Casmurro",
      limit: "10",
      fields: "key,title,author_name,first_publish_year,subject,cover_i"
    }
  end

  def stub_search(response)
    stub_request(:get, open_library_url)
      .with(query: default_query)
      .to_return(response)
  end

  it "normalizes successful OpenLibrary results" do
    stub_search(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        docs: [
          {
            key: "/works/OL123W",
            title: "Dom Casmurro",
            author_name: [ "Machado de Assis", "Another Author" ],
            first_publish_year: 1899,
            subject: [ "Fiction", "Brazil" ],
            cover_i: 12345
          }
        ]
      }.to_json
    )

    result = search.call(title: "Dom Casmurro").first

    expect(result.as_json).to eq(
      key: "/works/OL123W",
      title: "Dom Casmurro",
      author: "Machado de Assis",
      year: 1899,
      subjects: [ "Fiction", "Brazil" ],
      cover_id: 12345,
      cover_url: "https://covers.openlibrary.org/b/id/12345-M.jpg"
    )
  end

  it "treats an empty list as a distinct friendly error" do
    stub_search(status: 200, body: { docs: [] }.to_json)

    expect { search.call(title: "Dom Casmurro") }
      .to raise_error(OpenLibrary::EmptyResultsError) { |error|
        expect(error.code).to eq("empty_results")
        expect(error.user_message).to include("Nenhum livro")
      }
  end

  it "treats timeouts as a distinct friendly error" do
    stub_request(:get, open_library_url).with(query: default_query).to_timeout

    expect { search.call(title: "Dom Casmurro") }
      .to raise_error(OpenLibrary::TimeoutError) { |error|
        expect(error.code).to eq("timeout")
        expect(error.user_message).to include("demorou")
      }
  end

  it "treats 5xx responses as a distinct friendly error" do
    stub_search(status: 500, body: "Internal Server Error")

    expect { search.call(title: "Dom Casmurro") }
      .to raise_error(OpenLibrary::ServerError) { |error|
        expect(error.code).to eq("server_error")
        expect(error.user_message).to include("erro temporario")
      }
  end

  it "treats malformed JSON as a distinct friendly error" do
    stub_search(status: 200, body: "{not-json")

    expect { search.call(title: "Dom Casmurro") }
      .to raise_error(OpenLibrary::InvalidResponseError) { |error|
        expect(error.code).to eq("invalid_response")
        expect(error.user_message).to include("Nao foi possivel ler")
      }
  end

  it "treats 4xx responses as unavailable" do
  stub_search(status: 429, body: "Too Many Requests")

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::UnavailableError) { |error|
      expect(error.code).to eq("unavailable")
      expect(error.user_message).to include("indisponivel")
    }
end

  it "treats non-timeout connection failures as unavailable" do
  stub_request(:get, open_library_url)
    .with(query: default_query)
    .to_raise(Faraday::ConnectionFailed.new("network down"))

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::UnavailableError) { |error|
      expect(error.code).to eq("unavailable")
    }
end

  it "treats a payload that is not an object as an invalid response" do
  stub_search(status: 200, body: [ { key: "/works/OL123W" } ].to_json)

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::InvalidResponseError, /not an object/)
end

  it "treats a scalar payload as an invalid response" do
  stub_search(status: 200, body: "not json at all".to_json)

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::InvalidResponseError)
end

  it "treats missing docs as an invalid response" do
  stub_search(status: 200, body: { num_found: 1 }.to_json)

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::InvalidResponseError, /missing docs/)
end

  it "treats non-array docs as an invalid response" do
  stub_search(status: 200, body: { docs: {} }.to_json)

  expect { search.call(title: "Dom Casmurro") }
    .to raise_error(OpenLibrary::InvalidResponseError, /not an array/)
end

  it "normalizes books with missing author, year, subjects, and cover" do
    stub_search(
      status: 200,
      body: {
        docs: [
          {
            key: "/works/OL999W",
            title: "Untitled Fragment"
          }
        ]
      }.to_json
    )

    result = search.call(title: "Dom Casmurro").first

    expect(result.as_json).to eq(
      key: "/works/OL999W",
      title: "Untitled Fragment",
      author: nil,
      year: nil,
      subjects: [],
      cover_id: nil,
      cover_url: nil
    )
  end
end
