class Album < ApplicationRecord
  # Albums themselves no longer directly own reviews; reviews are attached to Song records.
  validates :title, :artist, presence: true
end
