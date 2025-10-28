Feature: Log an album
  As a music lover
  I want to record and rate an album
  So that I can share my opinion with friends

  Scenario: Add a review
    Given an album "Kid A" by "Radiohead" exists
    And I am signed in as "kian@example.com"
    When I visit the album page for "Kid A"
    And I add a 5 star review with "Timeless"
    Then I should see "Timeless" on the page