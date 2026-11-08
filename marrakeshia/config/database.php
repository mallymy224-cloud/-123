<?php
/**
 * Marrakeshia — إعدادات الاتصال بقاعدة البيانات والثوابت العامة
 * متجر مراكشية | PHP + MySQL
 */

date_default_timezone_set('Africa/Casablanca');

/* ------------------------------------------------------------
 * بيانات الاتصال تُقرأ من متغيرات البيئة (Render / أي استضافة).
 * القيم الافتراضية أدناه للتطوير المحلي على XAMPP فقط، ولا تحتوي أي أسرار.
 * لا تضع كلمات مرور أو مفاتيح حقيقية داخل هذا الملف.
 * ------------------------------------------------------------ */
function env_value(string $key, string $default = ''): string
{
    $value = getenv($key);
    return $value === false ? $default : $value;
}

define('DB_HOST', env_value('DB_HOST', '127.0.0.1'));
define('DB_PORT', env_value('DB_PORT', '3306'));
define('DB_NAME', env_value('DB_NAME', 'marrakeshia'));
define('DB_USER', env_value('DB_USER', 'root'));
define('DB_PASS', env_value('DB_PASS', ''));
define('DB_CHARSET', 'utf8mb4');

/** سلسلة اتصال PDO؛ $withDatabase=false للاتصال قبل إنشاء/اختيار القاعدة */
function db_dsn(bool $withDatabase = true): string
{
    $dsn = 'mysql:host=' . DB_HOST . ';port=' . (int) DB_PORT . ';charset=' . DB_CHARSET;
    return $withDatabase ? $dsn . ';dbname=' . DB_NAME : $dsn;
}

/* ------- مسارات المشروع ------- */
define('ROOT_PATH', dirname(__DIR__));
define('UPLOAD_PATH', ROOT_PATH . '/assets/images/products');

/* ------- الحساب التلقائي لرابط المشروع ------- */
$docRoot = isset($_SERVER['DOCUMENT_ROOT']) ? str_replace('\\', '/', (string) realpath($_SERVER['DOCUMENT_ROOT'])) : '';
$appRoot = str_replace('\\', '/', (string) realpath(ROOT_PATH));
$basePath = '';
if ($docRoot !== '' && strpos($appRoot, $docRoot) === 0) {
    $basePath = str_replace('\\', '/', substr($appRoot, strlen($docRoot)));
}
define('BASE_URL', rtrim($basePath, '/'));

/* ------- الجلسة ------- */
if (session_status() === PHP_SESSION_NONE) {
    if (PHP_VERSION_ID >= 70300) {
        session_set_cookie_params([
            'lifetime' => 0,
            'path'     => '/',
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
    }
    session_start();
}

/**
 * الاتصال بقاعدة البيانات (اتصال واحد يُعاد استخدامه)
 */
function db(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = db_dsn();

    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
        $pdo->exec('SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci');
    } catch (PDOException $e) {
        http_response_code(500);
        echo '<!DOCTYPE html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'
            . '<title>خطأ في الاتصال</title></head>'
            . '<body style="font-family:Tahoma,Arial,sans-serif;background:#faf6f1;color:#2b2118;padding:40px;text-align:center">'
            . '<div style="max-width:640px;margin:40px auto;background:#fff;border-radius:18px;padding:32px;box-shadow:0 12px 40px rgba(0,0,0,.08)">'
            . '<h1 style="color:#b5442e;margin-top:0">تعذر الاتصال بقاعدة البيانات</h1>'
            . '<p>تأكد من تشغيل <strong>MySQL</strong> في لوحة تحكم XAMPP، ثم استورد ملف '
            . '<code>database/marrakeshia.sql</code> أو افتح '
            . '<a href="' . htmlspecialchars(BASE_URL, ENT_QUOTES, 'UTF-8') . '/install.php">install.php</a> لإعداد القاعدة تلقائياً.</p>'
            . '<p style="color:#7a6a5d;font-size:14px">' . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . '</p>'
            . '</div></body></html>';
        exit;
    }

    return $pdo;
}
