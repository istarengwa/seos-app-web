require "rails_helper"

RSpec.describe "Notifications des modules désactivés", type: :job do
  it "termine sans envoi une notification en attente, y compris après réactivation" do
    actor = create(:user, :super_admin)
    user = create(:user)
    notice = Notification.notify!(user: user, key: "chain:queued", title: "Une invitation")
    travel 2.seconds do
      AppFeatures.change!(actor: actor, key: "chains", enabled: false, reason: "Fermeture", expected: AppFeatures.digest)
      expect { NotificationEmailJob.perform_now(notice) }.not_to change(ActionMailer::Base.deliveries, :count)
      AppFeatures.change!(actor: actor, key: "chains", enabled: true, reason: "Réouverture", expected: AppFeatures.digest)
      expect { NotificationEmailJob.perform_now(notice.reload) }.not_to change(ActionMailer::Base.deliveries, :count)
    end
    expect(notice.reload.emailed_at).to be_nil
    expect(Notification.find(notice.id)).to eq(notice)
  end
end
