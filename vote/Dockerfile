# Pin to exact stable Debian Bookworm base image
FROM python:3.11.9-slim-bookworm AS base

# Install curl for container health check and clean up apt caches
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Create dedicated non-root user and group
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /sbin/nologin -d /usr/local/app appuser

WORKDIR /usr/local/app

# Install dependencies before copying application code for layer caching
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Dev stage for development
FROM base AS dev
RUN pip install --no-cache-dir watchdog
ENV FLASK_ENV=development
COPY . .
RUN chown -R appuser:appuser /usr/local/app
USER appuser
CMD ["python", "app.py"]

# Final production stage
FROM base AS final

COPY . .
RUN chown -R appuser:appuser /usr/local/app

USER appuser

EXPOSE 8080

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
