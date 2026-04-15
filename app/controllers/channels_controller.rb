class ChannelsController < ApplicationController
  CHANNELS_META = [
    {
      slug:      "canal-plus",
      name:      "Canal+",
      keywords:  ["Canal+"],
      tagline:   "Champions League, Europa League, Conference League",
      meta_desc: "Programme des matchs Canal+ : Champions League, Europa League, Conference League. Abonnements à partir de 19,99 €/mois. Tous les prochains matchs sur Canal+."
    },
    {
      slug:      "bein-sports",
      name:      "beIN Sports",
      keywords:  ["beIN"],
      tagline:   "La Liga, Bundesliga, Ligue 2, NBA",
      meta_desc: "Programme des matchs beIN Sports : La Liga, Bundesliga, Ligue 2, NBA. 15 €/mois sans engagement. Tous les prochains matchs sur beIN Sports."
    },
    {
      slug:      "dazn",
      name:      "DAZN",
      keywords:  ["DAZN"],
      tagline:   "Ligue 1, Serie A, Betclic Élite, sports de combat",
      meta_desc: "DAZN France 2025-2026 : Ligue 1 incluse pour 16,99 €/mois, Serie A, Eredivisie, boxe, MMA et PFL. Le meilleur rapport qualité/prix du marché foot."
    },
    {
      slug:      "amazon-prime",
      name:      "Amazon Prime",
      keywords:  ["Amazon"],
      tagline:   "Pass Ligue 1, quelques affiches foot",
      meta_desc: "Pass Ligue 1 Amazon Prime Video : ce qu'il inclut vraiment, le prix réel et notre avis honnête. Prochains matchs disponibles sur Amazon Prime Video Sport."
    },
    {
      slug:      "rmc-sport",
      name:      "RMC Sport",
      keywords:  ["RMC"],
      tagline:   "UFC, PFL, foot européen, NFL",
      meta_desc: "RMC Sport : la chaîne des sports de combat (UFC, PFL) et du foot européen. Disponible sans SFR en version digitale. Programme et prochains matchs sur RMC Sport."
    },
    {
      slug:      "france-tv",
      name:      "France TV",
      keywords:  ["France 2", "France 3", "France 4", "France TV"],
      tagline:   "Coupe de France, Bleues, Espoirs - gratuit et sans pub",
      meta_desc: "France TV diffuse la Coupe de France, les Bleues et les Espoirs gratuitement et sans pub pendant les matchs. Programme foot sur France 2 et France 3."
    },
    {
      slug:      "tf1",
      name:      "TF1",
      keywords:  ["TF1"],
      tagline:   "Équipe de France, Ligue des Nations - gratuit",
      meta_desc: "TF1 diffuse les matchs de l'équipe de France masculine (Ligue des Nations, qualifications) gratuitement. TF1+ pour les replays. Attention : le Mondial 2026 est sur M6."
    },
    {
      slug:      "m6",
      name:      "M6",
      keywords:  ["M6"],
      tagline:   "Mondial 2026 - 54 matchs dont tous les Bleus, gratuit",
      meta_desc: "M6 diffuse le Mondial 2026 gratuitement : 54 matchs dont tous les matchs des Bleus. Replay gratuit sur 6play sans abonnement."
    },
  ].freeze

  def index
    @channels = CHANNELS_META.map do |ch|
      conditions = ch[:keywords].map { "tv_channels ILIKE ?" }.join(" OR ")
      values     = ch[:keywords].map { |k| "%#{k}%" }
      count = Match.where("start_time >= ?", Time.current)
                   .where(conditions, *values)
                   .count
      ch.merge(upcoming_count: count)
    end

    @page_title = "Chaînes TV foot 2025-2026 : Canal+, beIN Sports, DAZN - programme | Coup d'Envoi TV"
    @page_desc  = "Retrouvez tous les matchs de football par chaîne TV : Canal+, beIN Sports, DAZN, Amazon Prime, RMC Sport, France TV. Programme et prochains matchs."
    expires_in 1.hour, public: true
  end

  def show
    @channel = CHANNELS_META.find { |c| c[:slug] == params[:slug] }
    render "errors/not_found", status: :not_found and return unless @channel

    conditions = @channel[:keywords].map { "tv_channels ILIKE ?" }.join(" OR ")
    values     = @channel[:keywords].map { |k| "%#{k}%" }

    @matches = Match.where("start_time >= ?", Time.current - 3.hours)
                    .where(conditions, *values)
                    .order(:start_time)
                    .limit(30)

    @editorial = channel_editorial(@channel[:slug])
    @noindex   = @editorial.blank? && @matches.empty?

    @page_title = "#{@channel[:name]} Football 2025-2026 : #{@channel[:tagline]} | Coup d'Envoi TV"
    @page_desc  = @channel[:meta_desc]
    expires_in 30.minutes, public: true
  end

  private

  def channel_editorial(slug)
    yaml_path = Rails.root.join("config", "channel_editorial.yml")
    return nil unless File.exist?(yaml_path)
    (YAML.load_file(yaml_path) || {})[slug]&.strip
  rescue => e
    Rails.logger.error("channel_editorial.yml error: #{e.message}")
    nil
  end
end
