class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  enum :role, { owner: "owner", manager: "manager", editor: "editor" }, validate: true
  enum :status, { active: "active", revoked: "revoked" }, validate: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :preserve_last_owner, on: :update
  before_destroy :preserve_owner_before_destroy

  private

  def preserve_last_owner(removing: false)
    return unless role_in_database == "owner" && status_in_database == "active"
    return unless removing || role != "owner" || status != "active" || organization_id_changed?

    original = Organization.find(organization_id_in_database)
    original.with_lock do
      unless original.organization_memberships.active.where(role: "owner").where.not(id: id).exists?
        errors.add(:base, "L’organisation doit conserver un propriétaire actif")
      end
    end
  end

  def preserve_owner_before_destroy
    preserve_last_owner(removing: true)
    throw :abort if errors.any?
  end
end
