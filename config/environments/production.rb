require "active_support/core_ext/integer/time"

Rails.application.configure do
  # --- CONFIGURATION DE BASE ---
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.require_master_key = true

  # --- PERFORMANCE & ASSETS (Boost Lighthouse) ---

  # Indispensable pour Heroku : On sert les fichiers statiques
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || true

  # Cache agressif pour les images, CSS et JS (Améliore le score Performance)
  # Les navigateurs garderont les logos en mémoire au lieu de les redemander
  config.public_file_server.headers = {
    'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000',
    'Expires' => "#{1.year.from_now.to_formatted_s(:rfc822)}"
  }

  # Compression des assets (Réduit le temps de chargement)
  config.assets.js_compressor = :terser
  config.assets.css_compressor = :sass
  config.assets.compile = false

  # --- SÉCURITÉ (Boost Best Practices) ---
  config.force_ssl = true

  # --- STOCKAGE & MAILER ---
  config.active_storage.service = :local
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true

  # --- LOGS ---
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # --- BASE DE DONNÉES & DEPRECATIONS ---
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # --- URLS & DOMAINE (Essentiel pour le Sitemap dynamique) ---
  config.action_controller.default_url_options = { host: "www.coupdenvoi.tv", protocol: "https" }
  config.action_mailer.default_url_options = { host: "www.coupdenvoi.tv", protocol: "https" }
end
