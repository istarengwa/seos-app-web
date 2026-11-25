class FeatureFlag < ApplicationRecord
  validates :key, inclusion: { in: ->(_record) { AppFeatures::DEFINITIONS.values.map { |item| item[:flag] } } }, uniqueness: true
  validates :enabled, inclusion: { in: [ true, false ] }
  def self.voyage_enabled? = AppFeatures.enabled?("voyage")
  def self.tile_url = ENV.fetch("MAP_TILE_URL", Rails.env.test? ? "" : "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
  def self.map_enabled? = AppFeatures.enabled?("public_map")
end
