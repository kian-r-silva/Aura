Given("an album {string} by {string} exists") do |title, artist|
  Album.create!(title: title, artist: artist, year: 2000)
end

When("I visit the album page for {string}") do |title|
  album = Album.find_by(title: title)
  visit album_path(album)
end

When("I add a {int} star review with {string}") do |rating, comment|
  fill_in "Rating", with: rating
  fill_in "Comment", with: comment
  click_button "Add review"
end

Then("I should see {string} on the page") do |text|
  expect(page).to have_content(text)
end