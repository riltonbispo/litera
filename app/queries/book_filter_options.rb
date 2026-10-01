class BookFilterOptions
  def initialize(scope = Book.all)
    @scope = scope
  end

  def call
    {
      genres: genres,
      years: years
    }
  end

  private

  attr_reader :scope

  def genres
    scope.distinct.order(:genre).pluck(:genre)
  end

  def years
    scope.where.not(first_publish_year: nil).distinct.order(first_publish_year: :desc).pluck(:first_publish_year)
  end
end
