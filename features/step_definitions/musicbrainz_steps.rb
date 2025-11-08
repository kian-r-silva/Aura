Given(/^the MusicBrainz result:$/) do |table|
  # table is a Cucumber::MultilineArgument::DataTable
  row = table.hashes.first
  @mb_item = {
    'id' => row['id'],
    'title' => row['title'],
    'artists' => row['artists'],
    'release' => row['release']
  }
end

When(/^I create a review for that MusicBrainz result with rating (\d+) and comment "([^"]+)"$/) do |rating, comment|
  payload = {
    album_title: @mb_item['release'],
    artists: @mb_item['artists'],
    track_id: @mb_item['id'],
    track_name: @mb_item['title'],
    rating: rating.to_i,
    comment: comment
  }

  # Use the current Capybara driver to POST to the endpoint. The rack_test driver supports submit.
  if page.driver.respond_to?(:submit)
    page.driver.submit :post, musicbrainz_create_review_path, payload
  else
    # Fallback: use Net::HTTP against local server (less reliable in test env)
    raise 'Capybara driver does not support programmatic submit; ensure tests run with rack_test driver.'
  end

  # After the POST, find the created song and review for assertions
  @created_song = Song.find_by(title: @mb_item['title'], artist: @mb_item['artists'])
  @created_review = @created_song&.reviews&.order(created_at: :desc)&.first
end

Then(/^I should be redirected to the song page$/) do
  expect(@created_song).not_to be_nil
  # Visit the song page to assert contents
  visit song_path(@created_song)
  expect(page.status_code).to eq(200)
end

Then(/^I should see "([^"]+)" on the song page$/) do |text|
  expect(page).to have_content(text)
end

When(/^I visit my profile$/) do
  user = User.find_by(email: 'tester@example.com')
  visit user_path(user)
end

Then(/^I should see "([^"]+)" on my profile$/) do |text|
  expect(page).to have_content(text)
end
