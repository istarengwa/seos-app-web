require Rails.root.join("app/middleware/google_feature_gate")
Rails.application.config.middleware.insert_before Warden::Manager, GoogleFeatureGate
