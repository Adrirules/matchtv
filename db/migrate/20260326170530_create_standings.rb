class CreateStandings < ActiveRecord::Migration[7.0]
  def change
    create_table :standings do |t|
      t.integer :league_id, null: false
      t.integer :season, null: false, default: 2025
      t.jsonb :data
      t.datetime :synced_at

      t.timestamps
    end

    add_index :standings, [:league_id, :season], unique: true
  end
end
