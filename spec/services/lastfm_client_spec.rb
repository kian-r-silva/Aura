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

    it 'search_tracks returns empty array on API error' do
      allow_any_instance_of(LastfmClient).to receive(:api_call).and_return(nil)
      client = described_class.new
      expect(client.search_tracks('query')).to eq([])
    end

    it 'search_tracks returns empty array on blank query' do
      client = described_class.new
      expect(client.search_tracks('')).to eq([])
      expect(client.search_tracks(nil)).to eq([])
    end

    it 'search_tracks handles single track response' do
      body = { 'results' => { 'trackmatches' => { 'track' => { 'name' => 'Single', 'artist' => 'Solo', 'mbid' => 'm1', 'url' => 'http://x', 'image' => [] } } } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.search_tracks('q')
      expect(out).to be_an(Array)
      expect(out.length).to eq(1)
      expect(out.first[:name]).to eq('Single')
    end

    it 'recent_tracks returns empty array on API error' do
      @user.update!(lastfm_session_key: 'sess', lastfm_username: 'alice')
      allow_any_instance_of(LastfmClient).to receive(:api_call).and_return(nil)
      
      client = described_class.new(@user)
      expect(client.recent_tracks).to eq([])
    end

    it 'recent_tracks handles single track response' do
      @user.update!(lastfm_session_key: 'sess', lastfm_username: 'alice')
      client = described_class.new(@user)
      resp_body = { 'recenttracks' => { 'track' => { 'name' => 'Single', 'artist' => { '#text' => 'Artist' }, 'album' => { '#text' => 'Album' }, 'image' => [], 'url' => 'http://x', 'date' => { '#text' => '2020-01-01' } } } }
      allow_any_instance_of(LastfmClient).to receive(:api_call).and_return(resp_body)

      out = client.recent_tracks
      expect(out).to be_an(Array)
      expect(out.length).to eq(1)
    end

    it 'recent_tracks constructs external_url when missing' do
      @user.update!(lastfm_session_key: 'sess', lastfm_username: 'alice')
      client = described_class.new(@user)
      resp_body = { 'recenttracks' => { 'track' => [ { 'name' => 'Track', 'artist' => { '#text' => 'Artist Name' }, 'album' => { '#text' => 'Album' }, 'image' => [], 'date' => { '#text' => '2020-01-01' } } ] } }
      allow_any_instance_of(LastfmClient).to receive(:api_call).and_return(resp_body)

      out = client.recent_tracks
      expect(out.first[:external_url]).to include('Artist+Name')
      expect(out.first[:external_url]).to include('Track')
    end
  end

  describe '#track_similar' do
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

    it 'returns similar tracks for valid artist and track' do
      body = { 'similartracks' => { 'track' => [ { 'name' => 'Similar1', 'artist' => { 'name' => 'Artist' }, 'url' => 'http://similar1' } ] } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.track_similar('Artist', 'Track', limit: 5)
      expect(out).to be_an(Array)
      expect(out.first[:name]).to eq('Similar1')
      expect(out.first[:artist]).to eq('Artist')
    end

    it 'returns empty array when artist missing' do
      client = described_class.new
      expect(client.track_similar(nil, 'Track')).to eq([])
    end

    it 'returns empty array when track missing' do
      client = described_class.new
      expect(client.track_similar('Artist', nil)).to eq([])
    end

    it 'returns empty array when API returns no similar tracks' do
      body = { 'similartracks' => {} }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      expect(client.track_similar('Artist', 'Track')).to eq([])
    end

    it 'handles single similar track response' do
      body = { 'similartracks' => { 'track' => { 'name' => 'Single', 'artist' => { 'name' => 'A' }, 'url' => 'http://x' } } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.track_similar('Artist', 'Track')
      expect(out).to be_an(Array)
      expect(out.length).to eq(1)
    end

    it 'handles artist as text field instead of object' do
      body = { 'similartracks' => { 'track' => [ { 'name' => 'S', 'artist' => { '#text' => 'TextArtist' }, 'url' => 'http://x' } ] } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.track_similar('Artist', 'Track')
      expect(out.first[:artist]).to eq('TextArtist')
    end

    it 'handles artist as string' do
      body = { 'similartracks' => { 'track' => [ { 'name' => 'S', 'artist' => { 'name' => 'StringArtist' }, 'url' => 'http://x' } ] } }
      resp = double('resp', status: 200, body: body.to_json)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      out = client.track_similar('Artist', 'Track')
      expect(out.first[:artist]).to eq('StringArtist')
    end
  end

  describe '#api_call' do
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

    it 'returns nil when API returns non-200 status' do
      resp = double('resp', status: 500, body: '{}')
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_nil
    end

    it 'returns nil when API returns error in body' do
      body = { 'error' => 6, 'message' => 'Track not found' }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_nil
    end

    it 'returns parsed JSON on success' do
      body = { 'track' => { 'name' => 'Test' } }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_a(Hash)
      expect(result['track']['name']).to eq('Test')
    end

    it 'includes signature for authenticated calls' do
      @user.update!(lastfm_session_key: 'sess123')
      client = described_class.new(@user)

      body = { 'user' => { 'name' => 'alice' } }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get) do |uri|
        expect(uri).to include('api_sig=')
        expect(uri).to include('sk=sess123')
        resp
      end

      result = client.send(:api_call, { 'method' => 'user.getInfo' }, authenticated: true)
      expect(result).to be_a(Hash)
    end

    it 'returns nil when authenticated call without session' do
      client = described_class.new
      result = client.send(:api_call, { 'method' => 'user.getInfo' }, authenticated: true)
      expect(result).to be_nil
    end

    it 'returns nil when API_KEY is not set' do
      old_key = ENV['LASTFM_API_KEY']
      ENV['LASTFM_API_KEY'] = nil

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_nil

      ENV['LASTFM_API_KEY'] = old_key
    end

    it 'handles Faraday network errors' do
      allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed, 'Network error')

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_nil
    end

    it 'handles JSON parsing errors' do
      resp = double('resp', status: 200, body: 'not valid json')
      allow(Faraday).to receive(:get).and_return(resp)

      client = described_class.new
      result = client.send(:api_call, { 'method' => 'test' })
      expect(result).to be_nil
    end
  end

  describe '.get_session with error responses' do
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

    it 'returns nil when API returns error' do
      body = { 'error' => 4, 'message' => 'Token expired' }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get).and_return(resp)

      result = described_class.get_session('token')
      expect(result).to be_nil
    end

    it 'returns nil when API key/secret missing' do
      ENV['LASTFM_API_KEY'] = nil
      result = described_class.get_session('token')
      expect(result).to be_nil
    end

    it 'returns nil on network error' do
      allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed, 'Connection failed')
      result = described_class.get_session('token')
      expect(result).to be_nil
    end

    it 'returns nil when session data missing in response' do
      body = { 'user' => { 'name' => 'test' } }.to_json
      resp = double('resp', status: 200, body: body)
      allow(Faraday).to receive(:get).and_return(resp)

      result = described_class.get_session('token')
      expect(result).to be_nil
    end
  end
end

