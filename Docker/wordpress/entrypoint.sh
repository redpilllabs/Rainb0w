#!/bin/bash

# Wait for MariaDB to start listening on port 3306
sleep 5
until nc -z -v -w30 mariadb 3306; do
    echo "Waiting for MariaDB to start..."
    # Wait for 5 seconds before checking again
    sleep 5
done

# Install and setup WordPress if no existing setup found
if [ ! -f /var/www/html/wp-config.php ]; then
    wp core download --allow-root
    wp config create --dbname=${WORDPRESS_DB_NAME} --dbuser=${WORDPRESS_DB_USER} --dbpass=${WORDPRESS_DB_PASSWORD} --dbhost=${WORDPRESS_DB_HOST} --allow-root --extra-php <<PHP
define('FORCE_SSL_ADMIN', true);
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
  \$_SERVER['HTTPS'] = 'on';
}
PHP
    wp core install --url=${WORDPRESS_URL} --title="${WORDPRESS_TITLE}" --admin_user=${WORDPRESS_ADMIN_USER} --admin_password=${WORDPRESS_ADMIN_PASSWORD} --admin_email=${WORDPRESS_ADMIN_EMAIL} --skip-email --allow-root
    wp plugin install loginizer --activate --allow-root # Protect admin panel from brute-force attacks
    wp plugin install wordpress-importer --activate --allow-root
    if [ -f /var/www/wp/wp-demo-content.xml ]; then
        wp import /var/www/wp/wp-demo-content.xml --authors=create --allow-root
    fi
    if [ -f /var/www/wp/theme.zip ]; then
        wp theme install /var/www/wp/theme.zip --activate --allow-root
    fi
    wp media import "https://s.w.org/style/images/about/WordPress-logotype-wmark.png" --porcelain --allow-root | wp option update site_icon --allow-root
    echo "ServerName ${WORDPRESS_URL}" >/etc/apache2/sites-available/wordpress.conf
else
    echo "Existing wp-config.php found!"
fi

# Start Apache
a2ensite wordpress.conf &&
    exec apache2-foreground
