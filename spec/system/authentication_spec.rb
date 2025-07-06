# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :system do
  let!(:user) { create(:user, password: 'password123') }
  
  before do
    driven_by(:selenium_chrome_headless)
    Capybara.default_max_wait_time = 5
  end
  
  describe 'User sign in' do
    it 'allows a user to sign in with valid credentials' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'
      
      expect(page).to have_content('Signed in successfully')
      expect(page).to have_current_path(root_path)
    end
    
    it 'shows an error with invalid credentials' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Sign in'
      
      expect(page).to have_content('Invalid Email or password')
      expect(page).to have_current_path(new_user_session_path)
    end
  end
  
  describe 'User sign up' do
    let(:new_user) { build(:user) }
    
    it 'allows a new user to sign up' do
      visit new_user_registration_path
      
      fill_in 'Name', with: new_user.name
      fill_in 'Email', with: new_user.email
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      
      expect {
        click_button 'Sign up'
      }.to change(User, :count).by(1)
      
      expect(page).to have_content('Welcome! You have signed up successfully.')
      expect(page).to have_current_path(root_path)
    end
    
    it 'shows validation errors with invalid data' do
      visit new_user_registration_path
      click_button 'Sign up'
      
      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Password can't be blank")
    end
  end
  
  describe 'Password reset' do
    it 'allows a user to request a password reset' do
      visit new_user_password_path
      
      fill_in 'Email', with: user.email
      
      expect {
        click_button 'Send me reset password instructions'
      }.to have_enqueued_job.on_queue('mailers')
      
      expect(page).to have_content('You will receive an email with instructions')
      
      # Test the reset password link from email
      reset_token = user.send_reset_password_instructions
      visit edit_user_password_path(reset_password_token: reset_token)
      
      fill_in 'New password', with: 'newpassword123'
      fill_in 'Confirm new password', with: 'newpassword123'
      click_button 'Change my password'
      
      expect(page).to have_content('Your password has been changed successfully')
    end
  end
  
  describe 'Email confirmation' do
    let(:unconfirmed_user) { create(:user, :unconfirmed) }
    
    it 'allows a user to confirm their email' do
      visit new_user_confirmation_path
      
      fill_in 'Email', with: unconfirmed_user.email
      
      expect {
        click_button 'Resend confirmation instructions'
      }.to have_enqueued_job.on_queue('mailers')
      
      # Test the confirmation link from email
      confirmation_token = unconfirmed_user.confirmation_token
      visit user_confirmation_path(confirmation_token: confirmation_token)
      
      expect(page).to have_content('Your email address has been successfully confirmed')
    end
  end
  
  describe 'User sign out' do
    before do
      login_as(user, scope: :user)
      visit root_path
    end
    
    it 'allows a user to sign out' do
      click_link 'Sign out'
      
      expect(page).to have_content('Signed out successfully')
      expect(page).to have_current_path(root_path)
    end
  end
  
  describe 'Protected pages' do
    it 'redirects to sign in when accessing protected pages' do
      visit dashboard_path
      
      expect(page).to have_content('You need to sign in or sign up before continuing.')
      expect(page).to have_current_path(new_user_session_path)
    end
    
    it 'allows access with valid credentials' do
      login_as(user, scope: :user)
      visit dashboard_path
      
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('Dashboard')
    end
  end
  
  describe 'Admin area' do
    let(:admin) { create(:user, :admin) }
    
    it 'restricts access to non-admin users' do
      login_as(user, scope: :user)
      visit admin_root_path
      
      expect(page).to have_content('You are not authorized to access this page.')
      expect(page).to have_current_path(root_path)
    end
    
    it 'allows access to admin users' do
      login_as(admin, scope: :user)
      visit admin_root_path
      
      expect(page).to have_current_path(admin_root_path)
      expect(page).to have_content('Admin Dashboard')
    end
  end
  
  describe 'Remember me' do
    it 'keeps the user signed in after browser close when "Remember me" is checked' do
      visit new_user_session_path
      
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      check 'Remember me'
      click_button 'Sign in'
      
      # Simulate browser close and reopen
      Capybara.reset_session!
      
      visit root_path
      expect(page).to have_content('Dashboard')
    end
  end
  
  describe 'Account lockout' do
    before do
      # Set a low maximum attempts for testing
      Devise.maximum_attempts = 3
    end
    
    it 'locks the account after too many failed attempts' do
      visit new_user_session_path
      
      Devise.maximum_attempts.times do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'wrongpassword'
        click_button 'Sign in'
      end
      
      expect(page).to have_content('Your account is locked.')
      
      # Try with correct password after lockout
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'
      
      expect(page).to have_content('Your account is locked.')
    end
  end
  
  describe 'Session timeout' do
    before do
      # Set a short timeout for testing
      Devise.timeout_in = 5.seconds
      login_as(user, scope: :user)
    end
    
    it 'logs out the user after inactivity' do
      visit dashboard_path
      expect(page).to have_current_path(dashboard_path)
      
      # Wait for timeout
      sleep 6
      
      visit dashboard_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
