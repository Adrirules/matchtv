class CreateCrawlErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :crawl_errors do |t|
      t.string  :url,        null: false
      t.integer :count,      null: false, default: 0
      t.date    :first_seen, null: false
      t.date    :last_seen,  null: false
      t.boolean :alert_sent, null: false, default: false

      t.timestamps
    end
    add_index :crawl_errors, :url, unique: true
  end
end
