class CreateCoaches < ActiveRecord::Migration[7.0]
  def change
    create_table :coaches do |t|
      t.integer  :team_api_id, null: false
      t.string   :name
      t.string   :photo
      t.string   :nationality
      t.integer  :age
      t.jsonb    :career, default: []
      t.timestamps
    end
    add_index :coaches, :team_api_id, unique: true
  end
end
