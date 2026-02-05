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

ActiveRecord::Schema[7.0].define(version: 2026_02_04_205208) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "matches", force: :cascade do |t|
    t.string "home_team"
    t.string "away_team"
    t.string "competition"
    t.datetime "start_time"
    t.string "tv_channels"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "matchup_id", null: false
    t.integer "api_id"
    t.string "home_team_logo"
    t.string "away_team_logo"
    t.index ["api_id"], name: "index_matches_on_api_id"
    t.index ["matchup_id"], name: "index_matches_on_matchup_id"
  end

  create_table "matchups", force: :cascade do |t|
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "matches", "matchups"
end
