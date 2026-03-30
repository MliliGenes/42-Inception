FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

RUN git clone https://github.com/gabrielecirulli/2048.git /app

WORKDIR /app

EXPOSE 8080

CMD ["npx", "serve", "-s", ".", "-l", "8080"]