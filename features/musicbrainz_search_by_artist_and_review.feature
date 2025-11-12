Feature: MusicBrainz search by artist and review
  As a signed-in user
  I want to find recordings by artist via MusicBrainz and review them

  Scenario: Search by artist via MusicBrainz and review a recording
    Given I am signed in as "tester@example.com"
    # seed a MusicBrainz recording result that the app can use
    Given the MusicBrainz result:
      | id              | title     | artists       | release         |
      | mbid-artist-001 | Hey Jude  | The Beatles   | Hey Jude Single |
  When I create a review for that MusicBrainz result with rating 4 and comment "Solid classic track"
  Then I should be redirected to the song page
  And I should see "Solid classic track" on the song page
