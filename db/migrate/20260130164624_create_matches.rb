class CreateMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :matches do |t|
      t.string :home_team
      t.string :away_team
      t.string :competition
      t.datetime :start_time
      t.string :tv_channels

      t.timestamps
    end
  end
end
