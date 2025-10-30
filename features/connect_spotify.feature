Feature: Connect Spotify
  As a user
  I want to connect my Spotify account
  So that I can see connected status and use Spotify features

  Scenario: Connect Spotify from account page
    Given I am signed in as "kian@example.com"
    When I connect my Spotify account
    Then I should see "Spotify account connected"
