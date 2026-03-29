FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./chat-not-gpt/ /app/

EXPOSE 3000

CMD ["python3", "-m", "http.server", "3000", "--directory", "/app"]
