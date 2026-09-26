# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Rails application (`rails new`) using import maps (`importmap-rails`) for JavaScript — no Node/Yarn/build step. The only domain feature so far is a `Bicycle` CRUD resource (brand, model, usage_type, color, wheels) — see Architecture notes below. There is no README content beyond the default template.

## Stack

- Ruby 3.3.12, Rails 7.1.6
- PostgreSQL (`pg` gem) — databases are named `test_app_v6_{development,test,production}` in `config/database.yml`
- Puma 6 as the app server (Rails 7.1 pulls in Rack 3, which requires Puma >= 6)
- `importmap-rails` for JS — no bundler, no Node/Yarn. Entry point is `app/javascript/application.js`; pins live in `config/importmap.rb`; CDN-vendored packages sit in `vendor/javascript/`
- Turbo (`turbo-rails`) + `@rails/ujs` for the JS/HTML integration layer (Turbo Drive handles navigation/forms; UJS handles `data-method`/`data-confirm` links like the Delete button)
- CSS goes through Sprockets/`sass-rails` (`app/assets/stylesheets/`) — this was never routed through the JS bundler, before or after the import-map migration
- RSpec (`rspec-rails`) for unit/request specs, with Capybara + `selenium-webdriver` for system specs, and `factory_bot_rails` for test data (factories in `spec/factories/`). No `webdrivers` gem — `selenium-webdriver` >= 4.11 ships Selenium Manager, which auto-provisions the matching browser driver
- The existing system spec (`spec/system/bicycles_spec.rb`) explicitly uses `driven_by(:rack_test)`, so it doesn't execute JS or exercise Selenium. A real Selenium/Chrome system spec has never been added to the suite — only ad hoc manual verification during the Rails 7.1 upgrade confirmed Selenium Manager + headless Chrome actually work end to end against this app

## Commands

Setup:
```
bin/setup          # installs gems, prepares the db, etc. (no yarn install needed)
bundle install
```

Run the app:
```
bin/rails server    # import maps have no separate dev server/build step
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
- JavaScript lives in `app/javascript`; `application.js` is the sole entry point (imports `@rails/ujs` and `@hotwired/turbo-rails`). `app/javascript/channels/consumer.js` is dormant Action Cable scaffolding — no channels are actually defined, and nothing imports it yet.
- `config/importmap.rb` pins JS packages; run `bin/importmap pin <package>` to add one. Pins resolve either to a CDN-vendored file under `vendor/javascript/` (e.g. `@rails/ujs`, `@rails/actioncable`) or, for `@hotwired/turbo-rails`, to the gem's own bundled asset.
- `Bicycle` (`app/models/bicycle.rb`) is the only domain model: `usage_type` is restricted to `road`/`off-road` at both the model (`Bicycle::USAGE_TYPES`, inclusion validation) and DB level (Postgres check constraint `usage_type_check`), `wheels` defaults to 2 in the schema. Scopes `Bicycle.road` / `Bicycle.off_road` filter by usage type (covered by model specs; no UI currently exposes this filtering). `BicyclesController` is a plain RESTful resource; `root` routes to `bicycles#index`. Failed create/update render with `status: :unprocessable_content` (Rack 3 renamed the old `:unprocessable_entity` symbol) — Turbo Drive relies on that 422 status to redisplay the form in place.
- **Spring gotcha**: Spring's preloader has repeatedly hung (not just slowed down — genuinely stuck) after Gemfile/config changes during the Rails 6.1→7.1 upgrade. If a `bin/rails` command seems to hang, run `bin/spring stop` (or prefix the command with `DISABLE_SPRING=1`) rather than waiting it out.
- Prefer extending this structure (new models under `app/models`, routes in `config/routes.rb`) rather than introducing new architectural patterns without discussion.
