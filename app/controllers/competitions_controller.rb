class CompetitionsController < ApplicationController

  COUNTRY_FLAGS = {
    "France"          => "🇫🇷",
    "Europe"          => "🏆",
    "Angleterre"      => "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
    "Espagne"         => "🇪🇸",
    "Allemagne"       => "🇩🇪",
    "Italie"          => "🇮🇹",
    "Portugal"        => "🇵🇹",
    "Pays-Bas"        => "🇳🇱",
    "Belgique"        => "🇧🇪",
    "Turquie"         => "🇹🇷",
    "Arabie Saoudite" => "🇸🇦",
    "USA"             => "🇺🇸",
    "Monde"           => "🌍",
  }.freeze

  COMPETITION_CHANNELS = {
    61  => %w[dazn bein-sports],
    62  => %w[bein-sports],
    63  => %w[canal-plus],
    39  => %w[canal-plus],
    140 => %w[bein-sports],
    78  => %w[bein-sports],
    135 => %w[dazn],
    141 => %w[bein-sports],
    137 => %w[bein-sports],
    81  => %w[bein-sports],
    40  => %w[bein-sports],
    144 => %w[bein-sports],
    2   => %w[canal-plus],
    3   => %w[canal-plus bein-sports],
    848 => %w[canal-plus],
    64  => %w[canal-plus],
    66  => %w[france-tv bein-sports],
    88  => %w[dazn],
    94  => %w[canal-plus],
    253 => %w[amazon-prime],
    307 => %w[canal-plus],
    203 => %w[bein-sports],
    1   => %w[m6 bein-sports],
  }.freeze

  def index
    db_competitions = Match.distinct.pluck(:competition).compact

    # On ordonne selon COMPETITIONS_META (popularité), les inconnus vont à la fin
    all_known = FootballApiService::COMPETITIONS_META
              .select { |c| db_competitions.include?(c[:name]) }
              .map do |c|
                {
                  name:         c[:name],
                  slug:         c[:name].parameterize,
                  logo:         FootballApiService.league_logo(c[:id]),
                  has_standings: c[:has_standings],
                  standing_slug: c[:has_standings] ? c[:name].parameterize : nil,
                  archived:     c[:archived] || false
                }
              end

    known_names = all_known.map { |c| c[:name] }
    unknown = (db_competitions - known_names).sort.map do |name|
      { name: name, slug: name.parameterize, logo: nil, has_standings: false, standing_slug: nil, archived: false }
    end

    all_comps       = all_known + unknown
    @competitions   = all_comps.reject { |c| c[:archived] }
    @archived_competitions = all_comps.select { |c| c[:archived] }
    @page_title = "Compétitions Football 2025-2026 — Programme TV et Calendrier | Coup d'Envoi TV"
    @page_desc  = "Retrouvez le programme TV de toutes les compétitions de football : Ligue 1, Champions League, Coupe de France, Premier League et plus encore."

    expires_in 1.hour, public: true
  end

  def show
    slug = params[:slug]

    # Trouver la compétition dans notre liste de référence
    meta = FootballApiService::COMPETITIONS_META.find { |c| c[:name].parameterize == slug }

    if meta
      @competition_name = meta[:name]
      @competition_slug = slug
      @competition_logo = FootballApiService.league_logo(meta[:id])
      @has_standings    = meta[:has_standings]
      @standing_slug    = meta[:has_standings] ? meta[:name].parameterize : nil
      @league_id        = meta[:id]
    else
      # Fallback pour les compétitions hors liste
      @competition_name = slug.tr('-', ' ').split.map(&:capitalize).join(' ')
      @competition_slug = slug
      @competition_logo = nil
      @has_standings    = false
    end

    @matches = Match.where("competition ILIKE ?", "%#{@competition_name}%")
                    .where("start_time >= ?", Time.current - 3.hours)
                    .order(:start_time)
                    .limit(50)

    # Phases finales / bracket pour les compétitions à élimination directe
    knockout_league_ids = [2, 3, 848, 66, 81, 137, 141, 1]
    if meta && knockout_league_ids.include?(meta[:id])
      knockout_rounds = Match.where("competition ILIKE ?", "%#{@competition_name}%")
                             .where.not(round: [nil, ''])
                             .where("start_time >= ?", 3.months.ago)
                             .order(:start_time)
                             .group_by(&:round)
      # Garder uniquement les rounds de phase finale (pas les phases de groupe)
      @knockout_rounds = knockout_rounds.reject do |round_name, _|
        round_name.to_s.downcase.match?(/group|league phase|league stage|ligue|pool|poule|regular/)
      end
    else
      @knockout_rounds = {}
    end

    editorial = competition_editorial(@competition_name)
    @description  = editorial || competition_description(@competition_name)
    @editorial_html = editorial.present?

    # Classement depuis la DB (0 appel API)
    @is_world_cup = meta && meta[:id] == 1
    if @has_standings && meta
      standing = Standing.for_league(meta[:id])
      if @is_world_cup
        # CDM : 12 tableaux de groupes
        @all_groups = standing&.data&.dig(0, "league", "standings") || []
        @standings_rows = @all_groups.first || []
      else
        @standings_rows = standing&.data&.dig(0, "league", "standings", 0) || []
      end
    else
      @standings_rows = []
      @all_groups = []
    end

    # Chaînes qui diffusent cette compétition
    @comp_channel_slugs = meta ? (COMPETITION_CHANNELS[meta[:id]] || []) : []

    # noindex si page vide : pas de texte éditorial humain + aucun match à venir
    @noindex = !@editorial_html && @matches.empty?

    @page_title = "#{@competition_name} 2025-2026 — Programme TV, matchs et résultats | Coup d'Envoi TV"
    @page_desc  = "Programme TV complet #{@competition_name} 2025-2026 : matchs à venir, horaires et chaînes de diffusion (Canal+, beIN Sports, DAZN, France TV)."

    expires_in 10.minutes, public: true
  end

  private

  def competition_editorial(name)
    yaml_path = Rails.root.join("config", "competition_editorial.yml")
    return nil unless File.exist?(yaml_path)
    (YAML.load_file(yaml_path) || {})[name]&.strip
  rescue => e
    Rails.logger.error("competition_editorial.yml error: #{e.message}")
    nil
  end

  def competition_description(name)
    yaml_path = Rails.root.join("config", "competition_descriptions.yml")
    return nil unless File.exist?(yaml_path)
    require "yaml"
    (YAML.load_file(yaml_path) || {})[name]
  rescue => e
    Rails.logger.error("competition_descriptions.yml error: #{e.message}")
    nil
  end
end
