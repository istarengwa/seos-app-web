# No demonstration accounts, rewards, missions, legal documents or reference data.
# Keep the completion marker even if an administrator later removes the homepage.
SeedRun.transaction do
  run = SeedRun.create_or_find_by!(name: "production_home")
  run.with_lock do
    unless run.completed_at
      unless StudioVersion.exists?
        version = StudioVersion.new(
          name: "Accueil initial",
          system_generated: true,
          status: "published",
          published_at: Time.current,
          settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } }
        )
        version.validated_digest = version.digest
        version.save!
      end
      run.update!(completed_at: Time.current)
    end
  end
end
