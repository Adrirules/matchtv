class ShareReportMailer < ApplicationMailer
  REPORT_TO = "coupdenvoi@gmail.com"
  MONTHS_FR = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre].freeze

  def weekly_report
    @week_start  = 7.days.ago.beginning_of_day
    @month_start = Time.current.beginning_of_month
    @year_start  = Time.current.beginning_of_year

    @top_week  = top_pages(since: @week_start)
    @top_month = top_pages(since: @month_start)
    @top_year  = top_pages(since: @year_start)

    # Trends : comparer avec la semaine précédente (8-14 jours)
    prev_week_start = 14.days.ago.beginning_of_day
    prev_top = top_pages(since: prev_week_start, before: @week_start)
    @trends = build_trends(@top_week, prev_top)

    @generated_at = Time.current.strftime("%d/%m/%Y à %Hh%M")
    @month_fr = MONTHS_FR[Date.today.month - 1]
    @year     = Date.today.year

    mail(
      to:      REPORT_TO,
      subject: "Coup d'Envoi TV — Partages semaine du #{7.days.ago.strftime('%d/%m')}"
    )
  end

  private

  def top_pages(since:, before: nil, limit: 10)
    scope = ShareClick.where(created_at: since..)
    scope = scope.where(created_at: ..before) if before

    counts = scope.group(:page_url, :platform).count
    # counts = { ["url", "whatsapp"] => 5, ["url", "x"] => 3, ... }

    by_url = counts.each_with_object({}) do |((url, platform), n), h|
      h[url] ||= { whatsapp: 0, x: 0 }
      h[url][platform.to_sym] = (h[url][platform.to_sym] || 0) + n
    end

    by_url.map { |url, p|
      { url: url, whatsapp: p[:whatsapp], x: p[:x], total: p[:whatsapp] + p[:x] }
    }.sort_by { |r| -r[:total] }.first(limit)
  end

  def build_trends(current, previous)
    prev_rank = previous.each_with_index.to_h { |row, i| [row[:url], i + 1] }
    current.each_with_index.map do |row, i|
      rank_now  = i + 1
      rank_prev = prev_rank[row[:url]]
      trend = if rank_prev.nil?         then "🆕"
               elsif rank_now < rank_prev then "↑"
               elsif rank_now > rank_prev then "↓"
               else                           "="
               end
      row.merge(trend: trend)
    end
  end
end
