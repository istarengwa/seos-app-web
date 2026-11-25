module Admin
  class VisualStudioController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action { @source = StudioVersion.find(params[:id]) }
    before_action :allow_builder_inline_styles, only: :builder
    content_security_policy only: :preview do |policy|
      policy.frame_ancestors :self
    end
    content_security_policy only: :builder do |policy|
      policy.style_src :self, :unsafe_inline
      policy.img_src :self, :data, :blob
      policy.frame_src :self, :blob
    end

    def legacy
      redirect_to builder_admin_site_path(@source, page: params[:page].presence || "home"), status: :see_other
    end

    def builder
      @version = @source
      @policies = RetentionPolicyVersion.order(id: :desc).limit(30)
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @source.available_pages.include?(@slug)
      assets = StudioAsset.includes(image_attachment: :blob).order(id: :desc)
      page = @source.site.dig("pages", @slug) || SiteDesign.default_page(@slug)
      canvas = builder_canvas_for(page, @slug)
      legal_documents = StudioLegalDocuments.for_editor(@source)
      published_legal_documents = StudioLegalDocuments.for_editor
      @builder_data = {
        settings: editable_settings,
        legalDocuments: legal_documents,
        legalDocumentHtml: legal_documents.transform_values { |fields| helpers.legal_rich_text(fields["body"]).to_s },
        publishedLegalDocuments: published_legal_documents,
        publishedLegalDocumentHtml: published_legal_documents.transform_values { |fields| helpers.legal_rich_text(fields["body"]).to_s },
        page: @slug,
        legalDocument: params[:document].presence_in(ContentVersion::LEGAL_SLUGS),
        featureBindings: AppFeatures::DEFINITIONS.transform_values { |item| item[:label] },
        digest: @source.digest,
        pages: @source.available_pages.to_h { |slug| [ slug, @source.site.dig("pages", slug) || SiteDesign.default_page(slug) ] },
        templates: builder_templates,
        images: helpers.site_image_options(assets),
        tokens: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        colors: StudioVersion::COLORS,
        colorNames: SiteHelper::COLOR_NAMES,
        options: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        chrome: SiteDesign::CHROME,
        styles: SiteSectionStyle::OPTIONS,
        presets: ContentVersion::PRESETS,
        initialHtml: canvas.fetch("html"),
        initialCss: canvas.fetch("css", ""),
        stylesheets: [ helpers.stylesheet_path("application") ],
        save: builder_save_admin_site_path(@source),
        review: review_admin_site_path(@source, page: @slug),
        preview: preview_admin_studio_path(@source, page: @slug, canvas: "1")
      }
      render layout: "studio_builder"
    end

    def preview
      @studio_version = proposal
      @visual_preview = true
      @visual_revision = params[:revision].to_s.first(20)
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @studio_version.available_pages.include?(@slug)
      @page = @studio_version.site.dig("pages", @slug)
      if @page
        render "site/show", layout: "application"
      elsif @slug == "home"
        render "pages/home", layout: "application"
      else
        @content = ContentVersion.where(id: @studio_version.settings.fetch("editorial_resets", []), slug: @slug).first || ContentVersion.current("page", @slug)
        if @content
          render "contents/show", layout: "application"
        else
          @page = SiteDesign.default_page(@slug)
          render "site/show", layout: "application"
        end
      end
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render plain: error.message, status: :unprocessable_content
    end

    def builder_save
      draft = proposal
      raise Exchanges::Invalid, "Cette copie a changé. Rechargez le Studio V2 avant d’enregistrer." unless params[:digest] == @source.digest
      version = Studio.change!(actor: current_user, source: @source, name: "Composition Studio V2", settings: draft.settings.slice("site", "tokens", "legal_documents"))
      render json: {
        digest: version.digest,
        url: builder_admin_site_path(version),
        save: builder_save_admin_site_path(version),
        preview: preview_admin_studio_path(version, page: params[:page].presence || "home", canvas: "1"),
        review: review_admin_site_path(version, page: params[:page].presence || "home")
      }
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def allow_builder_inline_styles
      request.content_security_policy_nonce_directives = %w[script-src]
    end

    def editable_settings
      settings = @source.settings.deep_dup
      settings.delete("legal_documents") if @source.status == "published"
      settings.dig("site", "pages")&.each_value do |page|
        page["blocks"]&.reject! { |block| SiteDesign::RETIRED_TEMPLATES.include?(block["template"]) }
      end
      settings
    end

    def proposal
      raw = params[:document].to_s
      raise Exchanges::Invalid, "Cette page est trop volumineuse." if raw.bytesize > 2.megabytes
      document = JSON.parse(raw)
      raise Exchanges::Invalid, "Le contenu de la copie est invalide." unless document.is_a?(Hash) && (document.keys - %w[site tokens pages editorial_resets legal_documents]).empty?
      document.dig("site", "pages")&.each_value do |page|
        next unless page.is_a?(Hash) && page["canvas"].is_a?(Hash)
        page["canvas"] = {
          "version" => 1,
          "html" => SiteCanvasDocument.sanitize_html(page.dig("canvas", "html")),
          "css" => SiteCanvasDocument.sanitize_css(page.dig("canvas", "css"))
        }
      end
      settings = editable_settings.merge(document.slice("site", "tokens", "legal_documents"))
      StudioVersion.new(author: current_user, name: "Aperçu privé", settings: settings).tap(&:validate!)
    rescue JSON::ParserError
      raise Exchanges::Invalid, "Le contenu de la copie est illisible."
    end

    def builder_canvas_for(page, slug)
      @feature_editor = true
      @studio_version = @source
      @visual_preview = true
      if page["canvas"].present?
        content = helpers.site_canvas_html(page).to_s
        css = SiteCanvasDocument.sanitize_css(page.dig("canvas", "css"))
      else
        rendered = render_to_string(partial: "site/page", locals: { page: page, slug: slug })
        fragment = Nokogiri::HTML5.fragment(rendered)
        css = fragment.css("style").map(&:text).join("\n")
        fragment.css("style,.site-edit-link").remove
        content = (fragment.at_css(".maquette-surface") || fragment).to_html
      end
      header = Nokogiri::HTML5.fragment(render_to_string(partial: "shared/header"))
      footer = Nokogiri::HTML5.fragment(render_to_string(partial: "shared/footer"))
      header.at_css("header")["data-studio-chrome"] = "header"
      footer.at_css("footer")["data-studio-chrome"] = "footer"
      html = %(#{header}<main id="main-content" data-studio-page>#{content}</main>#{footer})
      { "version" => 1, "html" => protect_builder_dynamic_markup(html), "css" => css }
    end

    def protect_builder_dynamic_markup(markup)
      fragment = Nokogiri::HTML5.fragment(markup)
      {
        ".category-grid" => "Catégories de l’application",
        ".ad-grid" => "Annonces de l’application",
        ".testimonial-grid" => "Avis et témoignages validés",
        ".travel-missions-slot" => "Missions solidaires",
        ".legal-tabs-slot" => "Documents légaux",
        ".chain-home-grid" => "Chaînes d’entraide"
      }.each do |selector, label|
        fragment.css(selector).each do |node|
          node["data-studio-dynamic"] = label
          node["class"] = [ node["class"], "studio-dynamic-widget" ].compact.join(" ")
        end
      end
      fragment.to_html
    end

    def builder_templates
      SiteDesign.editable_templates.to_h do |key, template|
        values = template.fetch("fields").transform_values { |field| field["default"].to_s }
        block = { "id" => "preset-#{key}", "template" => key, "values" => values }
        markup =
          if key == "spacer"
            '<div class="studio-spacer" style="min-height:96px"></div>'
          elsif key == "text"
            '<section class="section"><div class="container"><h2>Votre titre</h2><p>Votre contenu</p><a class="btn btn-deep" href="/contact">En savoir plus</a></div></section>'
          else
            helpers.maquette_html(template.fetch("html", ""), block: block).to_s
          end
        markup = protect_builder_dynamic_markup(markup)
        tone = SiteSectionSurface.tone(block)
        color = SiteSectionSurface::COLORS.fetch(tone)
        feature = AppFeatures::TEMPLATES[key]
        binding = feature ? %( data-app-feature="#{feature}") : ""
        markup = %(<div class="site-section"#{binding} data-surface-tone="#{tone}" style="--section-bg:#{color};--previous-bg:var(--cream);--next-bg:var(--cream)">#{markup}</div>)
        [ key, { name: helpers.site_section_name(key), description: helpers.site_section_description(key), html: markup } ]
      end
    end
  end
end
