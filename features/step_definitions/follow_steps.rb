Given("the following users exist:") do |table|
  table.hashes.each do |hash|
    User.create!(
      name: hash['name'],
      email: hash['email'],
      username: hash['username'],
      password: 'password',
      password_confirmation: 'password'
    )
  end
end

When("I search for {string}") do |query|
  fill_in "q", with: query
  click_button "Search"
end

Then("Alice User should be following Bob User") do
  alice = User.find_by(name: "Alice User")
  bob = User.find_by(name: "Bob User")
  expect(alice.following?(bob)).to be true
end

Given("I follow {string}") do |user_name|
  user = User.find_by(name: user_name)
  current_user = User.find_by(email: @current_user_email)
  current_user.follow(user)
end

When("I view the following list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit following_friend_path(alice)
end

When("I view the following list for {string}") do |user_name|
  user = User.find_by(name: user_name)
  visit following_friend_path(user)
end

Then("I should see {string} in the following list") do |user_name|
  expect(page).to have_content(user_name)
end

Given("Bob User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  bob = User.find_by(name: "Bob User")
  bob.follow(alice)
end

Given("Charlie User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  charlie = User.find_by(name: "Charlie User")
  charlie.follow(alice)
end

When("I view the followers list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit followers_friend_path(alice)
end

When("I view the followers list for {string}") do |user_name|
  user = User.find_by(name: user_name)
  visit followers_friend_path(user)
end

Then("I should see {string} in the followers list") do |user_name|
  expect(page).to have_content(user_name)
end

When("I unfollow {string}") do |user_name|
  user = User.find_by(name: user_name)
  current_user = User.find_by(email: @current_user_email)
  current_user.unfollow(user)
end

Then("I should see a message about empty following list") do
  expect(page).to have_content(/no.*following|following.*empty|not.*following anyone/i)
end

Then("I should see a message about empty followers list") do
  expect(page).to have_content(/no.*followers|followers.*empty|not.*followers|no one.*following/i)
end

Given("Alice User has not followed anyone") do
  alice = User.find_by(name: "Alice User")
  alice.following.destroy_all
end

Given("no one is following Alice User") do
  alice = User.find_by(name: "Alice User")
  alice.followers.destroy_all
end

Given("Diana User follows Alice User") do
  alice = User.find_by(name: "Alice User")
  diana = User.find_by(name: "Diana User")
  diana.follow(alice)
end

When("Bob User is signed in") do
  bob = User.find_by(name: "Bob User")
  @current_user_email = bob.email
  visit new_session_path
  fill_in "Username or Email", with: bob.email
  fill_in "Password", with: "password"
  click_button "Sign In"
end

When("Bob User views the followers list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit followers_friend_path(alice)
end

Then("Bob User should see {string} in the followers list") do |user_name|
  expect(page).to have_content(user_name)
end

When("Bob User views the following list for Alice User") do
  alice = User.find_by(name: "Alice User")
  visit following_friend_path(alice)
end

Then("Bob User should see {string} in the following list") do |user_name|
  expect(page).to have_content(user_name)
end
