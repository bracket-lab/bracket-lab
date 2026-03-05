# Madness-rb

A Ruby on Rails application for managing tournament brackets and pools.

## Requirements

- Ruby 3.4.2
- SQLite 3.8.0+
- Node.js/Bun for asset compilation
- Docker for production deployment

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/bracket-lab/bracket-lab.git
cd bracket-lab
```

2. Run the setup script:
```bash
bin/setup
```

This will:
- Install Ruby dependencies via Bundler
- Install JavaScript dependencies via Bun
- Set up the development database
- Start the development server

3. Configure environment variables:
```bash
cp .env.template .env
```

Edit `.env` and set the following required variables:
- `RAILS_MASTER_KEY`: Rails master key for decrypting credentials
- `POOL_NAME`: Name of your tournament pool
- `MADNESS_HOST`: Host domain for your application
- `SMTP_*`: SMTP settings for email delivery
- `DEV_PASSWORD`: Password for dev scenario users

## Testing

Run the test suite:
```bash
bin/rails test
```

## Development Scenarios

Reset the database to different tournament states for development and testing:

```bash
# List available scenarios
bin/rails dev:scenarios

# Reset to a specific state
bin/rails dev:scenarios[pre_tipoff]
```

Available scenarios:

| Scenario | Description |
|----------|-------------|
| `pre_selection` | No tournament exists |
| `pre_tipoff` | Tournament created, brackets editable |
| `tipoff` | Brackets locked, no game results |
| `some_games` | ~10 Round 1 games completed |
| `first_weekend` | 48 games (Rounds 1 & 2 complete) |
| `mid_tournament` | 50 games with Sweet 16 gaps |
| `final_four` | 60 games (3 games remaining) |
| `completed` | All 63 games finished |

## Production Deployment

The application includes a production-ready Dockerfile with:
- Multi-stage builds for smaller images
- Jemalloc for improved memory usage
- Proper security settings
- Automatic database migrations
- Asset precompilation

The production environment uses:
- SQLite databases with persistent storage
- Solid Queue for background job processing
- Solid Cache for caching
- Solid Cable for Action Cable
- Thruster for HTTP asset optimization
- Pundit for authorization

## License

This software is licensed under the GNU Affero General Public License v3 (AGPL-3.0).
See the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.
