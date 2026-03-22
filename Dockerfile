# syntax=docker/dockerfile:1
# Rubysmithing Skills — minimal interactive demo
# ClaudeBox-inspired: non-root user, credentials-only mount
FROM ruby:3.3-slim

# ── Non-root user (UID overridable at build time) ─────────────────────────────
# docker build --build-arg USER_UID=$(id -u) . for seamless file ownership
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g "${USER_GID}" user \
 && useradd -u "${USER_UID}" -g "${USER_GID}" -m -s /bin/bash user \
 && mkdir -p /home/user/.claude

# ── Node 22 + Claude Code CLI ─────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g @anthropic-ai/claude-code \
 && rm -rf /var/lib/apt/lists/*

# ── Bake in skills into Claude Code's personal skills directory ───────────────
# Claude Code discovers skills from ~/.claude/skills/ at session start.
# docker/ contains only runtime files (entrypoint, headless variant) —
# they land in ~/.claude/skills/docker/ which is harmless to skill discovery.
COPY --chown=user:user . /home/user/.claude/skills/
WORKDIR /home/user

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER user

# Auth via credentials mount (primary — no API key required):
#   docker run -it -v ~/.claude/.credentials.json:/home/user/.claude/.credentials.json:ro rubysmithing-minimal
# Or via env var:
#   docker run -it -e ANTHROPIC_API_KEY=... rubysmithing-minimal
ENV ANTHROPIC_API_KEY=""

ENTRYPOINT ["/entrypoint.sh"]
