# Preview all emails at http://localhost:3000/rails/mailers/publication_mailer
class PublicationMailerPreview < ActionMailer::Preview

  def publish
    dest = Destination::Mail.new(publication_setup_id: 1, name: 'test destination', recipients: ["test@test.com"], email_title: "Publication par Mail", email_text: "Bonjour", attached_export_file: true)
    PublicationMailer.publish(Publication.first, dest)
  end

end