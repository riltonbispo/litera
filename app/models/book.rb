class Book < ApplicationRecord
  belongs_to :user

  before_validation :normalize_text_attributes

  validates :title, :author, :genre, presence: true
  validates :first_publish_year,
            numericality: {
              only_integer: true,
              less_than_or_equal_to: ->(_book) { Date.current.year }
            },
            allow_nil: true
  validates :cover_id,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :open_library_key, length: { maximum: 255 }, allow_blank: true
  validate :unique_catalog_entry_per_user

  private

  def normalize_text_attributes
    self.title = title&.squish
    self.author = author&.squish
    self.genre = genre&.squish
    self.open_library_key = open_library_key&.squish.presence
  end

  def unique_catalog_entry_per_user
    return if user.blank? || title.blank? || author.blank?

    duplicate = user.books
                    .where("LOWER(title) = ?", title.downcase)
                    .where("LOWER(author) = ?", author.downcase)
                    .where(first_publish_year:)
    duplicate = duplicate.where.not(id:) if persisted?

    errors.add(:base, "Book already exists in your catalog") if duplicate.exists?
  end
end
