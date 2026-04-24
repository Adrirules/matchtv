class CreateApiCallLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :api_call_logs do |t|
      t.date    :date,     null: false
      t.string  :endpoint, null: false
      t.integer :count,    null: false, default: 0

      t.timestamps
    end

    add_index :api_call_logs, [:date, :endpoint], unique: true
  end
end
