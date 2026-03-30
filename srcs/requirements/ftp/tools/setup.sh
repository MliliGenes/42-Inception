#!/bin/bash
set -euo pipefail

FTP_USER_NAME="${FTP_USER:-ftpuser}"
FTP_USER_PASS="${FTP_PASSWORD:-ftppass}"

if ! id "${FTP_USER_NAME}" >/dev/null 2>&1; then
    useradd -m -d /var/www/html -s /bin/bash "${FTP_USER_NAME}"
fi

echo "${FTP_USER_NAME}:${FTP_USER_PASS}" | chpasswd
chown -R "${FTP_USER_NAME}:${FTP_USER_NAME}" /var/www/html

mkdir -p /var/run/vsftpd/empty
chmod 755 /var/run/vsftpd
chmod 555 /var/run/vsftpd/empty

exec /usr/sbin/vsftpd /etc/vsftpd.conf
