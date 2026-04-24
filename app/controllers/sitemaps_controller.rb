class SitemapsController < ApplicationController
  layout false

  def index
    # 1. Les Matchs (les 1000 plus récents/futurs)
    @matches = Match.where("start_time > ?", 30.days.ago)
                    .where.not(slug: [nil, ""])
                    .order(start_time: :desc).limit(1000)

    # 2. Les Équipes (uniques — seulement les équipes avec matchs récents ou à venir)
    @teams = (
      Match.where("start_time > ?", 90.days.ago).distinct.pluck(:home_team) +
      Match.where("start_time > ?", 90.days.ago).distinct.pluck(:away_team)
    ).uniq.compact

    # 3. Les Compétitions (Ligues — seulement celles avec matchs récents)
    @competitions = Match.where("start_time > ?", 90.days.ago).distinct.pluck(:competition).compact

    # 4. Les Joueurs (seulement ceux avec un slug valide et une équipe active récemment)
    active_teams = @teams
    @players = Player.where(team: active_teams)
                     .where.not(slug: [nil, ""])
                     .select(:slug, :updated_at)

    # 5. Les Classements (slugs officiels uniquement)
    @standing_slugs = StandingsController::LEAGUES.map { |l| l[:slug] }

    # 6. Les Chaînes TV
    @channel_slugs = ChannelsController::CHANNELS_META.map { |c| c[:slug] }

    # 7. Les Articles de blog (publiés uniquement)
    @blog_articles = Dir.glob(Rails.root.join("app/content/blog/*.md")).map do |path|
      content = File.read(path)
      frontmatter = content.match(/\A---\n(.*?)\n---/m)&.[](1)
      next unless frontmatter
      slug         = frontmatter.match(/^slug:\s*(.+)/)&.[](1)&.strip
      published_at = frontmatter.match(/^published_at:\s*(.+)/)&.[](1)&.strip
      next unless slug && published_at
      date = Date.parse(published_at) rescue nil
      next unless date && date <= Date.today
      { slug: slug, date: date }
    end.compact

    respond_to do |format|
      format.xml
    end
  end
end
