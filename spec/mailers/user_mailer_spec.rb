# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, name: 'Test User', email: 'test@example.com') }
  let(:admin) { create(:user, :admin, email: 'admin@example.com') }
  
  before do
    # Set default URL options for the test environment
    Rails.application.routes.default_url_options[:host] = 'example.com'
  end
  
  describe '#welcome_email' do
    let(:mail) { UserMailer.welcome_email(user) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome to Our App')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@example.com'])
    end
    
    it 'includes the user\'s name in the body' do
      expect(mail.body.encoded).to include("Hello #{user.name},")
    end
    
    it 'includes a link to the login page' do
      expect(mail.body.encoded).to have_link('Log in here', href: 'http://example.com/login')
    end
    
    it 'includes the support email' do
      expect(mail.body.encoded).to include('support@example.com')
    end
    
    it 'is a multipart email (html and text)' do
      expect(mail).to be_multipart
      expect(mail.parts.size).to eq(2)
      expect(mail.parts[0].content_type).to include('text/plain')
      expect(mail.parts[1].content_type).to include('text/html')
    end
  end
  
  describe '#password_reset' do
    let(:token) { 'reset_token_123' }
    let(:mail) { UserMailer.password_reset(user, token) }
    
    before do
      allow(user).to receive(:reset_password_token).and_return(token)
    end
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Password Reset Instructions')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@example.com'])
    end
    
    it 'includes the reset link with token' do
      reset_url = "http://example.com/password/reset?token=#{token}"
      expect(mail.body.encoded).to have_link('Reset Password', href: reset_url)
    end
    
    it 'mentions the token expiry time' do
      expect(mail.body.encoded).to include('This link will expire in 24 hours.')
    end
    
    it 'includes a notice if not requested by the user' do
      expect(mail.body.encoded).to include('If you did not request this password reset')
    end
  end
  
  describe '#email_verification' do
    let(:token) { 'verification_token_456' }
    let(:mail) { UserMailer.email_verification(user, token) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Verify Your Email Address')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@example.com'])
    end
    
    it 'includes the verification link' do
      verify_url = "http://example.com/verify-email?token=#{token}"
      expect(mail.body.encoded).to have_link('Verify Email', href: verify_url)
    end
    
    it 'mentions the token expiry time' do
      expect(mail.body.encoded).to include('This link will expire in 24 hours.')
    end
  end
  
  describe '#account_locked' do
    let(:mail) { UserMailer.account_locked(user) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Your Account Has Been Locked')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['security@example.com'])
    end
    
    it 'mentions the account lock' do
      expect(mail.body.encoded).to include('Your account has been locked due to multiple failed login attempts.')
    end
    
    it 'includes a link to unlock the account' do
      unlock_url = 'http://example.com/unlock-account'
      expect(mail.body.encoded).to have_link('Unlock Account', href: unlock_url)
    end
    
    it 'includes contact information for support' do
      expect(mail.body.encoded).to include('If you did not attempt to log in')
      expect(mail.body.encoded).to include('security@example.com')
    end
  end
  
  describe '#new_device_sign_in' do
    let(:ip) { '192.168.1.1' }
    let(:location) { 'New York, NY' }
    let(:device) { 'Chrome on Windows 10' }
    let(:mail) { UserMailer.new_device_sign_in(user, ip, location, device) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('New Sign-In Detected')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['security@example.com'])
    end
    
    it 'includes the device and location information' do
      expect(mail.body.encoded).to include(ip)
      expect(mail.body.encoded).to include(location)
      expect(mail.body.encoded).to include(device)
    end
    
    it 'includes a link to change password if suspicious' do
      expect(mail.body.encoded).to have_link('change your password', href: 'http://example.com/change-password')
    end
  end
  
  describe '#two_factor_authentication_code' do
    let(:code) { '123456' }
    let(:mail) { UserMailer.two_factor_authentication_code(user, code) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Your Two-Factor Authentication Code')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['security@example.com'])
    end
    
    it 'includes the authentication code' do
      expect(mail.body.encoded).to include(code)
    end
    
    it 'mentions the code expiry time' do
      expect(mail.body.encoded).to include('This code will expire in 5 minutes.')
    end
    
    it 'includes a security notice' do
      expect(mail.body.encoded).to include('Do not share this code with anyone.')
    end
  end
  
  describe '#admin_notification' do
    let(:subject_text) { 'New User Registration' }
    let(:message) { 'A new user has registered on the platform.' }
    let(:mail) { UserMailer.admin_notification(admin, subject_text, message) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq(subject_text)
      expect(mail.to).to eq([admin.email])
      expect(mail.from).to eq(['notifications@example.com'])
    end
    
    it 'includes the notification message' do
      expect(mail.body.encoded).to include(message)
    end
    
    it 'includes a link to the admin dashboard' do
      expect(mail.body.encoded).to have_link('View in Admin Dashboard', 
                                           href: 'http://example.com/admin/dashboard')
    end
  end
  
  describe '#account_deleted' do
    let(:mail) { UserMailer.account_deleted(user) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Your Account Has Been Deleted')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['goodbye@example.com'])
    end
    
    it 'confirms account deletion' do
      expect(mail.body.encoded).to include('Your account has been successfully deleted.')
    end
    
    it 'includes feedback request' do
      expect(mail.body.encoded).to include('We would appreciate your feedback')
      expect(mail.body.encoded).to include('feedback@example.com')
    end
    
    it 'mentions data retention policy' do
      expect(mail.body.encoded).to include('Your personal data will be permanently removed')
    end
  end
  
  describe '#email_changed' do
    let(:old_email) { 'old@example.com' }
    let(:mail) { UserMailer.email_changed(user, old_email) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Email Address Changed')
      expect(mail.to).to eq([old_email])
      expect(mail.from).to eq(['notifications@example.com'])
    end
    
    it 'mentions the email change' do
      expect(mail.body.encoded).to include("Your email address has been changed from #{old_email} to #{user.email}")
    end
    
    it 'includes a security notice' do
      expect(mail.body.encoded).to include('If you did not make this change, please contact us immediately')
    end
  end
  
  describe '#password_changed' do
    let(:mail) { UserMailer.password_changed(user) }
    let(:ip) { '192.168.1.1' }
    let(:location) { 'New York, NY' }
    let(:device) { 'Firefox on Mac OS X' }
    
    before do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip)
      allow_any_instance_of(ActionDispatch::Request).to receive(:user_agent).and_return(device)
      allow(Geocoder).to receive(:search).with(ip).and_return([OpenStruct.new(city: 'New York', region: 'NY')])
    end
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Your Password Has Been Changed')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['security@example.com'])
    end
    
    it 'includes the change details' do
      expect(mail.body.encoded).to include(Time.current.strftime('%B %d, %Y at %I:%M %p %Z'))
      expect(mail.body.encoded).to include(ip)
      expect(mail.body.encoded).to include(device)
    end
    
    it 'includes a security notice' do
      expect(mail.body.encoded).to include('If you did not make this change, please secure your account')
    end
  end
  
  describe '#export_ready' do
    let(:export_type) { 'user_data' }
    let(:download_url) { 'http://example.com/download/export123' }
    let(:expires_in) { 24 }
    let(:mail) { UserMailer.export_ready(user, export_type, download_url, expires_in) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq("Your #{export_type.humanize} Export is Ready")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['exports@example.com'])
    end
    
    it 'includes the download link' do
      expect(mail.body.encoded).to have_link('Download Export', href: download_url)
    end
    
    it 'mentions the expiration time' do
      expect(mail.body.encoded).to include("This link will expire in #{expires_in} hours")
    end
  end
  
  describe '#weekly_summary' do
    let(:summary_data) do
      {
        new_messages: 5,
        recent_activity: ['New comment on your post', '3 new followers'],
        upcoming_events: ['Webinar on Friday'],
        stats: {
          profile_views: 42,
          post_views: 127
        }
      }
    end
    let(:mail) { UserMailer.weekly_summary(user, summary_data) }
    
    it 'renders the headers' do
      expect(mail.subject).to match(/^Your Weekly Summary - \w+ \d{1,2}/) # Matches "Your Weekly Summary - Month Day"
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['updates@example.com'])
    end
    
    it 'includes the summary data' do
      expect(mail.body.encoded).to include('5 new messages')
      expect(mail.body.encoded).to include('New comment on your post')
      expect(mail.body.encoded).to include('Webinar on Friday')
      expect(mail.body.encoded).to include('42 profile views')
      expect(mail.body.encoded).to include('127 post views')
    end
    
    it 'includes a call to action' do
      expect(mail.body.encoded).to have_link('View Your Dashboard', 
                                           href: 'http://example.com/dashboard')
    end
  end
end
