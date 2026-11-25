class GoogleFeatureGate
  def initialize(app)
    @app = app
  end

  def call(env)
    # Stop both the OAuth request and the callback before OmniAuth runs.
    if env["PATH_INFO"].to_s.match?(%r{\A/auth/(?:auth/)?google_oauth2(?:/|\z)}) && !AppFeatures.enabled?("google_login")
      return [ 404, { "content-type" => "text/plain; charset=utf-8", "cache-control" => "no-store" }, [ "Fonctionnalité indisponible." ] ]
    end
    @app.call(env)
  end
end
