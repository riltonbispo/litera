module Users
  class RegistrationsController < Devise::RegistrationsController
    def new
      build_resource({})
      set_minimum_password_length

      render inertia: "Auth/Register", props: registration_props
    end

    def create
      build_resource(sign_up_params)
      resource.save
      yield resource if block_given?

      if resource.persisted?
        handle_successful_signup
      else
        clean_up_passwords(resource)
        set_minimum_password_length

        render inertia: "Auth/Register", props: registration_props.merge(
          errors: inertia_errors(resource, scope: "user")
        ), status: :unprocessable_entity
      end
    end

    private

    def handle_successful_signup
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :signed_up_but_inactive
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    end

    def registration_props
      {
        email: resource.email.to_s,
        minimum_password_length: @minimum_password_length
      }
    end
  end
end
