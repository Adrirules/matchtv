require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Matchtv
  class Application < Rails::Application
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end

    config.load_defaults 7.0

    # LA CORRECTION EST ICI :
    config.time_zone = "Paris"
    config.active_record.default_timezone = :utc
  end
end
