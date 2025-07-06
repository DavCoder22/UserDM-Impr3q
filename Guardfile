# Guard configuration for automatic test running
guard 'rspec', cmd: 'bundle exec rspec' do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  # Watch Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Watch test files
  watch(%r{^spec/(.*)_spec\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  
  # Watch app files
  watch(%r{^app/(.+\.rb)$}) { |m| "spec/#{m[1]}_spec.rb" }
  
  # Watch lib files
  watch(%r{^lib/(.+\.rb)$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  
  # Watch spec_helper and rails_helper
  watch('spec/spec_helper.rb') { 'spec' }
  
  # Watch config/routes.rb
  watch('config/routes.rb') { 'spec/routing' }
  
  # Watch views
  watch(%r{^app/views/(.+)\.(erb|haml|slim)$}) do |m|
    "spec/views/#{m[1]}.erb_spec.rb"
  end
  
  # Watch JavaScript files
  watch(%r{^app/assets/javascripts/(.+)\.js(?:\..+)?$}) do |m|
    "spec/javascripts/#{m[1]}_spec.js"
  end
  
  # Watch stylesheets
  watch(%r{^app/assets/stylesheets/(.+)\.(?:css|scss|sass)$}) do |m|
    "spec/features/#{m[1]}_spec.rb"
  end
end

# Notifications
notification :terminal_title
notification :tmux, title: 'RSpec', display_title: true

# Guard configuration for RuboCop
guard 'rubocop', all_on_start: true, cli: '--auto-correct' do
  watch(%r{.+\.[rR][bB]$})
  watch(%r{(?:\.(?:rb|rake|gemspec|ru)|Gemfile|Rakefile)$}) { |m| File.dirname(m[0]) }
  watch('Gemfile.lock') { 'spec' }
end
