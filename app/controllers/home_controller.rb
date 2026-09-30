class HomeController < ApplicationController
  def index
    render inertia: "Home"
  end

  def ui_test
    render inertia: "ShadcnTest"
  end
end
