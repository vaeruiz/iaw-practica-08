#!/bin/bash

# Variables
CLAVE_MYSQL=root
ROOT_MYSQL=root
DB_NAME=wordpress
DB_USER=wordpress_user
DB_PASSWORD=wordpress_password
DIRECTORIO_HOME=/home/ubuntu

# Activar la depuración del script
set -x

#Actualizar lista de paquetes Ubuntu
apt update -y

#Actualizar los paquetes instalados
#apt upgrade -y

#----------------------------------------------------------

# Insatalar pila LAMP

# Instalar apache
apt install apache2 -y

# Mover archivo de host virtual
mv iaw-practica-08/fase-00/wordpress.conf /etc/apache2/sites-available/

# Instalar mysql-server
apt install mysql-server -y

#Cambiamos la contraseña root del servidor
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$CLAVE_MYSQL';"
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "FLUSH PRIVILEGES;"

# Instalar php y sus utilidades
apt install php libapache2-mod-php php-mysql -y

# Crear base de datos para wordpress
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

# Crear usuario para la base de datos de Wordpress
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "DROP USER '$DB_USER'@'%';"
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "CREATE USER '$DB_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD';"
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'%';"
mysql -u $ROOT_MYSQL -p$CLAVE_MYSQL <<< "FLUSH PRIVILEGES;"

# Instalar extensiones php
apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y

# Reiniciar apache
systemctl restart apache2

# Crear directorio del host virtual y configurar
rm -rf /var/www/wordpress
mkdir /var/www/wordpress
chown -R $USER:$USER /var/www/wordpress/

# Habilitar host virtual y desactivar el host por defecto
a2ensite wordpress
a2dissite 000-default
a2enmod rewrite
systemctl restart apache2

# Descargar paquete de Wordpress, descomprimir y configurar
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
touch /tmp/wordpress/.htaccess
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
mkdir /tmp/wordpress/wp-content/upgrade
cp -a /tmp/wordpress/. /var/www/wordpress
rm latest.tar.gz
rm -rf wordpress
cd $DIRECTORIO_HOME
# Configurar propiedad directorio wordpress y permisos
chown -R www-data:www-data /var/www/wordpress
find /var/www/wordpress/ -type d -exec chmod 750 {} \;
find /var/www/wordpress/ -type f -exec chmod 640 {} \;

# Configuramos el archivo de configuración de php
sed -i "s/database_name_here/$DB_NAME/" /var/www/wordpress/wp-config.php
sed -i "s/username_here/$DB_USER/" /var/www/wordpress/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" /var/www/wordpress/wp-config.php
sed -i "s/localhost/$IP_MYSQL_SERVER/" /var/www/wordpress/wp-config.php
