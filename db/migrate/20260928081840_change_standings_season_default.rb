class ChangeStandingsSeasonDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :standings, :season, from: 2025, to: 2026
  end
end
