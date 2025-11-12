Given(/^I connect my Last\.fm account$/) do
  user = User.find_by(email: 'tester@example.com') || User.last
  session_data = { 'key' => 'lastfm-session-key', 'name' => 'lastfm_user' }
  
  user.connect_lastfm_from_session(session_data['key'], session_data['name'])
  user.save!

  visit user_path(user)
  expect(page).to have_current_path(user_path(user))
end

Given(/^Last\.fm returns recent tracks including "([^"]*)"$/) do |artist_name|
  allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
    { name: 'Karma Police', artists: artist_name, album: '', image: nil }
  ])
  # Also stub track_similar to avoid external calls during profile rendering
  allow_any_instance_of(LastfmClient).to receive(:track_similar).and_return([
    { name: 'Paranoid Android', artist: artist_name, url: 'http://last.fm/p1' }
  ])
end

When(/^I search Last\.fm for "([^"]*)"$/) do |query|
  visit lastfm_search_path

  def LastfmClient.search_tracks(q)
    [
      {
        id: 'lf-1',
        name: q,
        artists: 'The Beatles',
        album: "#{q} Single",
        image: nil,
        external_url: nil
      }
    ]
  end

  fill_in "q", with: query
  click_button "Search"
end

Then(/^I should see "([^"]*)" in the results$/) do |text|
  expect(page).to have_content(text)
end

When(/^I click Review for "([^"]*)" and submit a (\d+) star review with "([^"]*)"$/) do |track, rating, body|
  
  visit new_review_path(track_id: 'lf-1', track_name: track, artists: 'The Beatles', album_title: "#{track} Single")

  fill_in "review_comment", with: body
  fill_in "review_rating", with: rating
  click_button "Submit review"
end