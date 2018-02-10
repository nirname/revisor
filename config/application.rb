require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Revisor
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Europe/Moscow'
    config.generators do |g|
      g.test_framework :rspec
    end
    config.settings = config_for(:settings)

    # config.eager_load_paths += Dir['app/models/reports/*.rb']
    # Dir['app/models/reports/*.rb'].each { |file| require file }
    ActiveSupport::Reloader.to_prepare do
      Dir['app/models/reports/*.rb'].each {|file| require_dependency file}
    end
  end
end
