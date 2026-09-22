# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Rails application (`rails new`) with Webpacker for JavaScript bundling. The only domain feature so far is a `Bicycle` CRUD resource (brand, model, usage_type, color, wheels) — see Architecture notes below. There is no README content beyond the default template.

## Stack

- Ruby 3.3.12, Rails 6.1.7.10
- PostgreSQL (`pg` gem) — databases are named `test_app_v6_{development,test,production}` in `config/database.yml`
- Puma as the app server
- Webpacker 5 for JS bundling, with Babel (see `babel.config.js`) and PostCSS (`postcss.config.js`)
- Turbolinks + `@rails/ujs` for the JS/HTML integration layer
- RSpec (`rspec-rails`) for unit/request specs, with Capybara + Selenium/`webdrivers` for system specs, and `factory_bot_rails` for test data (factories in `spec/factories/`)

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
bin/rails db:seed          # loads sample Bicycle records from db/seeds.rb
```

Tests (RSpec):
```
bundle exec rspec                              # full suite
bundle exec rspec spec/models/bicycle_spec.rb
bundle exec rspec spec/models/bicycle_spec.rb:12   # single example at line 12
bundle exec rspec spec/requests/bicycles_spec.rb
bundle exec rspec spec/system/bicycles_spec.rb
```

Console:
```
bin/rails console
```

## Architecture notes

- Standard Rails app layout (`app/models`, `app/controllers`, `app/views`, `app/jobs`, `app/mailers`, `app/channels`, `app/helpers`) — no non-standard directories or service-object conventions have been established.
- JavaScript lives in `app/javascript` and is compiled by Webpacker; entry packs are in `app/javascript/packs`, with Action Cable channel setup under `app/javascript/channels`.
- `config/webpacker.yml` and `config/webpack/` control the Webpacker build; `babel.config.js` and `postcss.config.js` sit at the repo root because Webpacker expects them there.
- `Bicycle` (`app/models/bicycle.rb`) is the only domain model: `usage_type` is restricted to `road`/`off-road` at both the model (`Bicycle::USAGE_TYPES`, inclusion validation) and DB level (Postgres check constraint `usage_type_check`), `wheels` defaults to 2 in the schema. Scopes `Bicycle.road` / `Bicycle.off_road` filter by usage type. `BicyclesController` is a plain RESTful resource; `root` routes to `bicycles#index`.
- **Webpacker/Babel gotcha**: `bin/webpack` and `bin/webpack-dev-server` require `"logger"` at the top before `bundler/setup` — without it they crash under Ruby 3.3.5+ (stdlib no longer auto-loads `logger` before Bundler boots, which older Rails/Webpacker assume). `babel.config.js` also references `@babel/plugin-proposal-private-methods` and `@babel/plugin-proposal-private-property-in-object`, which ship in `node_modules` only as non-functional placeholder packages unless explicitly added to `package.json` (already done) — if JS asset compilation ever throws `PLACEHOLDER PACKAGE` or `Cannot find package '@babel/plugin-proposal-...'`, this is why.
- Prefer extending this structure (new models under `app/models`, routes in `config/routes.rb`) rather than introducing new architectural patterns without discussion.
