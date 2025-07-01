source 'https://rubygems.org'

# Especificar versión de Ruby
ruby '3.2.8'

# Dependencias principales
gem 'rake', '~> 13.1.0'

# Dependencias de prueba
group :test do
  gem 'rspec', '~> 3.12.0'
  gem 'rspec-json_expectations', '~> 2.2.0'
  gem 'httparty', '~> 0.21.0'
  gem 'faraday', '~> 2.8.0'
  gem 'webmock', '~> 3.19.0'
  gem 'rack-test', '~> 2.1.0'
  gem 'faker', '~> 3.2.0'
  gem 'factory_bot', '~> 6.4.0'
  gem 'database_cleaner-active_record', '~> 2.1.0'
end

# Dependencias de desarrollo
group :development, :test do
  gem 'pry', '~> 0.14.0'
  gem 'pry-byebug', '~> 3.10.0'
  # Temporarily using an older version of rubocop to avoid prism dependency
  gem 'rubocop', '~> 0.93.1', require: false
  gem 'rubocop-rspec', '~> 1.44.1', require: false
  gem 'simplecov', '~> 0.22.0', require: false
end
