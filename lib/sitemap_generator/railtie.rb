# frozen_string_literal: true

module SitemapGenerator
  class Railtie < Rails::Railtie
    # Top level options object to namespace all settings
    config.sitemap = ActiveSupport::OrderedOptions.new

    rake_tasks do
      load 'tasks/sitemap_generator_tasks.rake'
    end

    # Recognize existing Rails options as defaults for config.sitemap.*
    # Then, after_initialize, "compile" them onto the SitemapGenerator classes.
    initializer 'sitemap_generator.set_configs' do |app|
      # routes.default_url_options takes precedence, falling back to configs
      url_opts = (app.default_url_options || {})
                 .with_defaults(config.try(:action_controller).try(:default_url_options) || {})
                 .with_defaults(config.try(:action_mailer).try(:default_url_options) || {})
                 .with_defaults(config.try(:active_job).try(:default_url_options) || {})

      config.sitemap.default_host ||= ActionDispatch::Http::URL.full_url_for(url_opts) if url_opts.key?(:host)

      # Rails defaults action_controller.asset_host and action_mailer.asset_host
      # to the top-level config.asset_host so we get that for free here.
      config.sitemap.sitemaps_host ||= [
        config.try(:action_controller).try(:asset_host),
        config.try(:action_mailer).try(:asset_host)
      ].grep(String).first

      config.sitemap.compress = config.try(:assets).try(:gzip) if config.sitemap.compress.nil?

      config.sitemap.public_path ||= app.paths['public'].first

      config.after_initialize do # TODO: ActiveSupport.on_load(:sitemap_generator)
        config.sitemap.except(:adapter).each do |k, v|
          SitemapGenerator::Sitemap.send("#{k}=", v)
        end
      end
    end
  end
end
