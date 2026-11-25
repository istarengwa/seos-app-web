Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.img_src :self, :data
    policy.media_src :self, :https
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self
    policy.connect_src :self
    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
  end
  # Turbo keeps the document CSP across visits: inline styles need the same
  # nonce until the session ends, without a second GET consuming flash messages.
  config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
