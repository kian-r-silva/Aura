require 'rails_helper'

RSpec.describe Song, type: :model do
  describe '#average_rating' do
    let(:user) { User.create!(email: 'u@example.com', name: 'User', username: 'u1', password: 'password') }

    it 'returns nil when there are no reviews' do
      song = Song.create!(title: 'No Reviews', artist: 'Nobody')
      expect(song.average_rating).to be_nil
    end

    it 'returns the average rating rounded to 2 decimals' do
      song = Song.create!(title: 'Hit', artist: 'Artist')
      song.reviews.create!(user: user, rating: 5, comment: 'Great track!' * 2)
      song.reviews.create!(user: user, rating: 3, comment: 'Not bad, could be better' )

      # average = (5 + 3) / 2.0 = 4.0
      expect(song.average_rating).to eq 4.0

      # add another review to make non-integer average
      song.reviews.create!(user: user, rating: 4, comment: 'Pretty good song' )
      # new average = (5 + 3 + 4) / 3 = 4.0 still
      expect(song.average_rating).to eq 4.0
    end
  end
end
require 'rails_helper'

RSpec.describe Song, type: :model do
  it 'is valid with title and artist' do
    s = Song.new(title: 'Yellow', artist: 'Coldplay')
    expect(s).to be_valid
  end

  it 'is invalid without a title' do
    s = Song.new(artist: 'Coldplay')
    expect(s).not_to be_valid
  end

  it 'is invalid without an artist' do
    s = Song.new(title: 'Yellow')
    expect(s).not_to be_valid
  end

  describe '#average_rating' do
    it 'returns nil when no reviews' do
      song = Song.create!(title: 'No Reviews', artist: 'Nobody')
      expect(song.average_rating).to be_nil
    end

    it 'calculates average rating rounded to 2 decimals' do
      song = Song.create!(title: 'Avg Song', artist: 'Band')
      user = create(:user)
      create(:review, song: song, rating: 5, user: user, comment: 'Excellent track')
      create(:review, song: song, rating: 4, user: user, comment: 'Pretty good')
      expect(song.average_rating).to eq(4.5)
    end
  end
end
