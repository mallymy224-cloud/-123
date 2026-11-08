# ============================================================
#  مراكشية — Dockerfile واحد مستقل للنشر على Render
#  لا يعتمد على أي ملف خارجي: كل الإعدادات مضمّنة هنا.
# ============================================================
#  المتطلبات التي تم التحقق منها من شيفرة المشروع:
#    PHP  >= 8.0 : str_starts_with / str_ends_with / static fn / array_key_first
#    pdo_mysql   : كل اتصالات قاعدة البيانات عبر PDO
#    mbstring    : mb_strlen / mb_substr
#    getimagesize() و IMAGETYPE_* من نواة PHP → لا حاجة لـ ext/gd
#    Apache      : لتفعيل .htaccess وتوفير $_SERVER['DOCUMENT_ROOT']
#    MySQL/MariaDB خارجية: بياناتها تُمرّر عبر متغيرات البيئة فقط
# ============================================================

FROM php:8.3-apache

# --- 1) الإضافات + إعدادات PHP + إعدادات Apache (كلها داخل هذا الملف) ---
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libonig-dev; \
    php -m | grep -qi '^pdo_mysql$' || docker-php-ext-install -j"$(nproc)" pdo_mysql; \
    php -m | grep -qi '^mbstring$'  || docker-php-ext-install -j"$(nproc)" mbstring; \
    a2enmod rewrite; \
    printf '%s\n' \
        'upload_max_filesize = 5M' \
        'post_max_size = 8M' \
        'memory_limit = 128M' \
        'display_errors = Off' \
        'log_errors = On' \
        'error_log = /dev/stderr' \
        > /usr/local/etc/php/conf.d/zz-marrakeshia.ini; \
    printf '%s\n' \
        '' \
        '<Directory /var/www/html>' \
        '    AllowOverride All' \
        '    Require all granted' \
        '    Options -Indexes +FollowSymLinks' \
        '</Directory>' \
        '<FilesMatch "^\.">' \
        '    Require all denied' \
        '</FilesMatch>' \
        >> /etc/apache2/apache2.conf; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# --- 2) نسخ المشروع وتهيئة مجلدات الرفع ---
WORKDIR /var/www/html
COPY . /var/www/html/

# إزالة أي ملف أسرار محلي قد يكون نُسخ مع المشروع (لا يوجد .dockerignore)
RUN rm -f /var/www/html/.env /var/www/html/.env.* \
    && rm -rf /var/www/html/.git \
    && mkdir -p /var/www/html/assets/images/products /var/www/html/assets/images/uploads \
    && chown -R www-data:www-data \
        /var/www/html/assets/images/products \
        /var/www/html/assets/images/uploads

# --- 3) لا أسرار هنا. Render يضبط PORT تلقائياً (10000) ---
ENV APP_ENV=production \
    PORT=10000

EXPOSE 10000

# --- 4) يقرأ $PORT وقت التشغيل ويجعل Apache يستمع عليه على 0.0.0.0 ---
# (ENTRYPOINT الخاص بالصورة الأصلية docker-php-entrypoint يمرّر هذا الأمر كما هو)
CMD ["sh", "-c", "PORT=\"${PORT:-10000}\"; case \"$PORT\" in ''|*[!0-9]*) PORT=10000;; esac; sed -i \"s/^Listen .*/Listen $PORT/\" /etc/apache2/ports.conf; sed -i \"s/:80>/:$PORT>/\" /etc/apache2/sites-available/000-default.conf; exec apache2-foreground"]
