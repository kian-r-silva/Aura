Feature: Create a playlist from rated songs
  As a signed-in user
  I want to create a playlist populated with my highest-rated songs
  So that I can easily access a collection of my favorite tracks

  Scenario: Create a playlist from top rated songs
    Given I am signed in as "user@example.com"
    Given I have the following rated songs:
      | title              | artist           | rating |
      | Stairway to Heaven | Led Zeppelin     | 5      |
      | Sweet Child O Mine | Guns N Roses     | 5      |
      | Hotel California   | Eagles           | 4      |

    When I create a playlist from my top rated songs
    Then I should see "Playlist created from your top rated songs"
    And I should see "My Top Rated Songs" on the page
    And the playlist should contain at least 3 songs

  Scenario: Verify top rated playlist is automatically populated
    Given I am signed in as "user@example.com"
    Given I have the following rated songs:
      | title    | artist     | rating |
      | Song One | Artist One | 5      |
      | Song Two | Artist Two | 4      |

    When I create a playlist from my top rated songs
    Then I should see "My Top Rated Songs" on the page

    When I view the playlist
    Then the playlist should contain songs I have rated
    And the playlist should contain "Song One"
