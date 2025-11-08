require 'rails_helper'

RSpec.describe SpotifyClient, type: :service do
  let(:user) { User.create!(name: 'Spec User', username: 'specuser', email: 'spec@example.com', password: 'password') }
  let(:client) { described_class.new(user) }

  describe '#search_tracks' do
    it 'returns parsed tracks when API responds with results' do
      body = { 'tracks' => { 'items' => [ { 'id' => 't1', 'name' => 'Hey', 'artists' => [{ 'name' => 'A' }], 'album' => { 'name' => 'AL', 'images' => [{ 'url' => 'img' }] }, 'external_urls' => { 'spotify' => 'url' } } ] } }
      resp = double('resp', status: 200, body: body.to_json)

      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_return(resp)

      result = client.search_tracks('hey')
      expect(result).to be_an(Array)
      expect(result.first[:id]).to eq('t1')
      expect(result.first[:artists]).to eq('A')
      expect(result.first[:album]).to eq('AL')
      expect(result.first[:image]).to eq('img')
      expect(result.first[:external_url]).to eq('url')
    end

    it 'returns [] when query blank' do
      expect(client.search_tracks('')).to eq([])
      expect(client.search_tracks(nil)).to eq([])
    end

    it 'returns [] when API returns non-200' do
      resp = double('resp', status: 500, body: 'err')
      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_return(resp)

      expect(client.search_tracks('q')).to eq([])
    end
  end

  describe '#recent_tracks' do
    it 'parses recently played response' do
      body = { 'items' => [ { 'played_at' => 'time', 'track' => { 'id' => 'r1', 'name' => 'Song', 'artists' => [{ 'name' => 'B' }], 'album' => { 'name' => 'ALB', 'images' => [{ 'url' => 'img' }] }, 'external_urls' => { 'spotify' => 'u' } } } ] }
      resp = double('resp', status: 200, body: body.to_json)

      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_return(resp)

      out = client.recent_tracks(limit: 1)
      expect(out).to be_an(Array)
      expect(out.first[:id]).to eq('r1')
      expect(out.first[:played_at]).to eq('time')
    end

    it 'returns [] when API call raises or returns nil' do
      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_raise(StandardError.new('boom'))

      expect(client.recent_tracks).to eq([])
    end
  end

  describe 'api_get refresh behavior' do
    it 'retries after 401 when refresh_token present and refresh succeeds' do
      # prepare user with refresh token
      user.update!(spotify_refresh_token: 'refresh-token')

      resp401 = double('resp401', status: 401, body: 'unauth')
      body200 = { 'tracks' => { 'items' => [] } }
      resp200 = double('resp200', status: 200, body: body200.to_json)

      conn = double('faraday')
      # first get returns 401, second get returns 200
      allow(conn).to receive(:get).and_return(resp401, resp200)
      allow(Faraday).to receive(:new).and_return(conn)

      # stub refresh_token! on the instance to simulate success
      allow_any_instance_of(SpotifyClient).to receive(:refresh_token!).and_return(true)

      result = client.search_tracks('x')
      expect(result).to eq([])
    end
  end
end
