class SeoController < ApplicationController
  PRIVATE_PATHS = %w[/compte /auth /admin /super_admin /membres /organisations /medias /preferences-confidentialite].freeze
  def sitemap
    @listings = Catalogue.call({})
    render formats: :xml
  end
  def robots
    private_rules = PRIVATE_PATHS.map { |path| "Disallow: #{path}\n" }.join
    # Public content is open to search and AI crawlers. Account areas stay private.
    rules = [ "*", "GPTBot", "Google-Extended", "ClaudeBot", "CCBot", "OAI-SearchBot" ].map do |bot|
      "User-agent: #{bot}\nAllow: /\n#{private_rules}\n"
    end.join
    rules += "Sitemap: #{sitemap_url}\n"
    render plain: rules
  end
end
