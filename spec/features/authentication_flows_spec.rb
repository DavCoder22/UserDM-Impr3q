# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Authentication Flows', type: :feature, js: true do
  let(:user) { create(:user, password: 'password123') }
  
  before do
    # Configure Capybara to use Selenium with Chrome in headless mode
    Capybara.javascript_driver = :selenium_chrome_headless
    
    # Set the default host for testing
    Capybara.app_host = 'http://localhost:3000'
    
    # Set the default max wait time for asynchronous processes
    Capybara.default_max_wait_time = 5
  end
  
  describe 'User Registration' do
    let(:new_user) { build(:user) }
    
    before { visit new_user_registration_path }
    
    context 'with valid information' do
      it 'creates a new user account' do
        fill_in 'Email', with: new_user.email
        fill_in 'Password', with: 'password123', match: :prefer_exact
        fill_in 'Password confirmation', with: 'password123'
        
        expect {
          click_button 'Sign up'
          # Wait for the AJAX request to complete
          expect(page).to have_content('Welcome! You have signed up successfully.')
        }.to change(User, :count).by(1)
        
        # Verify the user is signed in
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('Sign Out')
      end
    end
    
    context 'with invalid information' do
      it 'shows error messages' do
        click_button 'Sign up'
        
        expect(page).to have_content("Email can't be blank")
        expect(page).to have_content("Password can't be blank")
      end
    end
    
    context 'with existing email' do
      it 'shows email taken error' do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password123'
        fill_in 'Password confirmation', with: 'password123'
        click_button 'Sign up'
        
        expect(page).to have_content('Email has already been taken')
      end
    end
  end
  
  describe 'User Login' do
    before { visit new_user_session_path }
    
    context 'with valid credentials' do
      it 'logs in the user' do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password123'
        click_button 'Log in'
        
        expect(page).to have_content('Signed in successfully.')
        expect(page).to have_current_path(root_path)
      end
    end
    
    context 'with invalid credentials' do
      it 'shows error message' do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'wrongpassword'
        click_button 'Log in'
        
        expect(page).to have_content('Invalid Email or password')
      end
    end
    
    context 'with remember me checked' do
      it 'remembers the user' do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password123'
        check 'Remember me'
        click_button 'Log in'
        
        # Simulate browser close and reopen
        expire_cookies
        visit root_path
        
        expect(page).to have_content(user.email)
      end
    end
  end
  
  describe 'Password Reset' do
    before { visit new_user_password_path }
    
    it 'sends reset instructions' do
      fill_in 'Email', with: user.email
      
      expect {
        click_button 'Send me reset password instructions'
        expect(page).to have_content('You will receive an email with instructions')
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    
    it 'resets the password' do
      # Request password reset
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'
      
      # Extract reset token from email
      reset_email = ActionMailer::Base.deliveries.last
      reset_token = reset_email.body.match(/reset_password_token=([^\"]+)/)[1]
      
      # Visit reset password page
      visit edit_user_password_path(reset_password_token: reset_token)
      
      # Set new password
      fill_in 'New password', with: 'newpassword123'
      fill_in 'Confirm new password', with: 'newpassword123'
      click_button 'Change my password'
      
      expect(page).to have_content('Your password has been changed successfully.')
      
      # Verify login with new password
      click_link 'Sign Out'
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'newpassword123'
      click_button 'Log in'
      
      expect(page).to have_content('Signed in successfully.')
    end
  end
  
  describe 'Account Lockout' do
    before { visit new_user_session_path }
    
    it 'locks account after multiple failed attempts' do
      # Attempt to log in multiple times with wrong password
      6.times do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'wrongpassword'
        click_button 'Log in'
      end
      
      expect(page).to have_content('Your account is locked.')
      
      # Verify cannot log in even with correct password
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      
      expect(page).to have_content('Your account is locked.')
    end
  end
  
  describe 'Email Confirmation' do
    let(:unconfirmed_user) { create(:user, :unconfirmed) }
    
    it 'requires email confirmation' do
      # Try to log in before confirming
      visit new_user_session_path
      fill_in 'Email', with: unconfirmed_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      
      expect(page).to have_content('You have to confirm your email address')
      
      # Confirm the email
      confirmation_email = ActionMailer::Base.deliveries.find { |e| e.to.include?(unconfirmed_user.email) }
      confirmation_link = confirmation_email.body.match(/(http[^\s]+confirmation[^\s]+)/)[1]
      visit confirmation_link.gsub('http://example.com', 'http://localhost:3000')
      
      expect(page).to have_content('Your email address has been successfully confirmed.')
      
      # Now should be able to log in
      fill_in 'Email', with: unconfirmed_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      
      expect(page).to have_content('Signed in successfully.')
    end
  end
  
  describe 'Session Management' do
    before do
      login_as(user, scope: :user)
      visit root_path
    end
    
    it 'allows user to sign out' do
      click_link 'Sign Out'
      expect(page).to have_content('Signed out successfully.')
      expect(page).to have_current_path(root_path)
    end
    
    it 'expires session after timeout' do
      # Simulate session timeout
      travel 31.minutes do
        visit root_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end
  
  describe 'OAuth Authentication' do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '12345',
        info: {
          email: 'github@example.com',
          name: 'GitHub User'
        }
      })
    end
    
    it 'allows sign in with GitHub' do
      visit new_user_session_path
      click_link 'Sign in with GitHub'
      
      expect(page).to have_content('Successfully authenticated from GitHub account.')
      expect(page).to have_current_path(root_path)
      expect(User.last.email).to eq('github@example.com')
    end
    
    it 'links OAuth account to existing user' do
      # Create user with same email as OAuth
      user = create(:user, email: 'github@example.com')
      
      visit new_user_session_path
      click_link 'Sign in with GitHub'
      
      expect(page).to have_content('Successfully authenticated from GitHub account.')
      expect(User.count).to eq(1) # Should not create new user
    end
  end
  
  describe 'Admin Authentication' do
    let(:admin) { create(:user, :admin) }
    
    it 'allows admin to access admin dashboard' do
      login_as(admin, scope: :user)
      visit admin_dashboard_path
      
      expect(page).to have_content('Admin Dashboard')
    end
    
    it 'prevents regular users from accessing admin dashboard' do
      login_as(user, scope: :user)
      visit admin_dashboard_path
      
      expect(page).to have_content('You are not authorized to access this page.')
      expect(page).to have_current_path(root_path)
    end
  end
  
  describe 'Email Notifications' do
    it 'sends welcome email after registration' do
      visit new_user_registration_path
      
      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123', match: :prefer_exact
      fill_in 'Password confirmation', with: 'password123'
      
      expect {
        click_button 'Sign up'
      }.to change { ActionMailer::Base.deliveries.count }.by(2) # Confirmation + welcome
      
      welcome_email = ActionMailer::Base.deliveries.last
      expect(welcome_email.to).to include('newuser@example.com')
      expect(welcome_email.subject).to include('Welcome')
    end
  end
  
  private
  
  def expire_cookies
    # Clear cookies to simulate browser close
    Capybara.current_session.driver.browser.manage.delete_all_cookies
  end
end
