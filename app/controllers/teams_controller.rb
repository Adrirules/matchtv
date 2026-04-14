class TeamsController < ApplicationController
  helper TeamContentHelper

  def index
    rows = Match.where.not(home_team_logo: nil)
                .pluck(:home_team, :home_team_logo, :away_team, :away_team_logo, :competition)

    logos_by_team   = {}
    leagues_by_team = Hash.new { |h, k| h[k] = Set.new }

    rows.each do |ht, hl, at, al, comp|
      logos_by_team[ht] ||= hl
      logos_by_team[at] ||= al
      leagues_by_team[ht] << comp if ht && comp
      leagues_by_team[at] << comp if at && comp
    end

    vote_counts = TeamVote.group(:team_slug).count

    @teams = logos_by_team.keys.compact.map do |name|
      slug = name.parameterize
      { name: name, slug: slug, logo: logos_by_team[name],
        votes: vote_counts[slug] || 0,
        leagues: leagues_by_team[name].to_a }
    end.sort_by { |t| [-t[:votes], t[:name]] }

    # Ligues disponibles, ordonnées par popularité (COMPETITIONS_META)
    league_order    = FootballApiService::COMPETITIONS_META.map { |c| c[:name] }
    present_leagues = @teams.flat_map { |t| t[:leagues] }.uniq
    @filter_leagues = league_order.select { |l| present_leagues.include?(l) }

    @page_title = "Toutes les équipes de Football - Programme TV"
  end

  def vote
    slug    = params[:team_slug]
    ip_hash = Digest::SHA256.hexdigest("#{request.remote_ip}-cdtv")[0..15]
    record  = TeamVote.find_by(team_slug: slug, ip_hash: ip_hash)

    if record
      record.destroy
      status = 'removed'
    else
      TeamVote.create!(team_slug: slug, ip_hash: ip_hash)
      status = 'ok'
    end

    render json: { status: status, count: TeamVote.where(team_slug: slug).count }
  rescue => e
    render json: { status: 'error' }, status: 422
  end

  def show
    current_slug = params[:team_slug]

    # Filtrage précis par slug en Ruby (noms composés, accents, etc.)
    all_team_matches = Match.order(:start_time)
                            .select { |m| m.home_team&.parameterize == current_slug || m.away_team&.parameterize == current_slug }

    # Nom, logo et api_id depuis n'importe quel match (préférer ceux avec api_id renseigné)
    ref_match = all_team_matches.find { |m|
      m.home_team&.parameterize == current_slug && m.home_team_api_id.present?
    } || all_team_matches.find { |m|
      m.away_team&.parameterize == current_slug && m.away_team_api_id.present?
    } || all_team_matches.first

    if ref_match
      if ref_match.home_team&.parameterize == current_slug
        @team_name   = ref_match.home_team
        @team_logo   = ref_match.home_team_logo
        @team_api_id = ref_match.home_team_api_id
      else
        @team_name   = ref_match.away_team
        @team_logo   = ref_match.away_team_logo
        @team_api_id = ref_match.away_team_api_id
      end
    else
      @team_name = current_slug.tr('-', ' ').split.map(&:capitalize).join(' ')
    end

    @matches = all_team_matches.select { |m| m.start_time >= Time.current - 3.hours }

    # Stats & résultats enrichis via API (cachés)
    if @team_api_id.present?
      api = FootballApiService.new

      # Trouver la ligue principale = compétition la plus fréquente dans les matchs
      most_common_competition = all_team_matches.map(&:competition).compact
                                                .tally.max_by { |_, count| count }&.first
      primary_league_id = FootballApiService::SUPPORTED_LEAGUES.key(most_common_competition)
      @primary_league_name = most_common_competition

      if primary_league_id
        @stats   = api.fetch_team_stats(@team_api_id, primary_league_id)
        standing_record = Standing.for_league(primary_league_id)
        standings_data = standing_record&.data.presence || api.get_standings(primary_league_id)
        @standing = standings_data
                      &.dig(0, "league", "standings", 0)
                      &.find { |s| s["team"]["id"] == @team_api_id }
      end

      @recent_results = api.fetch_recent_results(@team_api_id)
      coach_record = Coach.find_by(team_api_id: @team_api_id)
      @coach = if coach_record
        coach_record.as_api_hash
      else
        Rails.cache.fetch("coach_#{@team_api_id}", expires_in: 24.hours) do
          api.fetch_coach(@team_api_id)
        end
      end
    end

    # Effectif de l'équipe (depuis la DB players)
    @squad = @team_api_id.present? ? Player.where(team_api_id: @team_api_id).order(:position, :name) : []

    @team_editorial = team_editorial(current_slug)

    @page_title = "#{@team_name} 2025-2026 — Stats, résultats et programme TV | Coup d'Envoi TV"
    @page_desc  = "Retrouvez tous les matchs de #{@team_name} à la télé : horaires, chaînes (Canal+, beIN, DAZN, France TV), résultats et statistiques de la saison 2025-2026."

    expires_in 10.minutes, public: true
  end

  private

  def team_editorial(slug)
    yaml_path = Rails.root.join("config", "team_editorial.yml")
    return nil unless File.exist?(yaml_path)
    (YAML.load_file(yaml_path) || {})[slug]&.strip
  rescue => e
    Rails.logger.error("team_editorial.yml error: #{e.message}")
    nil
  end
end
