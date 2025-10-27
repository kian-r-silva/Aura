Given('I am on the homepage') do
  visit root_path
end

When('I look at the page') do
  # Intentionally left blank - we're just viewing the page
end

Then('I should see the application') do
  expect(page).to have_http_status(:success)
end
