FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Keep in sync with the "version" field in config.yaml and the "version" in
# the root pyproject.toml -- this pins the addon to a specific release of
# the `supernote` package published on PyPI.
ARG SUPERNOTE_VERSION=0.20.0

# sqlite3: CLI for inspecting the database
# jq: parses /data/options.json (Home Assistant add-on options)
# curl: used by run.sh to wait for the server to become ready
RUN apt-get update && \
    apt-get install -y --no-install-recommends sqlite3 jq curl && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "supernote[server]==${SUPERNOTE_VERSION}"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 8080 8081

CMD ["/run.sh"]
