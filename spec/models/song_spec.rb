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
end
