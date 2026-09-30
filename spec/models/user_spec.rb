require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with Devise-required credentials" do
    user = described_class.new(email: "reader@example.com", password: "password123")

    expect(user).to be_valid
  end

  it "owns books" do
    association = described_class.reflect_on_association(:books)

    expect(association.macro).to eq(:has_many)
    expect(association.options[:dependent]).to eq(:destroy)
  end
end
