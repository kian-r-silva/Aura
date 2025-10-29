FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "user@example.com" }
    username { "testuser" }
    password { "password123" }
  end
end
