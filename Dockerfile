# Multi-stage build for optimized Redmica image
FROM ruby:3.2-slim AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        nodejs \
        npm \
        git \
        libyaml-dev \
        libffi-dev \
        libssl-dev && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /redmica

# Copy and install gems
COPY Gemfile* ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3 && \
    bundle clean --force

# Copy application code
COPY . .

# Production stage
FROM ruby:3.2-slim AS production

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        imagemagick \
        tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /redmica

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application from builder stage
COPY --from=builder /redmica /redmica

# Set environment variables
ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Precompiling assets..."\n\
RAILS_ENV=production SECRET_KEY_BASE=${SECRET_KEY_BASE:-$(bundle exec rails secret)} bundle exec rake assets:precompile\n\
echo "Starting Redmica..."\n\
exec bundle exec rails server -b 0.0.0.0' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Create non-root user and set ownership
RUN useradd -m -u 1000 redmica && \
    chown -R redmica:redmica /redmica
USER redmica

# Expose default Redmica port
EXPOSE 3000

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/docker-entrypoint.sh"]
