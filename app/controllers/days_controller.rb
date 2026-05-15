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

    # Sécurité : jamais dans le passé — redirect 301 pour éviter les conflits de canonical
    if @date < today
      redirect_to day_path(date: today), status: :moved_permanently and return
    end

    # Fenêtre fixe de 7 jours
    @days = (0..6).map { |i| today + i.days }

    # Matchs pour le jour sélectionné
    scope = Match.where(start_time: @date.all_day)

    # Pas de filtre sur l'heure : on affiche tous les matchs du jour (y compris terminés)

    @matches = scope.order(:start_time)

    # Nombre de matchs en direct (pour le badge du bouton)
    @live_count = Match.where(status: %w[1H HT 2H ET BT P]).count

    # 3 derniers articles blog (home uniquement)
    @recent_articles = load_recent_blog_articles(4) if @date == today
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
