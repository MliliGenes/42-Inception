# Redis Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    # Redis in-memory data store
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Copy custom configuration
COPY conf/redis.conf /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]
