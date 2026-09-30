require "rails_helper"

RSpec.describe BookSerializer do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password123") }
  let(:book) do
    Book.create!(
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      open_library_key: "/works/OL123W",
      cover_id: 123,
      user: owner
    )
  end

  it "serializes public book fields and owner editability" do
    payload = described_class.new(book, user: owner).as_json

    expect(payload).to include(
      id: book.id,
      title: "Dom Casmurro",
      author: "Machado de Assis",
      genre: "Romance",
      first_publish_year: 1899,
      open_library_key: "/works/OL123W",
      cover_id: 123,
      cover_url: "https://covers.openlibrary.org/b/id/123-M.jpg",
      owner_id: owner.id,
      can_edit: true
    )
    expect(payload.fetch(:created_at)).to eq(book.created_at.iso8601)
  end

  it "does not mark books editable for guests or non-owners" do
    guest_payload = described_class.new(book, user: nil).as_json
    other_payload = described_class.new(book, user: other_user).as_json

    expect(guest_payload.fetch(:can_edit)).to be(false)
    expect(other_payload.fetch(:can_edit)).to be(false)
  end

  it "serializes collections" do
    expect(described_class.collection([ book ], user: owner)).to eq([ described_class.new(book, user: owner).as_json ])
  end
end
