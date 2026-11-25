module AppFeaturesHelper
  def app_feature_visible?(key) = key.blank? || @feature_editor || AppFeatures.enabled?(key)

  def app_feature_link_visible?(url)
    uri = URI.parse(url.to_s)
    return true if uri.host && uri.host != request.host
    path = uri.path.to_s + (uri.fragment ? "##{uri.fragment}" : "")
    key = AppFeatures.path_feature(path)
    key = "chains" if [ "/#chaines", "/#site-section-home-4" ].include?(path)
    return AppFeatures.enabled?("quests") || AppFeatures.enabled?("highlights") if uri.path == account_community_path
    key.nil? || AppFeatures.enabled?(key)
  rescue URI::InvalidURIError
    true
  end

  def app_feature_markup(markup, blocks: [])
    # Keep HTML attribute values escaped when serializing user-provided text.
    doc = Nokogiri::HTML.fragment(markup.to_s)
    blocks.each do |block|
      key = AppFeatures::TEMPLATES[block["template"]]
      next unless key
      doc.css("[data-studio-block]").select { |node| node["data-studio-block"] == block["id"] }.each { |node| node["data-app-feature"] = key }
    end
    { ".community-associations" => "associations", ".chain-home,.featured-chains,.profile-chains,.chain-home-grid" => "chains", ".testimonial-grid" => "testimonials", ".travel-missions-slot,.travel-hero" => "voyage" }.each do |selector, key|
      doc.css(selector).each do |node|
        root = node.ancestors.find { |parent| parent["data-studio-block"] } || node.ancestors.find { |parent| parent.name == "section" } || node
        root["data-app-feature"] ||= key
      end
    end
    doc.css("[data-app-feature-disabled]").each { |node| node.remove_attribute("data-app-feature-disabled") }
    doc.css("[data-app-feature]").each do |node|
      key = node["data-app-feature"]
      next unless AppFeatures::DEFINITIONS.key?(key) && !AppFeatures.enabled?(key)
      @feature_editor ? node["data-app-feature-disabled"] = "true" : node.remove
    end
    unless @feature_editor
      doc.css("a[href]").each { |node| node.remove unless app_feature_link_visible?(node["href"]) }
    end
    doc.to_html.html_safe
  end

  def app_feature_readonly(markup)
    doc = Nokogiri::HTML.fragment(markup.to_s)
    doc.css("form").each do |form|
      next if form["method"].to_s.downcase == "get" || form.at_css('input[name="operation"][value="reveal"]')
      fieldset = Nokogiri::XML::Node.new("fieldset", doc)
      fieldset["disabled"] = "disabled"
      fieldset["class"] = "feature-readonly"
      form.children.each { |child| fieldset.add_child(child) }
      form.add_child(fieldset)
    end
    doc.to_html.html_safe
  end
end
