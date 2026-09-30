module Users
  class SessionsController < Devise::SessionsController
    def new
      self.resource = resource_class.new
      clean_up_passwords(resource)

      render inertia: "Auth/Login", props: {
        email: resource.email.to_s
      }
    end
  end
end
