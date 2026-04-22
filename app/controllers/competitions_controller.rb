class CompetitionsController < ApplicationController

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
    knockout_league_ids = [2, 3, 848, 66, 137, 141, 1]
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
