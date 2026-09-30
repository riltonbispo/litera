require "rails_helper"

RSpec.describe BookPolicy do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123") }
  let(:other_user) { User.create!(email: "other@example.com", password: "password123") }
  let(:book) do
    Book.create!(
      title: "Dom Casmurro",
      author: "Machado de Assis",
      first_publish_year: 1899,
      genre: "Romance",
      user: owner
    )
  end

  it "allows public index and show access" do
    policy = described_class.new(nil, book)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
  end

  it "allows logged-in users to create books" do
    expect(described_class.new(owner, Book).create?).to be(true)
    expect(described_class.new(nil, Book).create?).to be(false)
  end

  it "uses create and update rules for new and edit aliases" do
    expect(described_class.new(owner, Book).new?).to be(true)
    expect(described_class.new(nil, Book).new?).to be(false)
    expect(described_class.new(owner, book).edit?).to be(true)
    expect(described_class.new(other_user, book).edit?).to be(false)
  end

  it "allows only the owner to update and destroy" do
    owner_policy = described_class.new(owner, book)
    other_policy = described_class.new(other_user, book)
    guest_policy = described_class.new(nil, book)

    expect(owner_policy.update?).to be(true)
    expect(owner_policy.destroy?).to be(true)
    expect(other_policy.update?).to be(false)
    expect(other_policy.destroy?).to be(false)
    expect(guest_policy.update?).to be(false)
    expect(guest_policy.destroy?).to be(false)
  end

  it "resolves all books in the public scope" do
    other_book = Book.create!(title: "Mrs Dalloway", author: "Virginia Woolf", genre: "Fiction", user: other_user)

    resolved = described_class::Scope.new(nil, Book).resolve

    expect(resolved).to contain_exactly(book, other_book)
  end
end
