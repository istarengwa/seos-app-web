class NotificationMailer < ApplicationMailer
  def notice(notification)
    @notification = notification
    headers["Message-ID"] = "<seos-notification-#{notification.id}@seos.test>"
    mail(to: notification.user.email, subject: notification.title)
  end
end
