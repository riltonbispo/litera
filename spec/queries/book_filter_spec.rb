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

  it "keeps a total order by breaking created_at ties on descending id" do
    same_instant = Time.utc(2026, 1, 1)
    first = create_book(title: "First", created_at: same_instant)
    second = create_book(title: "Second", created_at: same_instant)
    third = create_book(title: "Third", created_at: same_instant)

    page_one = described_class.new(Book.all, {}).call.page(1).per(2)
    page_two = described_class.new(Book.all, {}).call.page(2).per(2)

    expect(page_one).to eq([ third, second ])
    expect(page_two).to eq([ first ])
    expect((page_one.to_a + page_two.to_a).map(&:id).uniq.size).to eq(3)
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

  it "exposes the resolved filters, collapsing the year alias" do
    filter = described_class.new(Book.all, author: "  Assis  ", genre: " Romance ", year: " 1937 ")

    expect(filter.applied_filters).to eq(author: "Assis", genre: "Romance", first_publish_year: "1937")
  end

  it "exposes blank filters as nil so the form can fall back to its defaults" do
    expect(described_class.new(Book.all, author: "   ").applied_filters).to eq(
      author: nil, genre: nil, first_publish_year: nil
    )
  end
end
