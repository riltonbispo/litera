class BookSearchesController < ApplicationController
  MIN_TITLE_LENGTH = 2
  RATE_LIMIT = 30
  RATE_LIMIT_WINDOW = 1.minute

  before_action :authenticate_user!
  rate_limit to: RATE_LIMIT, within: RATE_LIMIT_WINDOW, by: -> { current_user&.id || request.remote_ip },
    with: -> {
      render json: status_payload("rate_limited", "Busca temporariamente limitada. Tente de novo em instantes."),
        status: :too_many_requests
    }

  def show
    if title_param.length < MIN_TITLE_LENGTH
      return render json: status_payload("empty_results", "Digite pelo menos #{MIN_TITLE_LENGTH} letras do titulo.")
    end

    results = OpenLibrary::Search.new.call(title: title_param, limit: limit_param)

    render json: { results: results.map(&:as_json), status: { code: "ok", message: nil } }
  rescue OpenLibrary::Error => e
    render json: status_payload(e.code, e.user_message)
  end

  private

  def title_param
    params[:title].to_s.squish
  end

  def limit_param
    value = params[:limit].to_i
    value = OpenLibrary::Search::DEFAULT_LIMIT if value < 1
    [ value, OpenLibrary::Search::MAX_LIMIT ].min
  end

  def status_payload(code, message)
    {
      results: [],
      status: {
        code: code,
        message: message
      }
    }
  end
end
