Feature: Search Spotify and review a track
  As a signed-in user
  I want to search Spotify and create a review for a track
  So that I can log thoughts about a song I like

  Scenario: Search and review a Spotify track
    Given I am signed in as "kian@example.com"
    And I have connected Spotify
    When I search Spotify for "Hey Jude"
    Then I should see "Hey Jude" in the results
    When I click Review for "Hey Jude" and submit a 5 star review with "Classic"
    Then I should see "Classic" on the page
