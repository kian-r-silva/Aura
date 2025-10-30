Given("I am on the sign up page") do
  visit new_user_path
end

When("I sign up with {string} and {string}") do |name, email|
  # The sign-up form labels the name field as "Full Name"
  fill_in "Full Name", with: name
  fill_in "Email", with: email
  # new fields:
  fill_in "Username", with: (email.split('@').first || "user#{rand(1000)}")
  fill_in "Password", with: "password"
  fill_in "Confirm Password", with: "password"
  click_button "Create Account"
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Given("I am signed in as {string}") do |email|
  user = User.find_by(email: email) || User.create!(name: "Test User", username: (email.split('@').first), email: email, password: "password", password_confirmation: "password")
  visit new_session_path
  fill_in "Username or Email", with: user.email
  fill_in "Password", with: "password"
  click_button "Sign In"
end

When("I connect my Spotify account") do
  # Enable OmniAuth test mode and provide a mock auth hash for Spotify.
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
    provider: 'spotify',
    uid: 'spotify-test-uid',
    info: { name: 'Cuke User', email: 'cuke@example.com' },
    credentials: { token: 'test-access-token', refresh_token: 'test-refresh', expires_in: 3600 }
  )

  # Trigger the OmniAuth flow (the app should handle /auth/spotify and callback)
  visit '/auth/spotify'
  # follow redirect if necessary
  if page.response_headers['Location']
    visit page.response_headers['Location']
  end
end

When("I sign out") do
  # The layout uses a form button_to for sign out
  click_button "Sign out"
end