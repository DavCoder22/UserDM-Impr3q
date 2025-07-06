# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Authentication', type: :feature, js: true do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:new_admin) { build(:user) }
  
  before do
    # Configure Capybara
    Capybara.javascript_driver = :selenium_chrome_headless
    Capybara.app_host = 'http://localhost:3000'
    Capybara.default_max_wait_time = 5
    
    # Stub any external services
    allow_any_instance_of(AdminMailer).to receive(:new_admin_notification).and_return(double(deliver_later: true))
  end
  
  describe 'Admin Dashboard Access' do
    context 'when not signed in' do
      it 'redirects to login page' do
        visit admin_dashboard_path
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end
    
    context 'when signed in as regular user' do
      before { sign_in regular_user }
      
      it 'denies access to admin dashboard' do
        visit admin_dashboard_path
        expect(page).to have_http_status(:forbidden)
        expect(page).to have_content('You are not authorized to access this page.')
      end
    end
    
    context 'when signed in as admin' do
      before { sign_in admin }
      
      it 'allows access to admin dashboard' do
        visit admin_dashboard_path
        expect(page).to have_current_path(admin_dashboard_path)
        expect(page).to have_content('Admin Dashboard')
      end
    end
    
    context 'when admin session times out' do
      before do
        sign_in admin
        travel 2.days # Past session timeout
      end
      
      it 'requires re-authentication' do
        visit admin_dashboard_path
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('Your session has expired. Please sign in again.')
      end
    end
  end
  
  describe 'User Management' do
    before { sign_in admin }
    
    it 'lists all users' do
      users = create_list(:user, 3)
      visit admin_users_path
      
      users.each do |user|
        expect(page).to have_content(user.email)
      end
    end
    
    it 'creates a new user' do
      visit new_admin_user_path
      
      fill_in 'Email', with: new_admin.email
      fill_in 'Name', with: new_admin.name
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      check 'Admin'
      
      expect {
        click_button 'Create User'
      }.to change(User, :count).by(1)
      
      expect(page).to have_content('User was successfully created.')
      expect(User.last).to be_admin
    end
    
    it 'edits a user' do
      user = create(:user)
      visit edit_admin_user_path(user)
      
      fill_in 'Name', with: 'Updated Name'
      click_button 'Update User'
      
      expect(page).to have_content('User was successfully updated.')
      expect(user.reload.name).to eq('Updated Name')
    end
    
    it 'deletes a user' do
      user = create(:user)
      visit admin_users_path
      
      expect {
        accept_confirm { click_link 'Delete', href: admin_user_path(user) }
        expect(page).to have_content('User was successfully deleted.')
      }.to change(User, :count).by(-1)
    end
    
    it 'locks/unlocks a user account' do
      user = create(:user)
      visit admin_user_path(user)
      
      # Lock the account
      click_link 'Lock Account'
      expect(page).to have_content('Account locked successfully.')
      expect(user.reload.access_locked?).to be_truthy
      
      # Unlock the account
      click_link 'Unlock Account'
      expect(page).to have_content('Account unlocked successfully.')
      expect(user.reload.access_locked?).to be_falsey
    end
    
    it 'impersonates a user' do
      user = create(:user)
      visit admin_user_path(user)
      
      click_link 'Impersonate'
      
      expect(page).to have_content("You are currently impersonating #{user.email}")
      expect(page).to have_link('Stop Impersonating')
      
      # Test admin actions are not available while impersonating
      expect(page).not_to have_link('Admin')
      
      # Stop impersonating
      click_link 'Stop Impersonating'
      expect(page).to have_content('Stopped impersonating user.')
      expect(page).to have_current_path(admin_user_path(user))
    end
  end
  
  describe 'Role Management' do
    before { sign_in admin }
    
    it 'assigns admin role to user' do
      user = create(:user)
      visit edit_admin_user_path(user)
      
      check 'Admin'
      click_button 'Update User'
      
      expect(page).to have_content('User was successfully updated.')
      expect(user.reload).to be_admin
    end
    
    it 'removes admin role from user' do
      admin_user = create(:user, :admin)
      visit edit_admin_user_path(admin_user)
      
      uncheck 'Admin'
      click_button 'Update User'
      
      expect(page).to have_content('User was successfully updated.')
      expect(admin_user.reload).not_to be_admin
    end
    
    it 'prevents removing last admin' do
      visit edit_admin_user_path(admin)
      
      uncheck 'Admin'
      click_button 'Update User'
      
      expect(page).to have_content('At least one admin must remain.')
      expect(admin.reload).to be_admin
    end
  end
  
  describe 'Security Features' do
    before { sign_in admin }
    
    it 'logs admin actions' do
      user = create(:user)
      
      expect {
        visit edit_admin_user_path(user)
        fill_in 'Name', with: 'Audited Name'
        click_button 'Update User'
      }.to change(AuditLog, :count).by(1)
      
      audit = AuditLog.last
      expect(audit.user).to eq(admin)
      expect(audit.action).to eq('update')
      expect(audit.auditable).to eq(user)
    end
    
    it 'requires re-authentication for sensitive actions' do
      visit edit_admin_security_settings_path
      
      # Should show re-authentication form
      expect(page).to have_content('Re-authentication Required')
      
      # Test invalid password
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Authenticate'
      
      expect(page).to have_content('Invalid password')
      
      # Test valid password
      fill_in 'Password', with: 'password123'
      click_button 'Authenticate'
      
      expect(page).to have_current_path(edit_admin_security_settings_path)
    end
    
    it 'shows login history' do
      # Generate some login history
      create_list(:login_activity, 3, user: admin)
      
      visit admin_login_history_path
      
      expect(page).to have_content('Login History')
      expect(page).to have_selector('table tbody tr', count: 3)
    end
    
    it 'exports user data' do
      create_list(:user, 3)
      
      visit admin_users_path
      click_link 'Export Users'
      
      expect(page.response_headers['Content-Type']).to eq('text/csv')
      expect(page.body.lines.count).to eq(5) # Header + 4 users (admin + 3)
    end
  end
  
  describe 'Two-Factor Authentication' do
    before { sign_in admin }
    
    it 'enforces 2FA for admin users' do
      visit edit_admin_user_path(admin)
      
      # Should see 2FA status
      expect(page).to have_content('Two-Factor Authentication: Enabled')
      
      # Test resetting 2FA
      click_link 'Reset 2FA'
      
      expect(page).to have_content('Two-Factor Authentication has been reset.')
      expect(admin.reload.otp_required_for_login).to be_falsey
    end
    
    it 'allows viewing 2FA recovery codes' do
      # Enable 2FA for the admin
      admin.otp_secret = User.generate_otp_secret
      admin.otp_required_for_login = true
      admin.save!
      
      visit admin_user_path(admin)
      click_link 'View Recovery Codes'
      
      expect(page).to have_content('Two-Factor Recovery Codes')
      expect(page).to have_selector('.recovery-code', count: 10)
    end
  end
  
  describe 'Bulk Actions' do
    before { sign_in admin }
    
    it 'locks multiple users' do
      users = create_list(:user, 3)
      visit admin_users_path
      
      users.each do |user|
        check "user_#{user.id}"
      end
      
      select 'Lock Selected', from: 'bulk_action'
      click_button 'Apply'
      
      expect(page).to have_content('3 users have been locked.')
      users.each do |user|
        expect(user.reload.access_locked?).to be_truthy
      end
    end
    
    it 'exports selected users' do
      users = create_list(:user, 2)
      visit admin_users_path
      
      check "user_#{users.first.id}"
      select 'Export Selected', from: 'bulk_action'
      
      click_button 'Apply'
      
      expect(page.response_headers['Content-Type']).to eq('text/csv')
      expect(page.body.lines.count).to eq(2) # Header + 1 user
    end
  end
  
  describe 'Admin Impersonation' do
    before { sign_in admin }
    
    it 'allows admin to impersonate a user' do
      user = create(:user)
      visit admin_user_path(user)
      
      click_link 'Impersonate User'
      
      # Should be on the user's dashboard
      expect(page).to have_content("Impersonating: #{user.email}")
      expect(page).to have_link('Stop Impersonating')
      
      # Test admin actions are not available
      expect(page).not_to have_link('Admin Dashboard')
      
      # Test stopping impersonation
      click_link 'Stop Impersonating'
      expect(page).to have_content('Stopped impersonating user.')
      expect(page).to have_current_path(admin_user_path(user))
    end
    
    it 'logs impersonation events' do
      user = create(:user)
      
      expect {
        visit admin_user_path(user)
        click_link 'Impersonate User'
      }.to change(Impersonation, :count).by(1)
      
      impersonation = Impersonation.last
      expect(impersonation.admin).to eq(admin)
      expect(impersonation.user).to eq(user)
      
      # Verify the impersonation log entry
      visit admin_impersonations_path
      expect(page).to have_content("#{admin.email} started impersonating #{user.email}")
    end
    
    it 'prevents impersonating another admin' do
      other_admin = create(:user, :admin)
      
      visit admin_user_path(other_admin)
      
      expect(page).not_to have_link('Impersonate User')
      
      # Try to force the impersonation
      post admin_impersonations_path, params: { user_id: other_admin.id }
      
      expect(response).to have_http_status(:forbidden)
      expect(flash[:alert]).to include('Cannot impersonate another administrator')
    end
  end
  
  describe 'Admin Notifications' do
    it 'sends email notification on new admin creation' do
      sign_in admin
      
      visit new_admin_user_path
      
      fill_in 'Email', with: 'newadmin@example.com'
      fill_in 'Name', with: 'New Admin'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      check 'Admin'
      
      expect {
        click_button 'Create User'
      }.to have_enqueued_job.on_queue('mailers')
      
      # Verify the email was sent
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.to).to include('newadmin@example.com')
      expect(last_email.subject).to include('Your New Admin Account')
    end
    
    it 'sends security alert on admin password change' do
      admin # Ensure admin is created before the test
      
      sign_in admin
      
      visit edit_admin_user_path(admin)
      
      fill_in 'Password', with: 'newpassword123'
      fill_in 'Password confirmation', with: 'newpassword123'
      fill_in 'Current password', with: 'password123'
      
      expect {
        click_button 'Update User'
      }.to have_enqueued_job.on_queue('mailers')
      
      # Verify the security alert was sent
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.to).to include(admin.email)
      expect(last_email.subject).to include('Security Alert')
    end
  end
  
  describe 'Admin Activity Logs' do
    before { sign_in admin }
    
    it 'tracks admin logins' do
      visit admin_activity_logs_path
      
      # Should see the current login
      expect(page).to have_content(admin.email)
      expect(page).to have_content('Signed in successfully')
    end
    
    it 'filters logs by date range' do
      # Create some older logs
      create(:activity_log, user: admin, action: 'user.create', created_at: 1.week.ago)
      
      visit admin_activity_logs_path
      
      # Set date range to last 24 hours
      fill_in 'start_date', with: 1.day.ago.strftime('%Y-%m-%d')
      fill_in 'end_date', with: Date.tomorrow.strftime('%Y-%m-%d')
      click_button 'Filter'
      
      # Should only see recent activity
      expect(page).to have_content('Signed in successfully')
      expect(page).not_to have_content('user.create')
    end
    
    it 'exports logs to CSV' do
      create_list(:activity_log, 3, user: admin)
      
      visit admin_activity_logs_path
      click_link 'Export Logs'
      
      expect(page.response_headers['Content-Type']).to eq('text/csv')
      expect(page.body.lines.count).to eq(5) # Header + 4 logs (1 from sign_in + 3 created)
    end
  end
  
  describe 'Admin API Access' do
    let(:api_key) { 'test_api_key_123' }
    
    before do
      allow(SecureRandom).to receive(:hex).and_return(api_key)
      sign_in admin
    end
    
    it 'generates API keys' do
      visit admin_api_settings_path
      
      fill_in 'API Key Name', with: 'Test Integration'
      click_button 'Generate API Key'
      
      expect(page).to have_content('API Key generated successfully')
      expect(page).to have_content(api_key)
      
      # Test that the key is stored securely (not shown in plain text after page reload)
      visit admin_api_settings_path
      expect(page).not_to have_content(api_key)
    end
    
    it 'revokes API keys' do
      # Create an API key first
      admin.api_keys.create!(name: 'Test Key', key: 'test_key_123')
      
      visit admin_api_settings_path
      
      expect {
        accept_confirm { click_link 'Revoke' }
        expect(page).to have_content('API key has been revoked')
      }.to change(admin.api_keys.active, :count).by(-1)
    end
    
    it 'tracks API key usage' do
      api_key = admin.api_keys.create!(name: 'Test Key', key: 'test_key_123')
      create(:api_request, api_key: api_key, path: '/api/v1/users', method: 'GET')
      
      visit admin_api_settings_path
      
      click_link 'View Usage'
      
      expect(page).to have_content('API Key Usage: Test Key')
      expect(page).to have_content('/api/v1/users')
      expect(page).to have_content('GET')
    end
  end
  
  describe 'Admin Security Settings' do
    before { sign_in admin }
    
    it 'updates password requirements' do
      visit admin_security_settings_path
      
      fill_in 'Minimum password length', with: '12'
      check 'Require special characters'
      check 'Require numbers'
      check 'Require uppercase letters'
      
      click_button 'Update Security Settings'
      
      expect(page).to have_content('Security settings updated successfully')
      
      # Verify the settings were applied
      visit admin_security_settings_path
      expect(find_field('Minimum password length').value).to eq('12')
      expect(find_field('Require special characters')).to be_checked
      expect(find_field('Require numbers')).to be_checked
      expect(find_field('Require uppercase letters')).to be_checked
    end
    
    it 'configures session timeout' do
      visit admin_security_settings_path
      
      select '1 hour', from: 'Session timeout'
      check 'Enable re-authentication for sensitive actions'
      
      click_button 'Update Security Settings'
      
      expect(page).to have_content('Security settings updated successfully')
      
      # Test the session timeout
      visit admin_security_settings_path
      travel 61.minutes
      
      # Should be logged out due to session timeout
      visit admin_dashboard_path
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Your session has expired. Please sign in again.')
    end
    
    it 'configures IP whitelist' do
      visit admin_security_settings_path
      
      fill_in 'IP Whitelist', with: '192.168.1.1, 10.0.0.0/8'
      check 'Enable IP whitelist for admin access'
      
      click_button 'Update Security Settings'
      
      expect(page).to have_content('Security settings updated successfully')
      
      # Test with an IP not in the whitelist
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('203.0.113.1')
      
      visit admin_dashboard_path
      
      expect(page).to have_http_status(:forbidden)
      expect(page).to have_content('Access denied from your IP address')
    end
  end
  
  private
  
  def sign_in(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password123'
    click_button 'Log in'
  end
end
