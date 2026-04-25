class SeoReportMailer < ApplicationMailer
  REPORT_TO  = "coupdenvoi@gmail.com".freeze
  GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions".freeze
  GROQ_MODEL = "llama-3.3-70b-versatile".freeze

  def weekly_report(current:, previous:, summary_current:, summary_previous:, analysis:, week_label:)
    @current          = current
    @previous         = previous
    @summary          = summary_current
    @summary_prev     = summary_previous
    @analysis         = analysis
    @week_label       = week_label
    @trends           = build_page_trends(current, previous)
    @opportunities    = find_opportunities(current)
    @declines         = find_declines(current, previous)

    mail(
      to:      REPORT_TO,
      subject: "SEO coupdenvoi.tv — semaine #{week_label}"
    )
  end

  def monthly_report(current:, previous:, summary_current:, summary_previous:, analysis:, month_label:)
    @current       = current
    @previous      = previous
    @summary       = summary_current
    @summary_prev  = summary_previous
    @analysis      = analysis
    @month_label   = month_label
    @trends        = build_page_trends(current, previous)
    @opportunities = find_opportunities(current)
    @declines      = find_declines(current, previous)

    mail(
      to:      REPORT_TO,
      subject: "SEO coupdenvoi.tv — bilan #{month_label}"
    )
  end

  private

  # Ajoute delta WoW/MoM à chaque page
  def build_page_trends(current, previous)
    prev_map = previous.index_by { |r| r[:page] }
    current.map do |row|
      prev = prev_map[row[:page]]
      row.merge(
        prev_clicks:      prev ? prev[:clicks] : nil,
        prev_impressions: prev ? prev[:impressions] : nil,
        prev_position:    prev ? prev[:position] : nil,
        delta_pos:        prev ? (row[:position] - prev[:position]).round(1) : nil,
        is_new:           prev.nil?
      )
    end
  end

  # Pages à fort potentiel : impressions > 200, CTR < 3%, position 8-30
  def find_opportunities(pages)
    pages.select { |r| r[:impressions] > 200 && r[:ctr] < 3.0 && r[:position].between?(8, 30) }
         .sort_by { |r| -r[:impressions] }
         .first(5)
  end

  # Pages en recul : position dégradée > 3 places
  def find_declines(current, previous)
    prev_map = previous.index_by { |r| r[:page] }
    current.filter_map do |row|
      prev = prev_map[row[:page]]
      next unless prev && (row[:position] - prev[:position]) > 3.0
      row.merge(delta_pos: (row[:position] - prev[:position]).round(1))
    end.sort_by { |r| -r[:delta_pos] }.first(5)
  end
end
