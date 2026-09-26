# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Rails application (`rails new`) using import maps (`importmap-rails`) for JavaScript — no Node/Yarn/build step. The only domain feature so far is a `Bicycle` CRUD resource (brand, model, usage_type, color, wheels) — see Architecture notes below. There is no README content beyond the default template.

## Stack

- Ruby 4.0.7, Rails 8.1.3.1 (`config.load_defaults 8.1`, fully adopted — no lingering `new_framework_defaults_*.rb` initializers). Bundler is pinned to `4.0.20` in `Gemfile.lock` — that's Ruby 4.0.7's own default, not an arbitrary choice (see the Bundler/RubyGems gotcha below)
- PostgreSQL (`pg` gem) — databases are named `test_app_v6_{development,test,production}` in `config/database.yml`
- Puma 8 as the app server (bumped straight from 6 during the Rails 8.1 upgrade; Rack 3 requires Puma >= 6). This app doesn't use Puma lifecycle hooks or cluster/`workers` mode, so none of Puma 7/8's breaking changes (hook renames, `preload_app!` cluster default) apply here
- `importmap-rails` for JS — no bundler, no Node/Yarn. Entry point is `app/javascript/application.js`; pins live in `config/importmap.rb`; CDN-vendored packages sit in `vendor/javascript/`
- Turbo (`turbo-rails`) + `@rails/ujs` for the JS/HTML integration layer (Turbo Drive handles navigation/forms; UJS handles `data-method`/`data-confirm` links like the Delete button)
- CSS goes through plain Sprockets (`sprockets-rails`) — `app/assets/stylesheets/application.css` is plain CSS, no Sass anywhere in the app. `sass-rails`/`sassc-rails`/`sassc` were dropped during the Rails 8.1 upgrade (unused, and `sassc-rails`'s repo was archived in October 2025); `sprockets-rails` is now a direct Gemfile dependency instead of a transitive one. This was never routed through the JS bundler, before or after the import-map migration
- RSpec (`rspec-rails`, `~> 8.0` as of the Rails 8.1 upgrade) for unit/request specs, with Capybara + `selenium-webdriver` for system specs, and `factory_bot_rails` for test data (factories in `spec/factories/`). No `webdrivers` gem — `selenium-webdriver` >= 4.11 ships Selenium Manager, which auto-provisions the matching browser driver
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

CI (setup + importmap vulnerability audit + RSpec, all in one):
```
bin/ci
```

## Architecture notes

- Standard Rails app layout (`app/models`, `app/controllers`, `app/views`, `app/jobs`, `app/mailers`, `app/channels`, `app/helpers`) — no non-standard directories or service-object conventions have been established.
- JavaScript lives in `app/javascript`; `application.js` is the sole entry point (imports `@rails/ujs` and `@hotwired/turbo-rails`). `app/javascript/channels/consumer.js` is dormant Action Cable scaffolding — no channels are actually defined, and nothing imports it yet.
- `config/importmap.rb` pins JS packages; run `bin/importmap pin <package>` to add one. Pins resolve either to a CDN-vendored file under `vendor/javascript/` (e.g. `@rails/ujs`, `@rails/actioncable`) or, for `@hotwired/turbo-rails`, to the gem's own bundled asset.
- `Bicycle` (`app/models/bicycle.rb`) is the only domain model: `usage_type` is restricted to `road`/`off-road` at both the model (`Bicycle::USAGE_TYPES`, inclusion validation) and DB level (Postgres check constraint `usage_type_check`), `wheels` defaults to 2 in the schema. Scopes `Bicycle.road` / `Bicycle.off_road` filter by usage type (covered by model specs; no UI currently exposes this filtering). `BicyclesController` is a plain RESTful resource; `root` routes to `bicycles#index`. Failed create/update render with `status: :unprocessable_content` (Rack 3 renamed the old `:unprocessable_entity` symbol) — Turbo Drive relies on that 422 status to redisplay the form in place.
- **Spring was removed during the Rails 8.1 upgrade** (it's no longer in the Gemfile, and `bin/spring`/`config/spring.rb` are gone). This was a deliberate choice, not an oversight: Rails 8's own `bin/rails`/`bin/rake` templates dropped Spring's binstub wiring by default, the gem itself was tested and does still work against Rails 8.1, but this app's plain boot time without it is ~0.35s (bootsnap + Zeitwerk) — negligible savings for the hang risk. (Historical note: Spring's preloader had repeatedly hung — not just slowed down, genuinely stuck — after Gemfile/config changes during the Rails 6.1→7.1 upgrade.) Don't re-add Spring without a concrete reason; it isn't wired into any binstub.
- **`json` gem gotcha**: pinned to `~> 2.21` (below 3.0) in the Gemfile. `json` 3.0 made `JSON.parse`'s second argument keyword-only, which breaks `ActiveSupport::JSON.decode`'s positional `::JSON.parse(json, options)` call under Rails 8.1.3.1 — activesupport declares no upper bound on `json`, so an unconstrained `bundle update` will happily resolve to 3.0 and silently break session/flash cookie decryption on every request. Don't remove this pin without confirming activesupport's `JSON.decode` has been fixed to call `JSON.parse` with keywords.
- Rails 8.1's built-in CI runner (`bin/ci` / `config/ci.rb`) runs `bin/setup --skip-server`, `bin/importmap audit`, then tests. The generated template's default test step (`bin/rails test`, i.e. Minitest) was rewritten to `bundle exec rspec` since this app only has RSpec (`spec/`, no `test/` dir) — that step already covers system specs, so there's no separate `test:system` step. The template's default "Tests: Seeds" step (`db:seed:replant` against `RAILS_ENV=test`) was dropped entirely: `db/seeds.rb` commits real rows outside RSpec's transactional rollback, which permanently pollutes the test database for every `bundle exec rspec` run afterward (discovered the hard way — it broke the `Bicycle.road`/`.off_road` scope specs after one `bin/ci` run). If the test DB ever ends up in that state, `bin/rails db:test:prepare` restores it.
- Solid Queue, Solid Cache, Solid Cable, Kamal 2, Thruster, and the `bin/rails generate authentication` scaffold were all evaluated during the Rails 8.1 upgrade and deliberately **not** adopted: this app has no background jobs, no cache pressure, no Action Cable channels in use, no chosen deployment target, and no auth requirement. Don't propose adopting any of these reflexively — each is a separate decision to make if/when the app actually grows a matching need.
- **Bundler/RubyGems gotcha**: `Gemfile.lock`'s `BUNDLED WITH` must track whatever Bundler version ships by default with the pinned Ruby (`4.0.20` for Ruby 4.0.7). Ordinary top-level `bundle exec` commands tolerate a mismatch (an older pinned Bundler self-installs fine under a newer Ruby's RubyGems), but `bin/ci` shells out to a *nested* `bundle exec` subprocess, and that path breaks with a `LoadError` (a duplicated gem path segment) plus `already initialized constant Gem::Platform::*` warnings if the two are out of sync. Discovered during the Ruby 3.3.12 → 4.0.7 upgrade, when `BUNDLED WITH` was left at the old `2.5.22` — fixed by running `bundle _<version>_ install` to relock to the Ruby-default Bundler. Re-check this any time Ruby's version changes, even if plain `bundle exec` commands still seem to work.
- Prefer extending this structure (new models under `app/models`, routes in `config/routes.rb`) rather than introducing new architectural patterns without discussion.
