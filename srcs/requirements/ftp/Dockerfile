FROM debian:bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 21 21000-21010

ENTRYPOINT ["/usr/local/bin/setup.sh"]
