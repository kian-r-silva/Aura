require 'rails_helper'

RSpec.describe 'Spotify search and review', type: :system do
  before do
    driven_by :rack_test
  end

  it 'connects spotify, searches, and creates a review' do
    user = FactoryBot.create(:user)

    # Sign in
    visit new_session_path
    fill_in 'Username or Email', with: user.email
    fill_in 'Password', with: 'password123'
    click_button 'Sign In'

    # Mock OmniAuth Spotify connect
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
      provider: 'spotify',
      uid: 'spec-spotify-uid',
      credentials: { token: 'spec-token', refresh_token: 'spec-refresh', expires_in: 3600 }
    )

    # Simulate the Spotify callback by saving credentials on the user directly.
    auth_hash = OmniAuth::AuthHash.new(
      provider: 'spotify',
      uid: 'spec-spotify-uid',
      credentials: { token: 'spec-token', refresh_token: 'spec-refresh', expires_in: 3600 }
    )
    user.connect_spotify_from_auth(auth_hash)

    # Stub SpotifyClient to return deterministic results
    allow_any_instance_of(SpotifyClient).to receive(:search_tracks).and_return([
      { id: 't-heyjude', name: 'Hey Jude', artists: 'The Beatles', album: 'Hey Jude', image: nil, external_url: nil }
    ])

    visit spotify_search_path(q: 'Hey Jude')
    expect(page).to have_content('Hey Jude')

    within(:xpath, "//li[contains(., 'Hey Jude')]") do
      click_link 'Review'
    end

    fill_in 'Rating', with: 5
  fill_in 'Comment', with: 'Classic track! Truly timeless.'
    click_button 'Submit review'

    expect(page).to have_content('Classic')
  end
end
