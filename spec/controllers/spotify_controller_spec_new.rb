require "rails_helper"

RSpec.describe SpotifyController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
  end

  describe "GET #search" do
    context "when user is not connected to Spotify" do
      it "redirects to root with an alert" do
        allow(controller).to receive(:current_user).and_return(double(spotify_connected: false))

        get :search

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/Connect your Spotify account/i)
      end
    end

    context "when connected but no results" do
      it "assigns an empty array when Spotify returns no tracks" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:spotify_connected).and_return(true)

        client = instance_double("SpotifyClient")
        allow(SpotifyClient).to receive(:new).with(user).and_return(client)
        allow(client).to receive(:search_tracks).with("nothing", limit: 25).and_return([])

        get :search, params: { q: "nothing" }

        tracks = controller.instance_variable_get(:@tracks)
        expect(tracks).to eq([])
        expect(response).to have_http_status(:ok)
      end
    end

    context "when connected and Spotify returns results" do
      it "returns results for query" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:spotify_connected).and_return(true)

        allow_any_instance_of(SpotifyClient).to receive(:search_tracks).and_return([{ 'id' => '1', 'name' => 'Hey Jude' }])

        get :search, params: { q: 'beatles' }

        tracks = controller.instance_variable_get(:@tracks)
        expect(response).to have_http_status(:ok)
        expect(tracks).to be_present
      end
    end
  end

  describe "GET #recent" do
    it "redirects to root when not connected" do
      allow(controller).to receive(:current_user).and_return(double(spotify_connected: false))

      get :recent

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/Connect your Spotify account/i)
    end

    it "rescues errors from the Spotify client and assigns empty tracks with an alert" do
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:spotify_connected).and_return(true)

      client = instance_double("SpotifyClient")
      allow(SpotifyClient).to receive(:new).with(user).and_return(client)
      allow(client).to receive(:recent_tracks).and_raise(StandardError.new("boom"))

      get :recent

      tracks = controller.instance_variable_get(:@tracks)
      expect(tracks).to eq([])
      expect(flash[:alert]).to match(/Could not load recent tracks from Spotify/i)
    end

    it "renders recent and assigns tracks" do
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:spotify_connected).and_return(true)
      allow_any_instance_of(SpotifyClient).to receive(:recent_tracks).and_return([{ 'id' => '1', 'name' => 'Song' }])

      get :recent
      expect(response).to have_http_status(:ok)
      tracks = controller.instance_variable_get(:@tracks)
      expect(tracks).to be_present
    end
  end
end
