# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'
require 'bcrypt'

RSpec.describe 'Authentication Performance', type: :performance do
  include ActiveSupport::Testing::TimeHelpers
  
  # Test data
  let!(:user) { create(:user, password: 'password123') }
  let(:password) { 'password123' }
  let(:wrong_password) { 'wrong_password' }
  let(:concurrent_users) { 50 }
  let(:iterations) { 100 }
  
  before do
    # Clear cache and reset GC before each test
    Rails.cache.clear
    GC.start
  end
  
  describe 'Password Hashing' do
    it 'hashes passwords with acceptable performance' do
      # Test with different password lengths
      passwords = [
        'a' * 50,      # Very long password
        'P@ssw0rd!',   # Complex password
        '12345678',    # Simple password
        SecureRandom.hex(32)  # Random 64-char password
      ]
      
      passwords.each do |pwd|
        time = Benchmark.realtime do
          BCrypt::Password.create(pwd)
        end
        
        # Expect hashing to take between 0.1 and 500ms (adjust based on your requirements)
        expect(time).to be_between(0.1, 0.5), 
          "Password hashing took #{time * 1000}ms for password of length #{pwd.length}"
      end
    end
    
    it 'verifies passwords with acceptable performance' do
      hashed_password = BCrypt::Password.create(password)
      
      # Test correct password
      correct_time = Benchmark.realtime do
        BCrypt::Password.new(hashed_password) == password
      end
      
      # Test incorrect password
      incorrect_time = Benchmark.realtime do
        BCrypt::Password.new(hashed_password) == wrong_password
      end
      
      # Verification should be fast (sub 10ms)
      expect(correct_time).to be < 0.01
      expect(incorrect_time).to be < 0.01
      
      # Timing attack protection: verification time should be similar for correct/incorrect passwords
      time_difference = (correct_time - incorrect_time).abs
      expect(time_difference).to be < 0.001, 
        "Timing difference between correct and incorrect passwords is too large: #{time_difference * 1000}ms"
    end
  end
  
  describe 'Session Management' do
    it 'handles concurrent login attempts' do
      # Simulate concurrent login attempts
      threads = []
      successful_logins = 0
      
      concurrent_users.times do |i|
        threads << Thread.new do
          begin
            post user_session_path, params: { 
              user: { 
                email: user.email, 
                password: (i.even? ? password : wrong_password)
              } 
            }
            successful_logins += 1 if response.successful?
          rescue => e
            Rails.logger.error "Login attempt failed: #{e.message}"
          end
        end
      end
      
      # Wait for all threads to complete
      threads.each(&:join)
      
      # Verify the number of successful logins (should be exactly 1 with the correct password)
      expect(successful_logins).to eq(1)
      
      # Verify the user's failed_attempts counter
      expect(user.reload.failed_attempts).to eq(concurrent_users - 1)
    end
    
    it 'maintains performance under load' do
      # Warm up the server
      get root_path
      
      # Measure response times
      times = []
      
      iterations.times do |i|
        time = Benchmark.realtime do
          post user_session_path, params: { 
            user: { 
              email: user.email, 
              password: (i % 10 == 0 ? password : wrong_password)
            } 
          }
        end
        times << time
        
        # Print progress
        print "\rCompleted #{i + 1}/#{iterations} requests"
        STDOUT.flush
      end
      
      # Calculate statistics
      avg_time = times.sum / times.size
      max_time = times.max
      p90 = times.sort[(times.length * 0.9).to_i]
      
      puts "\nAverage response time: #{avg_time * 1000}ms"
      puts "Max response time: #{max_time * 1000}ms"
      puts "90th percentile: #{p90 * 1000}ms"
      
      # Define acceptable thresholds (adjust based on your requirements)
      expect(avg_time).to be < 0.5  # 500ms average
      expect(p90).to be < 1.0       # 90% under 1s
      expect(max_time).to be < 2.0   # Nothing over 2s
    end
  end
  
  describe 'Rate Limiting' do
    it 'throttles excessive login attempts' do
      # First few attempts should work
      5.times do
        post user_session_path, params: { 
          user: { email: user.email, password: wrong_password } 
        }
        expect(response).to have_http_status(:unauthorized)
      end
      
      # Subsequent attempts should be rate limited
      start_time = Time.now
      
      10.times do |i|
        post user_session_path, params: { 
          user: { email: user.email, password: wrong_password } 
        }
        
        if i < 5
          expect(response).to have_http_status(:too_many_requests)
        end
      end
      
      # Verify the account is locked after too many attempts
      expect(user.reload.access_locked?).to be_truthy
      
      # Verify the lockout duration is reasonable
      lockout_duration = user.locked_at + Devise.unlock_in - Time.now
      expect(lockout_duration).to be_between(5.minutes, 1.hour)
    end
  end
  
  describe 'Password Reset' do
    it 'handles password reset requests efficiently' do
      # Test password reset request
      time = Benchmark.realtime do
        post user_password_path, params: { 
          user: { email: user.email } 
        }
      end
      
      expect(time).to be < 0.5  # Reset request should be fast
      
      # Get the reset token from the email
      reset_email = ActionMailer::Base.deliveries.last
      reset_token = reset_email.body.match(/reset_password_token=([^\"]+)/)[1]
      
      # Test password reset
      time = Benchmark.realtime do
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }
      end
      
      expect(time).to be < 1.0  # Reset should be reasonably fast
      
      # Verify the password was changed
      expect(user.reload.valid_password?('newpassword123')).to be_truthy
    end
  end
  
  describe 'Session Storage' do
    it 'efficiently stores and retrieves session data' do
      # Sign in the user
      post user_session_path, params: { 
        user: { email: user.email, password: password } 
      }
      
      # Store the session cookie
      session_cookie = response.cookies['_session_id']
      
      # Make authenticated requests
      times = []
      
      10.times do
        time = Benchmark.realtime do
          get user_path(user), headers: { 'Cookie' => "_session_id=#{session_cookie}" }
          expect(response).to be_successful
        end
        times << time
      end
      
      # Calculate average time for authenticated requests
      avg_time = times.sum / times.size
      
      puts "\nAverage authenticated request time: #{avg_time * 1000}ms"
      
      # Authenticated requests should be reasonably fast
      expect(avg_time).to be < 0.1  # 100ms
    end
  end
  
  describe 'Database Queries' do
    it 'minimizes database queries during authentication' do
      # Sign in and count queries
      queries = []
      
      # Subscribe to SQL queries
      callback = ->(*args) { queries << args.last[:sql] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        post user_session_path, params: { 
          user: { email: user.email, password: password } 
        }
      end
      
      # Print queries for debugging
      puts "\nDatabase queries during login:"
      queries.each { |q| puts "  #{q}" }
      
      # We should have a small, fixed number of queries
      expect(queries.size).to be <= 5, "Expected <= 5 queries, got #{queries.size}"
    end
  end
  
  describe 'Memory Usage' do
    it 'does not leak memory during authentication' do
      # Get baseline memory usage
      baseline_memory = memory_usage
      
      # Perform authentication multiple times
      100.times do |i|
        post user_session_path, params: { 
          user: { email: user.email, password: password } 
        }
        
        # Sign out
        delete destroy_user_session_path
        
        # Print memory usage every 10 iterations
        if (i + 1) % 10 == 0
          current_memory = memory_usage
          puts "Iteration #{i + 1}: Memory usage: #{current_memory}MB (delta: #{current_memory - baseline_memory}MB)"
        end
      end
      
      # Check for memory leaks (allow some increase due to Ruby's GC behavior)
      current_memory = memory_usage
      memory_increase = current_memory - baseline_memory
      
      puts "\nMemory usage - Start: #{baseline_memory}MB, End: #{current_memory}MB, Increase: #{memory_increase}MB"
      
      # Allow for small increases due to Ruby's memory allocation patterns
      expect(memory_increase).to be < 10, "Memory leak detected: #{memory_increase}MB increase"
    end
    
    private
    
    def memory_usage
      # Get memory usage in MB
      `ps -o rss= -p #{Process.pid}`.to_f / 1024
    end
  end
  
  describe 'Concurrent User Sessions' do
    it 'handles multiple concurrent sessions per user' do
      # Create multiple sessions for the same user
      sessions = []
      
      5.times do
        post user_session_path, params: { 
          user: { email: user.email, password: password } 
        }
        
        expect(response).to be_successful
        sessions << response.cookies['_session_id']
      end
      
      # Verify all sessions are active
      sessions.each do |session_id|
        get user_path(user), headers: { 'Cookie' => "_session_id=#{session_id}" }
        expect(response).to be_successful
      end
      
      # Clean up sessions
      delete destroy_user_session_path
    end
  end
  
  describe 'Password Complexity' do
    it 'validates password complexity efficiently' do
      # Test with various password complexities
      passwords = [
        'short',
        'longpasswordwithoutcomplexity',
        'Simple123',
        'Complex!@#123',
        SecureRandom.base64(32)
      ]
      
      times = []
      
      passwords.each do |pwd|
        time = Benchmark.realtime do
          user.password = pwd
          user.valid?
        end
        
        times << time
        puts "Password validation for '#{pwd[0..10]}...' took #{time * 1000}ms"
      end
      
      # Password validation should be fast
      expect(times.max).to be < 0.01, "Password validation is too slow: #{times.max * 1000}ms"
    end
  end
  
  describe 'Session Expiration' do
    it 'efficiently handles session expiration' do
      # Sign in
      post user_session_path, params: { 
        user: { email: user.email, password: password } 
      }
      
      session_cookie = response.cookies['_session_id']
      
      # Fast-forward time to just before session expires
      travel_to (Devise.timeout_in - 1.minute).from_now do
        get user_path(user), headers: { 'Cookie' => "_session_id=#{session_cookie}" }
        expect(response).to be_successful
      end
      
      # Fast-forward past session expiration
      travel_to (Devise.timeout_in + 1.minute).from_now do
        get user_path(user), headers: { 'Cookie' => "_session_id=#{session_cookie}" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
