require 'rails_helper'

RSpec.describe 'MusicBrainz review creation', type: :request do
  let(:user) { User.create!(name: 'Spec User', username: 'specuser', email: 'spec@example.com', password: 'password') }

  let(:payload) do
    {
      album_title: 'Parachutes',
      artists: 'Coldplay',
      track_id: 'mb-12345',
      track_name: 'Yellow',
      rating: 5,
      comment: 'Great track'
    }
  end

  describe 'POST /reviews/musicbrainz_create' do
    context 'when not signed in' do
      it 'returns unauthorized' do
        post musicbrainz_create_review_path, params: payload
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context 'when signed in' do
      before do
        # stub current_user via controller helper
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'creates a song and a review and returns success with redirect' do
        expect { post musicbrainz_create_review_path, params: payload }.to change { Review.count }.by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['song_id']).to be_present

        song = Song.find(json['song_id'])
        expect(song.title).to eq('Yellow')
        expect(song.artist).to eq('Coldplay')

        review = Review.last
        expect(review.song_id).to eq(song.id)
        expect(review.comment).to eq('Great track')
        expect(review.rating).to eq(5)
      end
    end
  end
end
