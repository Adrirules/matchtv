class CreateTeamVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :team_votes do |t|
      t.string :team_slug, null: false
      t.string :ip_hash,   null: false
      t.timestamps
    end

    add_index :team_votes, [:team_slug, :ip_hash], unique: true
    add_index :team_votes, :team_slug
  end
end
