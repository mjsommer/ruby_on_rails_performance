source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.1.3'
# Pin below json 3.0, which changed JSON.parse's second argument to
# keyword-only and breaks ActiveSupport::JSON.decode's positional call
# (activesupport declares no upper bound on json itself).
gem 'json', '~> 2.21'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '~> 8.0'
# Use the Sprockets asset pipeline (app/assets/stylesheets is plain CSS -- no
# Sass anywhere in the app, so sass-rails/sassc-rails/sassc are dropped; only
# sprockets-rails is actually needed to serve it)
gem 'sprockets-rails'
# Use JS with ESM import maps. Read more: https://github.com/rails/importmap-rails
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator. Read more: https://turbo.hotwired.dev
gem 'turbo-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :windows]
  # RSpec for unit/request/system specs
  gem 'rspec-rails', '~> 8.0'
  # Test data factories
  gem 'factory_bot_rails', '~> 6.4'
  # Code coverage reporting for the RSpec suite
  gem 'simplecov', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 5.0'
  gem 'listen', '~> 3.3'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  # Selenium Manager (built into selenium-webdriver) resolves browser drivers
  # automatically; the old `webdrivers` gem is archived and no longer needed.
  gem 'selenium-webdriver', '>= 4.11'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]
