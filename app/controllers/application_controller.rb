class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :share_inertia_auth

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def share_inertia_auth
    inertia_share auth: {
      user: current_user && {
        id: current_user.id,
        email: current_user.email,
        initials: current_user.email.first.upcase
      }
    }, flash: {
      notice: flash.notice,
      alert: flash.alert
    }
  end
end
