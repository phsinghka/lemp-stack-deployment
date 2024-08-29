#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Install Nginx
echo "Installing Nginx..."
apt install nginx -y
systemctl start nginx
systemctl enable nginx

# Install MySQL
echo "Installing MySQL..."
apt install mysql-server -y

# Secure MySQL installation
echo "Securing MySQL installation..."
mysql_secure_installation <<EOF

y
password
password
y
y
y
y
EOF

# Install PHP and necessary extensions
echo "Installing PHP and extensions..."
apt install php-fpm php-mysql -y

# Create Nginx server block
echo "Creating Nginx server block..."
cat > /etc/nginx/sites-available/lemp_project <<EOF
server {
    listen 80;
    server_name localhost;
    root /var/www/lemp_project;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Enable the Nginx server block
echo "Enabling Nginx server block..."
ln -s /etc/nginx/sites-available/lemp_project /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Create PHP test files
echo "Creating PHP test files..."
mkdir -p /var/www/lemp_project
cat > /var/www/lemp_project/index.php <<EOF
<?php
phpinfo();
?>
EOF

cat > /var/www/lemp_project/test_db.php <<EOF
<?php
\$servername = "localhost";
\$username = "root";
\$password = "password";
\$dbname = "lemp_db";

\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}
echo "Connected successfully";
?>
EOF

# Set proper permissions
chown -R www-data:www-data /var/www/lemp_project

# Create MySQL database and user
echo "Creating MySQL database and user..."
mysql -u root -ppassword <<EOF
CREATE DATABASE lemp_db;
CREATE USER 'lemp_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON lemp_db.* TO 'lemp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

echo "LEMP stack setup complete. You can test your installation by visiting your server's IP address in a web browser."

