class CreateShareClicks < ActiveRecord::Migration[7.0]
  def change
    create_table :share_clicks do |t|
      t.string :platform, null: false   # 'whatsapp' ou 'x'
      t.string :page_url, null: false   # ex: /blog/mon-article

      t.timestamps
    end
    add_index :share_clicks, [:page_url, :platform]
    add_index :share_clicks, :created_at
  end
end
