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
