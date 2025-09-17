# Beszel Agent

Monitoring agent for Beszel.

## Environment Variables

- `LISTEN`: Listen address
- `KEY`: API key

## Setup

1. Set `LISTEN` and `KEY` in `.env`
2. Run: `systemctl --user start beszel-agent.container`