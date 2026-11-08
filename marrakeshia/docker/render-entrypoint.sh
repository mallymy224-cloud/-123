#!/bin/sh
# يجعل Apache يستمع إلى المنفذ الذي يحدده Render عبر متغير البيئة PORT.
# يُنفَّذ عند كل تشغيل للحاوية (وليس وقت البناء) لأن PORT قد يتغير.
set -eu

PORT="${PORT:-10000}"
case "$PORT" in
    ''|*[!0-9]*) PORT=10000 ;;
esac

cat > /etc/apache2/ports.conf <<EOF
Listen ${PORT}
EOF

cat > /etc/apache2/sites-available/000-default.conf <<EOF
ServerName localhost

<VirtualHost *:${PORT}>
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        Options -Indexes +FollowSymLinks
    </Directory>

    # ملفات البناء والضبط لا تُقدَّم عبر الويب
    <Directory /var/www/html/docker>
        Require all denied
    </Directory>

    # حظر الملفات المخفية (.env / .git / .dockerignore ...)
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    ErrorLog /proc/self/fd/2
    CustomLog /proc/self/fd/1 combined
</VirtualHost>
EOF

# مجلدات الرفع قابلة للكتابة من قبل مستخدم Apache
mkdir -p /var/www/html/assets/images/products /var/www/html/assets/images/uploads
chown -R www-data:www-data \
    /var/www/html/assets/images/products \
    /var/www/html/assets/images/uploads

exec docker-php-entrypoint apache2-foreground
