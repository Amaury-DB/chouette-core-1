module NotifiableSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :notification_target, in: %w[user workbench]
    belongs_to :user
  end

  module ClassMethods
    def notification_target_options
      notification_target.values.map { |k| [k && "operation_support.notification_targets.#{k}".t, k] }
    end
  end

  def notify_relevant_users(mailer, action)
    recipients = notification_recipients
    return unless recipients.present?

    mailer_params = yield(recipients)

    MailerJob.perform_later(mailer, action, mailer_params)
    notified_recipients!
  end

  def notified_recipients?
    notified_recipients_at.present?
  end

  def notified_recipients!
    update_column :notified_recipients_at, Time.now
  end

  def notification_recipients
    return [] unless notification_target.present?

    users = if notification_target.to_s == 'user'
      [user]
    else
      workbench.users
    end

    users.compact.map(&:email_recipient)
  end
end
