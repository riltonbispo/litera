require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:password) { "password123" }

  describe "POST /users (registration)" do
    it "creates the account and redirects to the catalog" do
      expect {
        post user_registration_path, params: {
          user: { email: "novo@example.com", password: password, password_confirmation: password }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(inertia.props.fetch("flash")).to include("notice" => be_present)
    end

    it "exposes the error when the email is already taken" do
      User.create!(email: " taken@example.com ".strip, password: password)

      expect {
        post user_registration_path, params: {
          user: { email: "taken@example.com", password: password, password_confirmation: password }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("Auth/Register")
      expect(inertia.props.fetch("errors")).to include("user.email")
    end

    it "exposes the error when the password is too short" do
      expect {
        post user_registration_path, params: {
          user: { email: "curto@example.com", password: "123", password_confirmation: "123" }
        }
      }.not_to change(User, :count)

      expect(inertia.props.fetch("errors")).to include("user.password")
    end

    it "exposes the error when the confirmation does not match" do
      post user_registration_path, params: {
        user: { email: "diff@example.com", password: password, password_confirmation: "outro123" }
      }

      expect(inertia.props.fetch("errors")).to include("user.password_confirmation")
    end
  end

  describe "POST /users/sign_in (session)" do
    let!(:user) { User.create!(email: "reader@example.com", password: password) }

    it "signs the user in and redirects to the catalog" do
      post user_session_path, params: { user: { email: user.email, password: password } }

      expect(response).to redirect_to(root_path)
    end

    it "reports invalid credentials through the shared flash" do
      post user_session_path, params: { user: { email: user.email, password: "errada" } },
        headers: { "X-Inertia" => "true", "X-Inertia-Version" => InertiaRails.configuration.version }

      expect(response).to have_http_status(:unprocessable_content)
      expect(inertia.component).to eq("Auth/Login")
      expect(inertia.props.fetch("flash")).to include("alert" => be_present)
    end
  end

  describe "DELETE /users/sign_out" do
    it "signs the user out" do
      user = User.create!(email: "sai@example.com", password: password)
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /users/sign_up" do
    it "renders the registration page with the minimum password length" do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Auth/Register")
      expect(inertia.props).to include("minimum_password_length")
    end
  end

  describe "GET /users/sign_in" do
    it "renders the login page" do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(inertia.component).to eq("Auth/Login")
    end
  end
end
