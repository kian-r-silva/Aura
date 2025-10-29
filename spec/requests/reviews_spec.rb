require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  describe "POST /create" do
    it "creates a review for an album and redirects" do
      album = FactoryBot.create(:album)
      user = FactoryBot.create(:user)
      params = { review: { rating: 4, body: 'Nice' }, album_id: album.id }
      # If your controller requires a logged-in user, you may need to set session[:user_id] = user.id
      post album_reviews_path(album), params: params
      expect(response).to have_http_status(:redirect)
    end
  end

end
