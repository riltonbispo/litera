require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:user) { User.create!(email: "reader@example.com", password: "password123") }
  let(:record) { Object.new }

  it "denies all default actions" do
    policy = described_class.new(user, record)

    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.new?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.edit?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it "requires subclasses to define scope resolution" do
    expect {
      described_class::Scope.new(user, Book).resolve
    }.to raise_error(NoMethodError, "You must define #resolve in ApplicationPolicy::Scope")
  end
end
