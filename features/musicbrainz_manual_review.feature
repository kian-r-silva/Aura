Feature: MusicBrainz manual review
  As a signed-in user
  I want to search MusicBrainz and create a review for a song
  So that song-based reviews are created and visible on song and profile pages

  Background:
    Given I am signed in as "tester@example.com"

  Scenario: Create a review from a MusicBrainz selection via the server endpoint
    Given the MusicBrainz result:
      | id        | title  | artists      | release        |
      | mb-12345  | Yellow | Coldplay     | Parachutes     |

    When I create a review for that MusicBrainz result with rating 5 and comment "Great track"
    Then I should be redirected to the song page
    And I should see "Great track" on the song page
    When I visit my profile
    Then I should see "Yellow" on my profile
