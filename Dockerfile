FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv for faster dependency management
RUN pip install --no-cache-dir uv

COPY . .

# Install Python dependencies using uv sync
# --extra otel ships the OpenTelemetry SDK/exporter so tracing can be enabled at
# runtime via OTEL_* env vars; it stays a no-op unless an OTLP endpoint is set.
RUN uv sync --frozen --no-dev --extra disk --extra otel

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app

# Give read and write access to the store_creds volume
RUN mkdir -p /app/store_creds \
    && chown -R app:app /app/store_creds \
    && chmod 755 /app/store_creds

# NOTA UTOPICA (req R.01, 2026-08-15): NO bajamos a USER app aqui.
# Railway monta volumenes nuevos con dueno root; el arranque necesita
# ser root una vez para hacer chown del volumen (WORKSPACE_MCP_CREDENTIALS_DIR)
# antes de dejar caer privilegios al usuario app para el proceso real.
# Ver docker-entrypoint-utopica.sh.

# Expose port (use default of 8000 if PORT not set)
EXPOSE 8000
# Expose additional port if PORT environment variable is set to a different value
ARG PORT
EXPOSE ${PORT:-8000}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD sh -c 'curl -f http://localhost:${PORT:-8000}/health || exit 1'

# Set environment variables for Python startup args
ENV TOOL_TIER=""
ENV TOOLS=""

COPY docker-entrypoint-utopica.sh /docker-entrypoint-utopica.sh
RUN chmod +x /docker-entrypoint-utopica.sh

# Use entrypoint for the base command and CMD for args
ENTRYPOINT ["/docker-entrypoint-utopica.sh"]
CMD ["uv run main.py --transport streamable-http ${TOOL_TIER:+--tool-tier \"$TOOL_TIER\"} ${TOOLS:+--tools $TOOLS}"]
