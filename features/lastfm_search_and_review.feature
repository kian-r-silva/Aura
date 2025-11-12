Feature: Connect Last.fm, search and review a track
  As a signed-in user
  I want to connect my Last.fm account, search for a track and create a review
  So that I can save my listening impressions from Last.fm

  Scenario: Sign in, connect Last.fm, search and review
    Given I am signed in as "tester@example.com"
    When I connect my Last.fm account
    And I search Last.fm for "Hey Jude"
    Then I should see "Hey Jude" in the results
  When I click Review for "Hey Jude" and submit a 5 star review with "Amazing track, love it"
  Then I should see "Amazing track, love it" on the song page
