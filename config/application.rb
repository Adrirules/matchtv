require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Matchtv
  class Application < Rails::Application
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end

    config.load_defaults 7.0

    # Configuration de la langue et du fuseau horaire
    config.time_zone = "Paris"
    config.active_record.default_timezone = :utc

    # C'est ici qu'on définit le français par défaut
    config.i18n.default_locale = :fr
  end
end
