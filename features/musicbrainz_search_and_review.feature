Feature: Search MusicBrainz and review a track
  As a signed-in user
  I want to search MusicBrainz and create a review for a song
  So that I can log thoughts about a song I like

  Scenario: Search and review a MusicBrainz track
    Given I am signed in as "kian@example.com"
    Given the MusicBrainz result:
      | id       | title    | artists      | release    |
      | mb-heyjd | Hey Jude | The Beatles  | Hey Jude   |

  When I create a review for that MusicBrainz result with rating 5 and comment "Classic track"
    Then I should be redirected to the song page
    And I should see "Classic" on the song page
