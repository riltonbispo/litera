class BooksController < ApplicationController
  def index
    authorize Book

    books = BookFilter.new(policy_scope(Book).includes(:user), filter_params).call
    paginated_books = books.page(page_param).per(per_page_param)
    props = books_payload(paginated_books)

    respond_to do |format|
      format.html { render inertia: "Books/Index", props: }
      format.json { render json: props }
    end
  end

  private

  def books_payload(books)
    {
      books: BookSerializer.collection(books),
      filters: normalized_filters,
      meta: pagination_meta(books)
    }
  end

  def filter_params
    params.permit(:author, :genre, :first_publish_year, :year)
  end

  def normalized_filters
    {
      author: filter_params[:author].presence,
      genre: filter_params[:genre].presence,
      first_publish_year: filter_params[:first_publish_year].presence || filter_params[:year].presence
    }
  end

  def page_param
    integer_param(:page, default: 1, minimum: 1)
  end

  def per_page_param
    integer_param(:per_page, default: 10, minimum: 1, maximum: 50)
  end

  def integer_param(key, default:, minimum:, maximum: nil)
    value = params[key].to_i
    value = default if value < minimum
    maximum ? [ value, maximum ].min : value
  end

  def pagination_meta(books)
    {
      current_page: books.current_page,
      per_page: books.limit_value,
      total_pages: books.total_pages,
      total_count: books.total_count,
      next_page: books.next_page,
      prev_page: books.prev_page
    }
  end
end
