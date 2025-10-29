require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a session (login) with valid credentials" do
      user = FactoryBot.create(:user)
  post session_path, params: { login: user.username, password: 'password123' }
      # login typically redirects
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /destroy" do
    it "logs out and redirects" do
      delete session_path
      expect(response).to have_http_status(:redirect)
    end
  end

end
