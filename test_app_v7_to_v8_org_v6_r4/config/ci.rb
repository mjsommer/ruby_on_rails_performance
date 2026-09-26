# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Tests: RSpec", "bundle exec rspec"

  # Not "Tests: Seeds" (db:seed:replant against RAILS_ENV=test): db/seeds.rb
  # commits real rows outside RSpec's transactional rollback, permanently
  # polluting the test database for every bundle exec rspec run afterward.

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
