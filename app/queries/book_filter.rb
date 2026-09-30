class BookFilter
  def initialize(scope = Book.all, params = {})
    @scope = scope
    @params = params.to_h.symbolize_keys
  end

  def call
    filtered_scope = scope
    filtered_scope = filter_by_author(filtered_scope)
    filtered_scope = filter_by_genre(filtered_scope)
    filtered_scope = filter_by_first_publish_year(filtered_scope)
    filtered_scope.order(created_at: :desc)
  end

  private

  attr_reader :scope, :params

  def filter_by_author(current_scope)
    return current_scope if author.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(author.downcase)}%"
    current_scope.where("LOWER(author) LIKE ?", pattern)
  end

  def filter_by_genre(current_scope)
    return current_scope if genre.blank?

    current_scope.where(genre:)
  end

  def filter_by_first_publish_year(current_scope)
    return current_scope if first_publish_year.blank?
    return current_scope.none unless first_publish_year.match?(/\A\d+\z/)

    current_scope.where(first_publish_year: first_publish_year.to_i)
  end

  def author
    params[:author].to_s.squish.presence
  end

  def genre
    params[:genre].to_s.squish.presence
  end

  def first_publish_year
    (params[:first_publish_year].presence || params[:year].presence).to_s.squish
  end
end
