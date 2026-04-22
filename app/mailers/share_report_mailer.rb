class ShareReportMailer < ApplicationMailer
  REPORT_TO = "coupdenvoi.tv@gmail.com"

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

    mail(
      to:      REPORT_TO,
      subject: "Coup d'Envoi TV — Partages semaine du #{7.days.ago.strftime('%d/%m')}"
    )
  end

  private

  def top_pages(since:, before: nil, limit: 10)
    scope = ShareClick.where(created_at: since..)
    scope = scope.where(created_at: ..before) if before
    scope.group(:page_url, :platform)
         .order("count_all desc")
         .limit(limit * 3)
         .count
         .each_with_object(Hash.new(0)) { |((url, platform), n), h| h[url] += n }
         .sort_by { |_, n| -n }
         .first(limit)
  end

  def build_trends(current, previous)
    prev_rank = previous.each_with_index.to_h { |(url, _), i| [url, i + 1] }
    current.each_with_index.map do |(url, count), i|
      rank_now  = i + 1
      rank_prev = prev_rank[url]
      trend = if rank_prev.nil?        then "🆕"
              elsif rank_now < rank_prev then "↑"
              elsif rank_now > rank_prev then "↓"
              else                           "="
              end
      { url: url, count: count, trend: trend }
    end
  end
end
