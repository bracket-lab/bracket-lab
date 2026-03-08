# Bracket Lab

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
- `APP_HOST`: Host domain for your application
- `SMTP_*`: SMTP settings for email delivery

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

## Self-Hosting

Bracket Lab publishes Docker images to GitHub Container Registry.

### Quick Start

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -v bracket-lab-storage:/rails/storage \
  -v bracket-lab-certs:/rails/storage/thruster \
  -e TLS_DOMAIN=brackets.example.com \
  -e RAILS_MASTER_KEY=<your-master-key> \
  -e POOL_NAME="My Bracket Pool" \
  -e APP_HOST=brackets.example.com \
  --name bracket-lab \
  ghcr.io/bracket-lab/bracket-lab:latest
```

### Generating a Master Key

The master key encrypts application credentials. Generate one for your deployment:

```bash
docker run --rm ghcr.io/bracket-lab/bracket-lab:latest bin/rails secret | head -c 32
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_MASTER_KEY` | Yes | Decrypts application credentials |
| `POOL_NAME` | Yes | Name of your bracket pool |
| `APP_HOST` | Yes | Hostname for email links (e.g. `brackets.example.com`) |
| `TLS_DOMAIN` | Yes | Domain for automatic SSL via Let's Encrypt (e.g. `brackets.example.com`) |
| `SMTP_HOST` | For email | SMTP server address |
| `SMTP_USERNAME` | For email | SMTP username |
| `SMTP_PASSWORD` | For email | SMTP password |
| `DEFAULT_FROM_EMAIL` | For email | Sender address for outgoing email |
| `SMTP_PORT` | No | SMTP port (default: 587) |
| `SMTP_AUTHENTICATION` | No | SMTP auth method (default: plain) |

### Data Persistence

Bracket Lab uses SQLite. Mount a volume at `/rails/storage` to persist your database, and a separate volume for TLS certificates:

```bash
docker volume create bracket-lab-storage
docker volume create bracket-lab-certs
```

### Docker Compose

```yaml
services:
  bracket-lab:
    image: ghcr.io/bracket-lab/bracket-lab:2026
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - bracket-lab-storage:/rails/storage
      - bracket-lab-certs:/rails/storage/thruster
    environment:
      TLS_DOMAIN: ${TLS_DOMAIN}
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      POOL_NAME: ${POOL_NAME}
      APP_HOST: ${APP_HOST}
      SMTP_HOST: ${SMTP_HOST:-}
      SMTP_USERNAME: ${SMTP_USERNAME:-}
      SMTP_PASSWORD: ${SMTP_PASSWORD:-}
      DEFAULT_FROM_EMAIL: ${DEFAULT_FROM_EMAIL:-}
    restart: unless-stopped

volumes:
  bracket-lab-storage:
  bracket-lab-certs:
```

### Running Behind a Reverse Proxy

If you already terminate SSL with nginx, Caddy, or Cloudflare, omit `TLS_DOMAIN` and expose only port 80:

```yaml
    ports:
      - "3000:80"
    # Do not set TLS_DOMAIN
```

### Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent build from main |
| `2026` | Latest release for the 2026 tournament season |
| `2026.0` | Specific version (immutable) |

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
