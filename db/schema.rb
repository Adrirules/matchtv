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

ActiveRecord::Schema[7.0].define(version: 2026_04_24_082211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coaches", force: :cascade do |t|
    t.integer "team_api_id", null: false
    t.string "name"
    t.string "photo"
    t.string "nationality"
    t.integer "age"
    t.jsonb "career", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_api_id"], name: "index_coaches_on_team_api_id", unique: true
  end

  create_table "crawl_errors", force: :cascade do |t|
    t.string "url", null: false
    t.integer "count", default: 0, null: false
    t.date "first_seen", null: false
    t.date "last_seen", null: false
    t.boolean "alert_sent", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_crawl_errors_on_url", unique: true
  end

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
    t.string "slug"
    t.string "status", default: "NS"
    t.integer "home_score"
    t.integer "away_score"
    t.integer "elapsed"
    t.integer "home_team_api_id"
    t.integer "away_team_api_id"
    t.text "summary"
    t.text "preview"
    t.string "round"
    t.index ["api_id"], name: "index_matches_on_api_id"
    t.index ["away_team"], name: "index_matches_on_away_team"
    t.index ["away_team_api_id"], name: "index_matches_on_away_team_api_id"
    t.index ["competition"], name: "index_matches_on_competition"
    t.index ["home_team"], name: "index_matches_on_home_team"
    t.index ["home_team_api_id"], name: "index_matches_on_home_team_api_id"
    t.index ["matchup_id"], name: "index_matches_on_matchup_id"
    t.index ["slug"], name: "index_matches_on_slug"
    t.index ["start_time", "competition"], name: "index_matches_on_start_time_and_competition"
    t.index ["start_time"], name: "index_matches_on_start_time"
    t.index ["status"], name: "index_matches_on_status"
  end

  create_table "matchups", force: :cascade do |t|
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "api_id", null: false
    t.string "team_name"
    t.integer "team_api_id"
    t.string "team_logo"
    t.string "position"
    t.string "nationality"
    t.string "photo"
    t.integer "age"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_id"], name: "index_players_on_api_id", unique: true
    t.index ["slug"], name: "index_players_on_slug", unique: true
    t.index ["team_api_id"], name: "index_players_on_team_api_id"
  end

  create_table "seo_reports", force: :cascade do |t|
    t.string "period", null: false
    t.string "label", null: false
    t.date "report_date", null: false
    t.jsonb "summary_data", default: {}
    t.jsonb "top_pages", default: []
    t.text "analysis"
    t.jsonb "actions", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period", "report_date"], name: "index_seo_reports_on_period_and_report_date", unique: true
  end

  create_table "share_clicks", force: :cascade do |t|
    t.string "platform", null: false
    t.string "page_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_share_clicks_on_created_at"
    t.index ["page_url", "platform"], name: "index_share_clicks_on_page_url_and_platform"
  end

  create_table "standings", force: :cascade do |t|
    t.integer "league_id", null: false
    t.integer "season", default: 2025, null: false
    t.jsonb "data"
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "season"], name: "index_standings_on_league_id_and_season", unique: true
  end

  create_table "team_votes", force: :cascade do |t|
    t.string "team_slug", null: false
    t.string "ip_hash", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_slug", "ip_hash"], name: "index_team_votes_on_team_slug_and_ip_hash", unique: true
    t.index ["team_slug"], name: "index_team_votes_on_team_slug"
  end

  add_foreign_key "matches", "matchups"
end
