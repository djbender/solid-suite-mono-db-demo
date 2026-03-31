# Solid Suite Mono DB Demo

Rails 8.1 demo app running **solid_queue**, **solid_cache**, and **solid_cable** on a single PostgreSQL database — no Redis required.

The interactive homepage lets you exercise each Solid gem in real time:

- **Solid Cache** — write a value to `Rails.cache` and read it back (30 s TTL)
- **Solid Queue** — enqueue a background job that sleeps 2 s and broadcasts its completion
- **Solid Cable** — send an Action Cable broadcast to all connected clients via Turbo Streams
- **Database Stats** — live counts of cache entries, queue jobs, processes, and cable messages

All backed by the same PostgreSQL database. All tables (`solid_cache_entries`, `solid_queue_*`, `solid_cable_messages`) live in a single schema.

## Quick Start (Docker)

No local Ruby or PostgreSQL needed.

```bash
docker compose up # starts PostgreSQL 18 + Rails on http://localhost:3000
```

Run any command with `docker compose run --rm app`. The app service volume-mounts `.:/rails` so code changes are reflected immediately.

```bash
docker compose run --rm app bin/setup                    # initial setup
docker compose run --rm app bin/rubocop                  # lint
docker compose run --rm app bin/brakeman                 # security scan
docker compose run --rm app bin/bundler-audit            # gem audit
docker compose run --rm app bin/rails db:migrate         # run migrations
docker compose run --rm app bin/rails console            # Rails console
```

## Quick Start (Local)

Requires Ruby 4.0.2 and PostgreSQL.

```bash
bin/setup      # bundle install, db:prepare, log:clear, start server
bin/dev        # start dev server
```

Visit http://localhost:3000.

## How It Works

### Architecture

```
Browser ─── Turbo Streams / Action Cable ─── Rails (Puma)
                                                │
                        ┌───────────────────────┼───────────────────────┐
                        │                       │                       │
                   Solid Cache            Solid Queue             Solid Cable
                        │                       │                       │
                        └───────────────────────┴───────────────────────┘
                                          PostgreSQL
```

A single `DemoController` drives the entire app. `DemoJob` is the only background job. There are no custom models — only Solid Suite internal tables.

The Solid Queue supervisor runs inside Puma via the `:solid_queue` plugin (enabled by `SOLID_QUEUE_IN_PUMA=1`), keeping the deployment to a single process.

### Key Configuration

| File               | What it configures                                                               |
|--------------------|----------------------------------------------------------------------------------|
| `config/queue.yml` | Dispatcher polling (1 s), worker threads (3), process count (`JOB_CONCURRENCY`) |
| `config/cache.yml` | Max size (1 GB), namespace per environment                                       |
| `config/cable.yml` | `solid_cable` adapter (dev/prod), polling interval (100 ms), 1-day retention     |
| `config/puma.rb`   | Loads `:solid_queue` plugin when `SOLID_QUEUE_IN_PUMA=1`                         |

### Environment Variables

| Variable              | Default                  | Purpose                                              |
|-----------------------|--------------------------|------------------------------------------------------|
| `SOLID_QUEUE_IN_PUMA` | —                        | Set to `1` to run the queue supervisor inside Puma   |
| `JOB_CONCURRENCY`     | `1`                      | Number of queue worker processes                     |
| `RAILS_MAX_THREADS`   | `3` (Puma) / `5` (DB pool) | Thread count                                      |
| `DATABASE_URL`        | —                        | Overrides `database.yml`                             |

## Testing

Requires local Ruby + PostgreSQL (tests need a separate test database).

```bash
bin/rails test         # unit + integration (Minitest)
bin/rails test:system  # system tests (Capybara + Selenium)
bin/ci                 # full CI: rubocop, brakeman, bundler-audit, importmap audit, tests, seeds, system tests
```

## CI

GitHub Actions runs on every PR and push to `main`:

- **scan_ruby** — Brakeman + bundler-audit
- **scan_js** — importmap audit
- **lint** — RuboCop (rubocop-rails-omakase)
- **test** — Minitest against PostgreSQL
- **system-test** — Capybara system tests (screenshots uploaded on failure)

## Stack

- Ruby 4.0.2 / Rails 8.1.3
- PostgreSQL 18
- Puma + Thruster
- Hotwire (Turbo + Stimulus) / importmap
- Propshaft (assets)
- solid_cache, solid_queue, solid_cable