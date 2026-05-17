class DaysController < ApplicationController
  def show
    today = Date.today

    # Date sélectionnée
    @date =
      if params[:date]
        Date.parse(params[:date])
      else
        today
      end

    # Fenêtre indexable : 3 mois en arrière, 7 jours en avant
    if @date < today - 3.months || @date > today + 7.days
      redirect_to day_path(date: today), status: :moved_permanently and return
    end

    # Variables d'état temporel
    @is_past   = @date < today
    @is_today  = @date == today
    @is_future = @date > today

    # Calendrier : 7 jours à partir d'aujourd'hui (navigation rapide)
    @days = (0..6).map { |i| today + i.days }

    # Matchs pour le jour sélectionné
    @matches = Match.where(start_time: @date.all_day).order(:start_time)

    # Nombre de matchs en direct (pour le badge du bouton)
    @live_count = Match.where(status: %w[1H HT 2H ET BT P]).count

    # 3 derniers articles blog (home uniquement)
    @recent_articles = load_recent_blog_articles(4) if @is_today
  end

  private

  def load_recent_blog_articles(limit)
    blog_path = Rails.root.join("app/content/blog")
    Dir.glob("#{blog_path}/*.md").filter_map do |path|
      raw = File.read(path)
      next unless raw.start_with?('---')
      parts = raw.split('---', 3)
      next if parts.length < 3
      meta = YAML.safe_load(parts[1], permitted_classes: [Date]) rescue {}
      next unless meta['published_at'] && meta['slug']
      pub_date = meta['published_at'].is_a?(Date) ? meta['published_at'] : Date.parse(meta['published_at'].to_s)
      next if pub_date > Date.today
      { slug: meta['slug'], title: meta['title'], excerpt: meta['excerpt'], image: meta['image'], published_at: pub_date }
    end.sort_by { |a| a[:published_at] }.reverse.first(limit)
  rescue
    []
  end
end
