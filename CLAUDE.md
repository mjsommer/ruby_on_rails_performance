# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a freshly generated Rails application (`rails new`) with Webpacker for JavaScript bundling. No models, controllers, routes, or views beyond the default skeleton have been added yet — `config/routes.rb` is empty and `app/models`/`app/controllers` contain only the base classes. There is no README content beyond the default template.

## Stack

- Ruby 3.3.12, Rails 6.1.7.10
- PostgreSQL (`pg` gem) — databases are named `test_app_v6_{development,test,production}` in `config/database.yml`
- Puma as the app server
- Webpacker 5 for JS bundling, with Babel (see `babel.config.js`) and PostCSS (`postcss.config.js`)
- Turbolinks + `@rails/ujs` for the JS/HTML integration layer
- RSpec (`rspec-rails`) for unit/request specs, with Capybara + Selenium/`webdrivers` for system specs

## Commands

Setup:
```
bin/setup          # installs gems, prepares the db, etc.
bundle install
yarn install
```

Run the app (needs both the Rails server and Webpacker dev server in development):
```
bin/rails server
bin/webpack-dev-server
```

Database:
```
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Tests (RSpec):
```
bundle exec rspec                        # full suite
bundle exec rspec spec/models/foo_spec.rb
bundle exec rspec spec/models/foo_spec.rb:12   # single example at line 12
```

Console:
```
bin/rails console
```

## Architecture notes

- Standard Rails app layout (`app/models`, `app/controllers`, `app/views`, `app/jobs`, `app/mailers`, `app/channels`, `app/helpers`) — no non-standard directories or service-object conventions have been established yet.
- JavaScript lives in `app/javascript` and is compiled by Webpacker; entry packs are in `app/javascript/packs`, with Action Cable channel setup under `app/javascript/channels`.
- `config/webpacker.yml` and `config/webpack/` control the Webpacker build; `babel.config.js` and `postcss.config.js` sit at the repo root because Webpacker expects them there.
- As real domain code is added, prefer extending this default structure (e.g., new models under `app/models`, routes in `config/routes.rb`) rather than introducing new architectural patterns without discussion.
