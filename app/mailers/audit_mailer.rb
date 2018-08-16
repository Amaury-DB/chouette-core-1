class AuditMailer < ApplicationMailer
  def self.enabled?
    !!Rails.configuration.enable_automated_audits
  end

  def audit opts={}
    @content = ReferentialAudit::Full.new.perform(opts.update({output: :html})).join("</td></tr><tr><td>")
    mail to: Rails.configuration.automated_audits_recipients, subject: t('mailers.audit_mailer.audit.subject', date: Time.now.l(format: :short))
  end
end
