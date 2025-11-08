require 'rails_helper'

RSpec.describe MusicbrainzController, type: :controller do
  describe 'GET #search' do
    it 'returns empty array when query too short' do
      get :search, params: { q: 'a' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it 'calls MusicbrainzClient and returns results for valid query' do
      results = [{ 'id' => 'r1', 'title' => 'Song' }]
      allow(MusicbrainzClient).to receive(:search_recordings).and_return(results)
      # ensure cache is clear so block executes
      Rails.cache.clear

      get :search, params: { q: 'nirvana' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq(results)
    end
  end
end
