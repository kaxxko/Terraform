CREATE USER 'wordpress-user'@'%' IDENTIFIED BY 'wordpress';
CREATE DATABASE `wordpress`;
GRANT ALL PRIVILEGES ON `wordpress`.* TO "wordpress-user"@"%";
FLUSH PRIVILEGES;