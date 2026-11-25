module StudioRequestHelpers
  def save_studio_version(source, settings, page: "home")
    post builder_save_admin_site_path(source), params: { document: settings.to_json, digest: source.digest, page: page }, as: :json
    expect(response).to have_http_status(:ok), response.body
    StudioVersion.find(response.parsed_body.fetch("url").split("/")[-2])
  end

  def studio_builder_configuration
    JSON.parse(Nokogiri::HTML(response.body).at_css("[data-studio-config]").text)
  end
end

RSpec.configure { |config| config.include StudioRequestHelpers, type: :request }
