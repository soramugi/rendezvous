require 'mail'
require 'action_gmailer'
require 'premailer'

module RV::Mailer
  include ApplicationHelper

  def compose_mail(post, opts = {})
    fail ArgumentError.new('post missing') unless post.present?
    fail ArgumentError.new('user missing') unless opts[:user].present? && opts[:user].is_a?(User)
    fail ArgumentError.new('to missing') unless opts[:to].present?
    fail ArgumentError.new('to mail format invalid') unless ValidatesEmailFormatOf.validate_email_format(opts[:to]).nil?

    html_body = generate_html_mail(post)

    mail = Mail.new do
      from opts[:user].email
      to opts[:to]
      subject post.title
      body post.body

      html_part do
        content_type 'text/html; charset=UTF-8'
        body html_body
      end
    end

    # set ActionGmailer
    config = {
      oauth2_token: opts[:user].google_auth_token,
      account: opts[:user].email
    }.merge(Rendezvous::Application.config.action_mailer.smtp_settings)
    mail.delivery_method(ActionGmailer::DeliveryMethod, config)

    mail
  end

  def generate_html_mail(post)
    path = File.expand_path(File.dirname(__FILE__) + '/mail-template2.html')
    template = File.open(path).read

    html_body = template
                .gsub('__POST_URL__', Settings.rendezvous.app_host + post.decorate.show_path)
                .gsub('__HTML_TITLE__', MarkdownRenderer.new(post.title).render)
                .gsub('__HTML_BODY__', MarkdownRenderer.new(post.body).render)
                .gsub('__RV_URL__', Settings.rendezvous.app_host + '/')

    premailer = Premailer.new(html_body, with_html_string: true, adapter: :nokogiri)
    premailer.to_inline_css
  end
end
