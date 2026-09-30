class BookSearchesController < ApplicationController
  before_action :authenticate_user!

  def show
    results = OpenLibrary::Search.new.call(title: title_param, limit: limit_param)
    render json: success_payload(results)
  rescue OpenLibrary::Error => e
    render json: error_payload(e)
  end

  private

  def title_param
    params[:title].to_s.squish
  end

  def limit_param
    value = params[:limit].to_i
    value = OpenLibrary::Search::DEFAULT_LIMIT if value < 1
    [ value, 20 ].min
  end

  def success_payload(results)
    {
      results: results.map(&:as_json),
      status: {
        code: "ok",
        message: nil
      }
    }
  end

  def error_payload(error)
    {
      results: [],
      status: {
        code: error.code,
        message: error.user_message
      }
    }
  end
end
