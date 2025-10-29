class AddSpotifyFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :spotify_uid, :string
    add_column :users, :spotify_access_token, :string
    add_column :users, :spotify_refresh_token, :string
    add_column :users, :spotify_token_expires_at, :datetime
    add_column :users, :spotify_connected, :boolean, default: false

    add_index :users, :spotify_uid, unique: true
  end
end