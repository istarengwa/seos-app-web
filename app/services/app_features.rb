class AppFeatures
  # Optional modules only. Listings, exchanges, balances and the points engine
  # deliberately have no switch in this registry.
  DEFINITIONS = {
    "associations" => { label: "Associations", description: "Annuaire, propositions d’association, équipes et espaces associatifs.", flag: "associations_enabled", group: "community", dependencies: [] },
    "quests" => { label: "Quêtes", description: "Objectifs, preuves et suivi des quêtes. Les calculs du moteur de points restent inchangés.", flag: "quests_enabled", group: "community", dependencies: [] },
    "chains" => { label: "Chaînes d’entraide", description: "Création de chaînes, invitations, confirmations et présentation sur le site.", flag: "chains_enabled", group: "community", dependencies: [] },
    "referrals" => { label: "Parrainage", description: "Liens, invitations et nouveaux rattachements de parrains.", flag: "referrals_enabled", group: "community", dependencies: [] },
    "testimonials" => { label: "Témoignages", description: "Dépôt et publication des témoignages écrits ou vidéo.", flag: "testimonials_enabled", group: "community", dependencies: [] },
    "highlights" => { label: "Mises en avant", description: "Demandes et affichage des annonces mises en avant. Les annonces restent accessibles.", flag: "highlights_enabled", group: "community", dependencies: [] },
    "voyage" => { label: "Voyage solidaire et missions", description: "Catalogue de missions, candidatures et échanges liés aux missions.", flag: "voyage_enabled", group: "services", dependencies: [ "associations" ] },
    "public_map" => { label: "Carte des annonces", description: "Affichage cartographique et chargement des fonds de carte.", flag: "public_map_enabled", group: "services", dependencies: [] },
    "journal" => { label: "Journal", description: "Articles publics du journal et liens vers ces articles.", flag: "journal_enabled", group: "services", dependencies: [] },
    "google_login" => { label: "Connexion Google", description: "Connexion et liaison d’un compte Google. La messagerie Gmail reste indépendante.", flag: "google_login_enabled", group: "services", dependencies: [] }
  }.freeze
  TEMPLATES = { "community-associations" => "associations", "home-4" => "chains", "home-6" => "testimonials", "travel-hero" => "voyage", "travel-missions" => "voyage" }.freeze
  COMMUNITY_TABS = { "quests" => "quests", "proofs" => "quests", "chains" => "chains", "testimonials" => "testimonials", "highlights" => "highlights" }.freeze
  NOTICE_PREFIXES = { "achievement" => "quests", "top" => "highlights", "chain" => "chains", "organization" => "associations", "mission" => "voyage", "testimonial" => "testimonials", "referral" => "referrals" }.freeze

  def self.definition(key) = DEFINITIONS.fetch(key.to_s)
  def self.flags = FeatureFlag.where(key: DEFINITIONS.values.map { |item| item[:flag] }).index_by(&:key)
  def self.enabled?(key, values = flags)
    item = definition(key)
    values[item[:flag]]&.enabled != false && item[:dependencies].all? { |parent| enabled?(parent, values) }
  end
  def self.configured?(key) = key.to_s != "google_login" || (ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?)
  def self.quest_available?(quest)
    proof_available?(quest.reward_key)
  end
  def self.proof_available?(kind)
    dependency = { "chain" => "chains", "referral" => "referrals", "written" => "testimonials", "video" => "testimonials" }[kind]
    enabled?("quests") && (!dependency || enabled?(dependency))
  end
  def self.require!(key)
    raise Exchanges::Invalid, "La fonctionnalité « #{definition(key)[:label]} » est désactivée." unless enabled?(key)
  end
  def self.digest(values = flags)
    Digest::SHA256.hexdigest(DEFINITIONS.map { |key, item| [ key, values[item[:flag]]&.attributes&.slice("enabled", "lock_version", "disabled_at") ] }.to_json)
  end
  def self.change!(actor:, key:, enabled:, reason:, expected:, password: nil)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.active? && actor.confirmed?
    item = definition(key)
    raise Exchanges::Invalid, "Précisez le motif du changement (500 caractères maximum)." unless reason.is_a?(String) && reason.strip.present? && reason.size <= 500
    raise Exchanges::Invalid, "Choisissez Actif ou Désactivé." unless [ true, false ].include?(enabled)
    if key.to_s == "google_login" && !enabled && !actor.valid_password?(password.to_s)
      raise Exchanges::Invalid, "Confirmez votre mot de passe SEOS pour conserver un accès sans Google."
    end
    FeatureFlag.transaction do
      # Lock absent keys as well as existing rows when two administrators confirm
      # a first change at once. PostgreSQL readers remain unblocked.
      FeatureFlag.connection.execute("LOCK TABLE feature_flags IN SHARE ROW EXCLUSIVE MODE") if FeatureFlag.connection.adapter_name == "PostgreSQL"
      values = FeatureFlag.where(key: DEFINITIONS.values.map { |entry| entry[:flag] }).order(:id).lock.index_by(&:key)
      raise Exchanges::Invalid, "Les fonctionnalités ont changé. Vérifiez à nouveau les conséquences avant de confirmer." unless expected == digest(values)
      flag = values[item[:flag]] || FeatureFlag.new(key: item[:flag], enabled: true)
      return flag if flag.enabled == enabled
      before = flag.enabled
      flag.enabled = enabled
      flag.disabled_at = Time.current unless enabled
      flag.save!
      AuditLog.create!(actor: actor, target: flag, action: "feature.change", reason: reason, metadata: { "feature" => key.to_s, "from" => before ? "enabled" : "disabled", "to" => enabled ? "enabled" : "disabled" })
      flag
    end
  rescue KeyError
    raise Exchanges::Invalid, "Fonctionnalité inconnue."
  end

  def self.notice_feature(key) = NOTICE_PREFIXES[key.to_s.split(":").first]
  def self.notice_allowed?(notice)
    key = notice_feature(notice.event_key)
    return true unless key
    values = flags
    return false unless enabled?(key, values)
    keys = [ key, *definition(key)[:dependencies] ]
    cutoff = keys.filter_map { |entry| values[definition(entry)[:flag]]&.disabled_at }.max
    !cutoff || notice.created_at > cutoff
  end

  def self.path_feature(path)
    case path.to_s.split("?").first
    when %r{\A/(associations|compte/organisations|organisations)(/|\z)} then "associations"
    when %r{\A/(voyage-solidaire|compte/candidatures)(/|\z)}, "/pages/voyage-solidaire", "/decouvrir/voyage-solidaire" then "voyage"
    when %r{\A/(chaines|compte/chaines)(/|\z)}, "/#chaines" then "chains"
    when %r{\A/(parrainage)(/|\z)} then "referrals"
    when %r{\A/(temoignages|compte/temoignages)(/|\z)} then "testimonials"
    when %r{\A/journal(/|\z)} then "journal"
    when %r{\A/auth/(?:auth/)?google_oauth2(/|\z)} then "google_login"
    end
  end

  def self.impact(key)
    case key.to_s
    when "associations" then { "Associations conservées" => Organization.where(kind: "association").count, "Demandes en attente" => Organization.where(kind: "association", status: "pending").count, "Missions dépendantes" => VolunteerMission.count }
    when "quests" then { "Quêtes conservées" => Achievement.count, "Preuves conservées" => UserAchievement.count }
    when "chains" then { "Chaînes conservées" => HelpChain.count, "Services conservés" => ChainService.count }
    when "referrals" then { "Parrainages conservés" => Referral.count, "Liens conservés" => ReferralLink.count }
    when "testimonials" then { "Témoignages conservés" => Testimonial.count, "Demandes en attente" => Testimonial.where(status: "submitted").count }
    when "highlights" then { "Demandes conservées" => TopListingRequest.count }
    when "voyage" then { "Missions conservées" => VolunteerMission.count, "Candidatures conservées" => MissionApplication.count }
    when "public_map" then { "Annonces conservées dans le catalogue" => Listing.published.count }
    when "journal" then { "Versions d’articles conservées" => ContentVersion.where(kind: "article").count }
    when "google_login" then { "Comptes liés à Google" => GoogleIdentity.count }
    else {}
    end
  end
end
