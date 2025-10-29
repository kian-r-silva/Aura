require 'rails_helper'

RSpec.describe "Albums", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get albums_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      album = FactoryBot.create(:album)
      get album_path(album)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_album_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates an album and redirects" do
      params = { album: { title: "New Album", artist: "Artist" } }
      post albums_path, params: params
      expect(response).to have_http_status(:redirect)
    end
  end

end
