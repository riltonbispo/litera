class BooksController < ApplicationController
  before_action :authenticate_user!, except: :index
  before_action :set_book, only: %i[edit update destroy]

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

  def new
    authorize Book

    render inertia: "Books/New", props: form_options
  end

  def create
    @book = current_user.books.build(book_params)
    authorize @book

    if @book.save
      redirect_to books_path, notice: "Livro cadastrado com sucesso."
    else
      render inertia: "Books/New", props: form_options, status: :unprocessable_entity
    end
  end

  def edit
    authorize @book

    render inertia: "Books/Edit", props: form_options.merge(book: BookSerializer.new(@book, user: current_user).as_json)
  end

  def update
    authorize @book

    if @book.update(book_params)
      redirect_to books_path, notice: "Livro atualizado com sucesso."
    else
      render inertia: "Books/Edit", props: form_options.merge(book: BookSerializer.new(@book, user: current_user).as_json), status: :unprocessable_entity
    end
  end

  def destroy
    authorize @book

    @book.destroy!
    redirect_to books_path, notice: "Livro removido com sucesso.", status: :see_other
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def books_payload(books)
    {
      books: BookSerializer.collection(books, user: current_user),
      filters: normalized_filters,
      filter_options: filter_options,
      meta: pagination_meta(books)
    }
  end

  def form_options
    {
      genre_options: Book.distinct.order(:genre).pluck(:genre)
    }
  end

  def book_params
    params.require(:book).permit(:title, :author, :first_publish_year, :genre, :open_library_key, :cover_id)
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

  def filter_options
    {
      genres: Book.distinct.order(:genre).pluck(:genre),
      years: Book.where.not(first_publish_year: nil).distinct.order(first_publish_year: :desc).pluck(:first_publish_year)
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
