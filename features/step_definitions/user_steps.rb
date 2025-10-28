Given("I am on the sign up page") do
  visit new_user_path
end

When("I sign up with {string} and {string}") do |name, email|
  fill_in "Name", with: name
  fill_in "Email", with: email
  click_button "Create User"
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Given("I am signed in as {string}") do |email|
  user = User.find_by(email: email) || User.create!(name: "Test User", email: email)
  visit new_session_path
  fill_in "Email", with: user.email
  click_button "Sign in"
end