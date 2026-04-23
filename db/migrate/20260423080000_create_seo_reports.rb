class CreateSeoReports < ActiveRecord::Migration[7.0]
  def change
    create_table :seo_reports do |t|
      t.string  :period,       null: false           # weekly / monthly
      t.string  :label,        null: false           # "14/04 au 20/04/2026" ou "avril 2026"
      t.date    :report_date,  null: false           # date du rapport
      t.jsonb   :summary_data, default: {}           # clics/impressions/CTR/position + WoW/YoY
      t.jsonb   :top_pages,    default: []           # top 25-50 pages
      t.text    :analysis                            # analyse Claude/Groq complète
      t.jsonb   :actions,      default: []           # [{title, page, status: open/done/ignored}]
      t.timestamps
    end

    add_index :seo_reports, [:period, :report_date], unique: true
  end
end
