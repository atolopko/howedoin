source 'https://rubygems.org'

gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'therubyracer', :require => 'v8'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

gem 'chronic', '~> 0.9.1'
# TODO: use money-rails
gem "money", "~> 5.1.1"

# Deploy with Capistrano
# gem 'capistrano'

gem 'trollop'

group :development do
  # for Guard automated testing (4 gems)
  gem "guard-rspec", "~> 2.5.2"
  gem "growl"
  gem "rb-fsevent", "~> 0.9.3"
  gem "pry-full"
  gem "pry-rails"
end

group :test, :development do
  gem "rspec-rails", "~> 2.0"
  # To use debugger
  gem 'debugger'
  gem 'timecop'
end

group :test do
  gem "factory_girl_rails", "~> 4.0"
end