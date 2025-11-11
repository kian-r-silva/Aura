# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_11_193956) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string "artist"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "year"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "follower_id", null: false
    t.bigint "following_id", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "following_id"], name: "index_follows_on_follower_id_and_following_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.index ["following_id"], name: "index_follows_on_following_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "rating"
    t.bigint "song_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["song_id"], name: "index_reviews_on_song_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "album"
    t.string "artist", null: false
    t.datetime "created_at", null: false
    t.string "musicbrainz_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "lastfm_connected", default: false
    t.string "lastfm_session_key"
    t.string "lastfm_username"
    t.string "name"
    t.string "password_digest"
    t.string "spotify_access_token"
    t.boolean "spotify_connected", default: false
    t.string "spotify_refresh_token"
    t.datetime "spotify_token_expires_at"
    t.string "spotify_uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email_unique", unique: true
    t.index ["lastfm_username"], name: "index_users_on_lastfm_username", unique: true
    t.index ["spotify_uid"], name: "index_users_on_spotify_uid", unique: true
    t.index ["username"], name: "index_users_on_username_unique", unique: true
  end

  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "follows", "users", column: "following_id"
  add_foreign_key "reviews", "users"
end
