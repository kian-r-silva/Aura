require 'rails_helper'

RSpec.describe Album, type: :model do
  describe 'associations' do
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:artist) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      album = build(:album)
      expect(album).to be_valid
    end
  end

  describe 'attributes' do
    let(:album) { create(:album, title: 'Abbey Road', artist: 'The Beatles', year: 1969) }

    it 'has a title' do
      expect(album.title).to eq('Abbey Road')
    end

    it 'has an artist' do
      expect(album.artist).to eq('The Beatles')
    end

    it 'has a year' do
      expect(album.year).to eq(1969)
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated reviews when album is destroyed' do
      album = create(:album)
      user = create(:user)
      review = create(:review, album: album, user: user, rating: 5, comment: 'Great album!')
      
      expect { album.destroy }.to change { Review.count }.by(-1)
    end
  end
end
