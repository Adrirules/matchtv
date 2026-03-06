class CreatePlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.integer :api_id,      null: false
      t.string  :team_name
      t.integer :team_api_id
      t.string  :team_logo
      t.string  :position
      t.string  :nationality
      t.string  :photo
      t.integer :age
      t.timestamps
    end

    add_index :players, :slug,       unique: true
    add_index :players, :api_id,     unique: true
    add_index :players, :team_api_id
  end
end
