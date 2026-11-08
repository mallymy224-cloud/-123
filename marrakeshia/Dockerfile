# ============================================================
#  مراكشية — صورة Docker جاهزة للنشر على Render
# ============================================================
#  المتطلبات التي تم التحقق منها من شيفرة المشروع:
#    PHP >= 8.0  : str_starts_with / str_ends_with / static fn / array_key_first
#    pdo_mysql   : كل اتصالات قاعدة البيانات عبر PDO
#    mbstring    : mb_strlen / mb_substr في التحقق والعرض العربي
#    getimagesize() و IMAGETYPE_* من نواة PHP → لا حاجة لـ ext/gd
#    Apache      : لتفعيل ملفات .htaccess وتوفير $_SERVER['DOCUMENT_ROOT']
#    MySQL/MariaDB خارجية: بيانات الاتصال تُمرّر عبر متغيرات البيئة فقط
# ============================================================

FROM php:8.3-apache

# libonig-dev لازمة لبناء mbstring على الصورة الرسمية
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libonig-dev; \
    php -m | grep -qi '^pdo_mysql$' || docker-php-ext-install -j"$(nproc)" pdo_mysql; \
    php -m | grep -qi '^mbstring$'  || docker-php-ext-install -j"$(nproc)" mbstring; \
    a2enmod rewrite; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# إعدادات PHP للإنتاج + السماح برفع الصور حتى 5MB
COPY docker/php.ini /usr/local/etc/php/conf.d/zz-marrakeshia.ini

WORKDIR /var/www/html
COPY . /var/www/html/

COPY docker/render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh \
    && mkdir -p /var/www/html/assets/images/products /var/www/html/assets/images/uploads \
    && chown -R www-data:www-data \
        /var/www/html/assets/images/products \
        /var/www/html/assets/images/uploads

# لا توجد أي كلمة مرور أو مفتاح هنا.
# Render يضبط PORT تلقائياً (الافتراضي 10000) وentrypoint يقرأه وقت التشغيل.
# بيانات قاعدة البيانات تُضاف من Render Dashboard → Environment.
ENV APP_ENV=production \
    PORT=10000

EXPOSE 10000

# CMD موروث/مُعلن صراحةً؛ سكربت الدخول هو من يشغّل apache2-foreground فعلياً
CMD ["apache2-foreground"]
ENTRYPOINT ["/usr/local/bin/render-entrypoint.sh"]
