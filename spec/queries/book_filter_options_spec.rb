require "rails_helper"

RSpec.describe BookFilterOptions do
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

  it "returns distinct genres in alphabetical order" do
    create_book(title: "A", genre: "Romance")
    create_book(title: "B", author: "B", first_publish_year: 1900, genre: "Fantasy")
    create_book(title: "C", author: "C", first_publish_year: 1901, genre: "Romance")

    expect(described_class.new.call.fetch(:genres)).to eq(%w[Fantasy Romance])
  end

  it "returns distinct years in descending order and skips books without one" do
    create_book(title: "A", first_publish_year: 1899)
    create_book(title: "B", author: "B", first_publish_year: 1925)
    create_book(title: "C", author: "C", first_publish_year: 1899)
    create_book(title: "D", author: "D", first_publish_year: nil)

    expect(described_class.new.call.fetch(:years)).to eq([ 1925, 1899 ])
  end

  it "restricts the options to the given scope" do
    mine = create_book(title: "Mine", genre: "Fantasy")
    create_book(title: "Theirs", author: "Other", first_publish_year: 1900, genre: "Satire")

    options = described_class.new(Book.where(id: mine.id)).call

    expect(options.fetch(:genres)).to eq([ "Fantasy" ])
  end
end
