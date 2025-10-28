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
  user = User.find_by(email: email) || User.create!(name: "Test", email: email)
  page.set_rack_session(user_id: user.id)
end