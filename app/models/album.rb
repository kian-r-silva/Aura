class Album < ApplicationRecord
  has_many :reviews, dependent: :destroy
  validates :title, :artist, presence: true
end
