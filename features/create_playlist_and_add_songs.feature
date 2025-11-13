Feature: Create a playlist and add songs
  As a signed-in user
  I want to create a new playlist
  So that I can organize and manage my favorite songs

  Scenario: Create a new playlist
    Given I am signed in as "user@example.com"
    When I create a playlist named "My Favorites"
    Then I should see "Playlist created"
    And I should see "My Favorites" on the playlist page

  Scenario: Create a playlist and verify it's empty
    Given I am signed in as "user@example.com"
    When I create a playlist named "Rock Classics"
    Then I should see "Playlist created"
    When I view the playlist
    Then the playlist should contain 0 songs
