FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates build-essential
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"
ADD ./pyproject.toml /app/
ADD ./uv.lock /app/
WORKDIR /app
RUN uv sync --frozen

COPY . .
