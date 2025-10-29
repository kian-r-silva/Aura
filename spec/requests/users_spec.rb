require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a user and redirects" do
      params = { user: { name: 'New', email: 'new@example.com', username: 'newuser', password: 'password123' } }
      post users_path, params: params
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      user = FactoryBot.create(:user)
      get user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

end
