Given("I have connected Spotify") do
  # Reuse the existing step to mock and visit the OmniAuth endpoint
  step 'I connect my Spotify account'
end

When("I search Spotify for {string}") do |query|
  # Stub SpotifyClient to return predictable results for the scenario
  tracks = [
    { id: 't-heyjude', name: 'Hey Jude', artists: 'The Beatles', album: 'Hey Jude', image: nil, external_url: nil }
  ]

  # Patch SpotifyClient instance methods for deterministic results in Cucumber steps.
  if defined?(SpotifyClient)
    # Save original instance methods so we can restore them later in an After hook.
    originals = {}
    %i[search_tracks recent_tracks].each do |m|
      if SpotifyClient.instance_methods.include?(m)
        originals[m] = SpotifyClient.instance_method(m)
      end
    end
    SpotifyClient.instance_variable_set(:@__cucumber_original_methods, originals)

    SpotifyClient.class_eval do
      define_method(:search_tracks) { |*| tracks }
      define_method(:recent_tracks) { |*| tracks }
    end
  end

  visit spotify_search_path(q: query)
end

Then(/I should see "([^"]+)" in the results/) do |text|
  expect(page).to have_content(text)
end

When(/I click Review for "([^"]+)" and submit a (\d+) star review with "([^"]+)"/) do |track_name, rating, comment|
  within(:xpath, "//li[contains(., \"#{track_name}\")]") do
    click_link 'Review'
  end

  # We're now on reviews#new with hidden track params
  fill_in 'Rating', with: rating
  fill_in 'Comment', with: comment
  click_button 'Submit review'
end

Then(/I should see "([^"]+)" on the page/) do |text|
  expect(page).to have_content(text)
end
