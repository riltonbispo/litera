module OpenLibrary
  Result = Data.define(:key, :title, :author, :year, :subjects, :cover_id, :cover_url) do
    COVER_BASE_URL = "https://covers.openlibrary.org/b/id"

    def self.from_document(document)
      cover_id = normalize_integer(document["cover_i"])

      new(
        key: document["key"].presence,
        title: document["title"].presence,
        author: Array(document["author_name"]).compact_blank.first,
        year: normalize_integer(document["first_publish_year"]),
        subjects: Array(document["subject"]).compact_blank,
        cover_id:,
        cover_url: cover_url(cover_id)
      )
    end

    def as_json(*)
      {
        key:,
        title:,
        author:,
        year:,
        subjects:,
        cover_id:,
        cover_url:
      }
    end

    def self.normalize_integer(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def self.cover_url(cover_id)
      return if cover_id.blank?

      "#{COVER_BASE_URL}/#{cover_id}-M.jpg"
    end
  end
end
