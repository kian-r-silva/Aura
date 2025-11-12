require 'rails_helper'

RSpec.describe LastfmClient do
  describe '.generate_signature' do
    it 'returns a 32-char md5 hex string and is deterministic' do
      params = { 'api_key' => 'k', 'method' => 'auth.getSession', 'token' => 't' }
      secret = 's3cr3t'

      sig1 = described_class.generate_signature(params, secret)
      sig2 = described_class.generate_signature(params, secret)

      expect(sig1).to be_a(String)
      expect(sig1.length).to eq(32)
      expect(sig1).to eq(sig2)
    end
  end

  describe '.get_session' do
    before do
      @old_key = ENV['LASTFM_API_KEY']
      @old_secret = ENV['LASTFM_SHARED_SECRET']
      ENV['LASTFM_API_KEY'] = 'fakekey'
      ENV['LASTFM_SHARED_SECRET'] = 'shh'
    end

    after do
      ENV['LASTFM_API_KEY'] = @old_key
      ENV['LASTFM_SHARED_SECRET'] = @old_secret
    end

    it 'returns session data when API responds with session' do
      body = { 'session' => { 'key' => 'sesskey', 'name' => 'alice' } }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get).and_return(resp)

      out = described_class.get_session('token123')
      expect(out).to be_a(Hash)
      expect(out[:session_key]).to eq('sesskey')
      expect(out[:username]).to eq('alice')
    end

    it 'returns nil on non-200 or error body' do
      resp = double('resp', status: 500, body: 'err')
      allow(Faraday).to receive(:get).and_return(resp)

      expect(described_class.get_session('token')).to be_nil
    end
  end

  describe 'instance methods: extract_image_url, search_tracks and recent_tracks' do
    before do
      @old_key = ENV['LASTFM_API_KEY']
      @old_secret = ENV['LASTFM_SHARED_SECRET']
      ENV['LASTFM_API_KEY'] = 'fakekey'
      ENV['LASTFM_SHARED_SECRET'] = 'shh'
      @user = User.create!(email: 'lf@example.com', name: 'LF', username: 'lf1', password: 'password')
    end

    after do
      ENV['LASTFM_API_KEY'] = @old_key
      ENV['LASTFM_SHARED_SECRET'] = @old_secret
    end

    it 'extract_image_url handles array and hash' do
      client = described_class.new
      arr = [ { '#text' => 'small' }, { 'size' => 'extralarge', '#text' => 'big.jpg' } ]
      expect(client.send(:extract_image_url, arr)).to eq('big.jpg')

      h = { '#text' => 'single.jpg' }
      expect(client.send(:extract_image_url, h)).to eq('single.jpg')

      expect(client.send(:extract_image_url, nil)).to be_nil
    end

    it 'search_tracks returns mapped tracks' do
      body = { 'results' => { 'trackmatches' => { 'track' => [ { 'name' => 'S', 'artist' => 'A', 'mbid' => 'm1', 'url' => 'http://x', 'image' => [] } ] } } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.search_tracks('q', limit: 1)
      expect(out).to be_an(Array)
      expect(out.first[:name]).to eq('S')
      expect(out.first[:artists]).to eq('A')
    end

    it 'recent_tracks returns [] when user missing session' do
      client = described_class.new(nil)
      expect(client.recent_tracks).to eq([])
    end

    it 'recent_tracks parses track list when authenticated' do
      @user.update!(lastfm_session_key: 'sess', lastfm_username: 'alice')
      # stub api_call to return expected structure
      client = described_class.new(@user)
      resp_body = { 'recenttracks' => { 'track' => [ { 'name' => 'T1', 'artist' => { '#text' => 'Artist' }, 'album' => { '#text' => 'Album' }, 'image' => [], 'url' => 'http://x', 'date' => { '#text' => '2020-01-01' } } ] } }
      allow_any_instance_of(LastfmClient).to receive(:api_call).and_return(resp_body)

      out = client.recent_tracks(limit: 5)
      expect(out).to be_an(Array)
      expect(out.first[:name]).to eq('T1')
      expect(out.first[:artists]).to include('Artist')
    end
  end
end
