FROM caddy:2-alpine

# Copy Caddyfile configuration
COPY Caddyfile /etc/caddy/Caddyfile

# Copy static HTML content
COPY html/ /srv/

# Expose port 8080 (non-privileged)
EXPOSE 8080

# Run as non-root user for security
USER 1000

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]