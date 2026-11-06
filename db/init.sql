-- Run once by the MariaDB image on an empty data volume: one database per app.
-- The passwords match DB_PASSWORD in workshop.env (fixed, local only).
CREATE DATABASE IF NOT EXISTS webdav CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ediarum_index CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'webdav'@'%' IDENTIFIED BY 'workshop';
CREATE USER IF NOT EXISTS 'index'@'%' IDENTIFIED BY 'workshop';

GRANT ALL PRIVILEGES ON webdav.* TO 'webdav'@'%';
GRANT ALL PRIVILEGES ON ediarum_index.* TO 'index'@'%';
FLUSH PRIVILEGES;
