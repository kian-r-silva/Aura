Feature: Sign up / Login
  As a user
  I want to sign up and log in
  So that I can leave reviews

  Scenario: Sign up
    Given I am on the sign up page
    When I sign up with "Kian" and "kian@example.com"
    Then I should see "Welcome, Kian"