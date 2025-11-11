require 'rails_helper'

RSpec.describe MusicbrainzClient do
  describe '.search_recordings' do
    let(:conn) { double('faraday_conn') }

    before do
      allow(Faraday).to receive(:new).and_return(conn)
    end

    it 'returns mapped recordings on 200 response' do
      rec = {
        'id' => 'mb-1',
        'title' => 'Yellow',
        'artist-credit' => [ { 'artist' => { 'name' => 'Coldplay' } } ],
        'releases' => [ { 'id' => 'r1', 'title' => 'Parachutes', 'date' => '2000-07-10' } ]
      }

      body = { 'recordings' => [rec] }.to_json
      resp = double('resp', status: 200, body: body, env: double(url: 'https://musicbrainz.org/ws/2/recording'))

      # emulate Faraday#get that yields a request object so headers can be set
      class ReqObj
        def headers
          @h ||= {}
        end
      end

      allow(conn).to receive(:get) do |path, params = {}, &block|
        req = ReqObj.new
        block.call(req) if block
        resp
      end

      results = described_class.search_recordings('yellow', limit: 1, contact_email: 'me@example.com')
      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      r = results.first
      expect(r[:id]).to eq('mb-1')
      expect(r[:title]).to eq('Yellow')
      expect(r[:artists]).to include('Coldplay')
      expect(r[:release]).to eq('Parachutes')
      expect(r[:release_id]).to eq('r1')
      expect(r[:release_date]).to eq('2000-07-10')
    end

    it 'returns empty array when query is blank' do
      expect(described_class.search_recordings(nil)).to eq([])
      expect(described_class.search_recordings('')).to eq([])
    end

    it 'returns empty array for non-200 responses' do
      resp = double('resp', status: 500, body: 'error', env: double(url: 'https://musicbrainz.org'))
      allow(conn).to receive(:get).and_return(resp)

      expect(described_class.search_recordings('nirvana')).to eq([])
    end

    it 'rescues exceptions and returns empty array' do
      allow(conn).to receive(:get).and_raise(StandardError.new('boom'))

      expect(described_class.search_recordings('nirvana')).to eq([])
    end
  end
end
require 'rails_helper'

RSpec.describe MusicbrainzClient, type: :service do
  describe '.search_recordings' do
    let(:query) { 'yellow' }

    it 'returns [] when query blank' do
      expect(described_class.search_recordings('')).to eq([])
      expect(described_class.search_recordings(nil)).to eq([])
    end

    it 'parses recordings when API returns 200' do
      body = { 'recordings' => [ { 'id' => 'r1', 'title' => 'Song', 'artist-credit' => [ { 'artist' => { 'name' => 'A' } } ], 'releases' => [ { 'id' => 'rel1', 'title' => 'Album', 'date' => '2000-01-01' } ] } ] }
      resp = double('resp', status: 200, body: body.to_json, env: double(url: 'http://example'))
      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_return(resp)

      out = described_class.search_recordings(query, limit: 5, contact_email: 'me@example.com')
      expect(out).to be_an(Array)
      expect(out.first[:id]).to eq('r1')
      expect(out.first[:artists]).to eq('A')
      expect(out.first[:release]).to eq('Album')
      expect(out.first[:release_date]).to eq('2000-01-01')
    end

    it 'returns [] on non-200 response' do
      resp = double('resp', status: 500, body: 'err', env: double(url: 'http://x'))
      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_return(resp)

      expect(described_class.search_recordings('q')).to eq([])
    end

    it 'rescues and returns [] on exceptions' do
      conn = double('faraday')
      allow(Faraday).to receive(:new).and_return(conn)
      allow(conn).to receive(:get).and_raise(StandardError.new('boom'))

      expect(described_class.search_recordings('x')).to eq([])
    end
  end
end
