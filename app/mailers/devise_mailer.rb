class DeviseMailer < Devise::Mailer
  add_template_helper MailerHelper 
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def confirmation_instructions(user, token, opts={})
    @user  = User.find(user.id)
    @token = token
    mail to: @user.email, subject: t('mailers.confirmation_mailer.subject')
  end

  def invitation_instructions(user, token, opts={})
    @user  = User.find(user.id)
    @token = token
    mail to: @user.email, subject: t('mailers.invitation_mailer.created.subject')
  end

    def reset_password_instructions(user, token, opts={})
    @user      = User.find(user.id)
    @token = token
    mail to: @user.email, subject: t('mailers.password_mailer.updated.subject')
  end
end