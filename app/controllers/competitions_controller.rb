class CompetitionsController < ApplicationController

  def index
    db_competitions = Match.distinct.pluck(:competition).compact

    # On ordonne selon COMPETITIONS_META (popularité), les inconnus vont à la fin
    known = FootballApiService::COMPETITIONS_META
              .select { |c| db_competitions.include?(c[:name]) }
              .map do |c|
                {
                  name:         c[:name],
                  slug:         c[:name].parameterize,
                  logo:         FootballApiService.league_logo(c[:id]),
                  has_standings: c[:has_standings],
                  standing_slug: c[:has_standings] ? c[:name].parameterize : nil
                }
              end

    known_names = known.map { |c| c[:name] }
    unknown = (db_competitions - known_names).sort.map do |name|
      { name: name, slug: name.parameterize, logo: nil, has_standings: false, standing_slug: nil }
    end

    @competitions = known + unknown
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

    @description = competition_description(@competition_name)

    @page_title = "#{@competition_name} 2025-2026 — Programme TV, matchs et résultats | Coup d'Envoi TV"
    @page_desc  = "Programme TV complet #{@competition_name} 2025-2026 : matchs à venir, horaires et chaînes de diffusion (Canal+, beIN Sports, DAZN, France TV)."

    expires_in 10.minutes, public: true
  end

  private

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
