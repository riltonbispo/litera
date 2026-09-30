require "rails_helper"

RSpec.describe BookFilter do
  let(:user) { User.create!(email: "owner@example.com", password: "password123") }

  def create_book(attributes = {})
    Book.create!({
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      user:
    }.merge(attributes))
  end

  it "returns books ordered by creation date descending by default" do
    older = create_book(title: "Older", created_at: 2.days.ago)
    newer = create_book(title: "Newer", created_at: 1.day.ago)

    expect(described_class.new(Book.all, {}).call).to eq([ newer, older ])
  end

  it "filters by sanitized partial author text" do
    matching = create_book(author: "A_ Percent")
    create_book(title: "Other", author: "Axx Percent", first_publish_year: 1900)

    result = described_class.new(Book.all, author: "A_").call

    expect(result).to eq([ matching ])
  end

  it "filters by genre and year alias" do
    matching = create_book(title: "Matching", genre: "Fantasy", first_publish_year: 1937)
    create_book(title: "Wrong Genre", genre: "Romance", first_publish_year: 1937)
    create_book(title: "Wrong Year", genre: "Fantasy", first_publish_year: 1954)

    result = described_class.new(Book.all, genre: "Fantasy", year: "1937").call

    expect(result).to eq([ matching ])
  end

  it "returns none for non-numeric years" do
    create_book

    expect(described_class.new(Book.all, first_publish_year: "18xx").call).to be_empty
  end
end
