#!/usr/bin/env bash

Autoconf_Ver='autoconf-2.13'
Libiconv_Ver='libiconv-1.17'
LibMcrypt_Ver='libmcrypt-2.5.8'
Mcypt_Ver='mcrypt-2.6.8'
Mhash_Ver='mhash-0.9.9.9'
Freetype_Ver='freetype-2.7'
Freetype_New_Ver='freetype-2.13.0'
Curl_Ver='curl-7.62.0'
Pcre_Ver='pcre-8.45'
Jemalloc_Ver='jemalloc-5.3.0'
TCMalloc_Ver='gperftools-2.9.1'
Libunwind_Ver='libunwind-1.2.1'
Libicu4c_Ver='icu4c-58_3'
Boost_Ver='boost_1_59_0'
Boost_New_Ver='boost_1_67_0'
Openssl_Ver='openssl-1.0.2u'
Openssl_New_Ver='openssl-1.1.1w'
Nghttp2_Ver='nghttp2-1.52.0'
Libzip_Ver='libzip-1.3.2'
Luajit_Ver='luajit2-2.1-20230119'
LuaNginxModule='lua-nginx-module-0.10.26'
LuaRestyCore='lua-resty-core-0.1.28'
LuaRestyLrucache='lua-resty-lrucache-0.13'
NgxDevelKit='ngx_devel_kit-0.3.3'
Nginx_Ver='nginx-1.26.0'
if [ -n "${Custom_Nginx_Ver}" ]; then
    Nginx_Ver="${Custom_Nginx_Ver}"
fi
Caddy_Ver='caddy-2.7.1'
NgxFancyIndex_Ver='ngx-fancyindex-0.5.2'
if [ "${DBSelect}" = "1" ]; then
    Mysql_Ver='mysql-5.1.73'
elif [ "${DBSelect}" = "2" ]; then
    Mysql_Ver='mysql-5.5.62'
elif [ "${DBSelect}" = "3" ]; then
    Mysql_Ver='mysql-5.6.51'
elif [ "${DBSelect}" = "4" ]; then
    Mysql_Ver='mysql-5.7.44'
elif [ "${DBSelect}" = "5" ]; then
    Mysql_Ver='mysql-8.0.37'
elif [ "${DBSelect}" = "6" ]; then
    Mariadb_Ver='mariadb-5.5.68'
elif [ "${DBSelect}" = "7" ]; then
    Mariadb_Ver='mariadb-10.4.33'
elif [ "${DBSelect}" = "8" ]; then
    Mariadb_Ver='mariadb-10.5.24'
elif [ "${DBSelect}" = "9" ]; then
    Mariadb_Ver='mariadb-10.6.17'
elif [ "${DBSelect}" = "10" ]; then
    Mariadb_Ver='mariadb-10.11.7'
elif [ "${DBSelect}" = "11" ]; then
    Mysql_Ver='mysql-8.4.4'
fi
if [ -n "${Custom_Mysql_Ver}" ]; then
    Mysql_Ver="${Custom_Mysql_Ver}"
fi
if [ -n "${Custom_Mariadb_Ver}" ]; then
    Mariadb_Ver="${Custom_Mariadb_Ver}"
fi
case "${PHPSelect}" in
    7.0)  Php_Ver='php-7.0.33' ;;
    7.1)  Php_Ver='php-7.1.33' ;;
    7.2)  Php_Ver='php-7.2.34' ;;
    7.3)  Php_Ver='php-7.3.33' ;;
    7.4)  Php_Ver='php-7.4.33' ;;
    8.0)  Php_Ver='php-8.0.30' ;;
    8.1)  Php_Ver='php-8.1.28' ;;
    8.2)  Php_Ver='php-8.2.19' ;;
    8.3)  Php_Ver='php-8.3.7' ;;
    8.4)  Php_Ver='php-8.4.0' ;;
esac
if [ -n "${Custom_Php_Ver}" ]; then
    Php_Ver="${Custom_Php_Ver}"
fi
APR_Ver='apr-1.7.4'
APR_Util_Ver='apr-util-1.6.3'
if [ "${ApacheSelect}" = "1" ]; then
    Apache_Ver='httpd-2.2.34'
elif [ "${ApacheSelect}" = "2" ]; then
    Apache_Ver='httpd-2.4.57'
fi

# Official download URLs - core libraries
Autoconf_URL="https://ftp.gnu.org/gnu/autoconf/${Autoconf_Ver}.tar.gz"
Libiconv_URL="https://ftp.gnu.org/gnu/libiconv/${Libiconv_Ver}.tar.gz"
LibMcrypt_URL="https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/${LibMcrypt_Ver}.tar.gz/download"
Mcrypt_URL="https://sourceforge.net/projects/mcrypt/files/MCrypt/2.6.8/${Mcypt_Ver}.tar.gz/download"
Mhash_URL="https://sourceforge.net/projects/mhash/files/mhash/0.9.9.9/${Mhash_Ver}.tar.bz2/download"
Freetype_URL="https://download.savannah.gnu.org/releases/freetype/${Freetype_Ver}.tar.bz2"
Freetype_New_URL="https://download.savannah.gnu.org/releases/freetype/${Freetype_New_Ver}.tar.xz"
Curl_URL="https://curl.se/download/${Curl_Ver}.tar.bz2"
Pcre_URL="https://sourceforge.net/projects/pcre/files/pcre/8.45/${Pcre_Ver}.tar.bz2/download"
Jemalloc_URL="https://github.com/jemalloc/jemalloc/releases/download/${Jemalloc_Ver#jemalloc-}/${Jemalloc_Ver}.tar.bz2"
TCMalloc_URL="https://github.com/gperftools/gperftools/releases/download/${TCMalloc_Ver}/${TCMalloc_Ver}.tar.gz"
Libunwind_URL="https://github.com/libunwind/libunwind/releases/download/v${Libunwind_Ver#libunwind-}/${Libunwind_Ver}.tar.gz"
Openssl_URL="https://www.openssl.org/source/${Openssl_Ver}.tar.gz"
Openssl_New_URL="https://www.openssl.org/source/${Openssl_New_Ver}.tar.gz"
Nghttp2_URL="https://github.com/nghttp2/nghttp2/releases/download/v${Nghttp2_Ver#nghttp2-}/${Nghttp2_Ver}.tar.xz"
Libzip_URL="https://libzip.org/download/${Libzip_Ver}.tar.xz"
Libicu4c_URL="https://github.com/unicode-org/icu/releases/download/release-${Libicu4c_Ver#icu4c-}/icu4c-${Libicu4c_Ver#icu4c-}-src.tgz"
Libicu4c_60_URL="https://github.com/unicode-org/icu/releases/download/release-60-3/icu4c-60_3-src.tgz"
Boost_URL="https://archives.boost.io/release/$(echo ${Boost_Ver} | sed 's/boost_//' | sed 's/_/./g')/source/${Boost_Ver}.tar.bz2"
Boost_New_URL="https://archives.boost.io/release/$(echo ${Boost_New_Ver} | sed 's/boost_//' | sed 's/_/./g')/source/${Boost_New_Ver}.tar.bz2"

# Official download URLs - web servers and modules
Nginx_URL="https://nginx.org/download/${Nginx_Ver}.tar.gz"
Luajit_URL="https://github.com/openresty/luajit2/archive/refs/tags/v${Luajit_Ver#luajit2-}.tar.gz"
LuaNginxModule_URL="https://github.com/openresty/lua-nginx-module/archive/v${LuaNginxModule#lua-nginx-module-}.tar.gz"
NgxDevelKit_URL="https://github.com/vision5/ngx_devel_kit/archive/v${NgxDevelKit#ngx_devel_kit-}.tar.gz"
LuaRestyCore_URL="https://github.com/openresty/lua-resty-core/archive/v${LuaRestyCore#lua-resty-core-}.tar.gz"
LuaRestyLrucache_URL="https://github.com/openresty/lua-resty-lrucache/archive/v${LuaRestyLrucache#lua-resty-lrucache-}.tar.gz"
NgxFancyIndex_URL="https://github.com/aperezdc/ngx-fancyindex/releases/download/v${NgxFancyIndex_Ver#ngx-fancyindex-}/${NgxFancyIndex_Ver}.tar.xz"

# Official download URLs - PHP
Php_URL="https://www.php.net/distributions/${Php_Ver}.tar.bz2"

# Official download URLs - Apache
APR_URL="https://downloads.apache.org/apr/${APR_Ver}.tar.bz2"
APR_Util_URL="https://downloads.apache.org/apr/${APR_Util_Ver}.tar.bz2"
if [ -n "${Apache_Ver}" ]; then
    Apache_URL="https://downloads.apache.org/httpd/${Apache_Ver}.tar.bz2"
fi

# Official download URLs - Database (source builds)
if [ -n "${Mysql_Ver}" ]; then
    Mysql_Ver_Short=$(echo ${Mysql_Ver} | sed 's/mysql-//' | cut -d. -f1-2)
    Mysql_Src_URL="https://cdn.mysql.com/Downloads/MySQL-${Mysql_Ver_Short}/${Mysql_Ver}.tar.gz"
fi

Pureftpd_Ver='pure-ftpd-1.0.49'
Pureftpd_URL="https://download.pureftpd.org/pub/pure-ftpd/releases/${Pureftpd_Ver}.tar.bz2"

# Legacy XCache (PHP 5.x only; PHP 5.x is no longer supported)
XCache_Ver='xcache-3.2.0'
ImageMagick_Ver='ImageMagick-7.1.1-8'
Imagick_Ver='imagick-3.7.0'
ZendOpcache_Ver='zendopcache-7.0.5'
Redis_Stable_Ver='redis-7.0.11'
PHPRedis_Ver='redis-5.3.7'
Memcached_Ver='memcached-1.6.15'
Libmemcached_Ver='libmemcached-1.0.18'
PHPMemcached_Ver='memcached-2.2.0'
PHP7Memcached_Ver='memcached-3.1.5'
PHP8Memcached_Ver='memcached-3.2.0'
PHPMemcache_Ver='memcache-3.0.8'
PHP7Memcache_Ver='memcache-4.0.5.2'
PHP8Memcache_Ver='memcache-8.2'
PHPOldApcu_Ver='apcu-4.0.11'
PHPNewApcu_Ver='apcu-5.1.22'
PHPApcu_Bc_Ver='apcu_bc-1.0.5'
PHPSodium_Ver='libsodium-2.0.23'
PHPSwoole_Ver='swoole-5.1.1'

# Official download URLs - PECL extensions and tools
XCache_URL="https://xcache.lighttpd.net/pub/Releases/3.2.0/${XCache_Ver}.tar.gz"
ImageMagick_URL="https://imagemagick.org/archive/${ImageMagick_Ver}.tar.xz"
Imagick_URL="https://pecl.php.net/get/${Imagick_Ver}.tgz"
ZendOpcache_URL="https://pecl.php.net/get/${ZendOpcache_Ver}.tgz"
PHPRedis_URL="https://pecl.php.net/get/${PHPRedis_Ver}.tgz"
Memcached_URL="https://github.com/memcached/memcached/releases/download/${Memcached_Ver#memcached-}/${Memcached_Ver}.tar.gz"
Libmemcached_URL="https://launchpad.net/libmemcached/1.0/${Libmemcached_Ver#libmemcached-}/+download/${Libmemcached_Ver}.tar.gz"
PHPMemcached_URL="https://pecl.php.net/get/${PHPMemcached_Ver}.tgz"
PHP7Memcached_URL="https://pecl.php.net/get/${PHP7Memcached_Ver}.tgz"
PHP8Memcached_URL="https://pecl.php.net/get/${PHP8Memcached_Ver}.tgz"
PHPMemcache_URL="https://pecl.php.net/get/${PHPMemcache_Ver}.tgz"
PHP7Memcache_URL="https://pecl.php.net/get/${PHP7Memcache_Ver}.tgz"
PHP8Memcache_URL="https://pecl.php.net/get/${PHP8Memcache_Ver}.tgz"
PHPOldApcu_URL="https://pecl.php.net/get/${PHPOldApcu_Ver}.tgz"
PHPNewApcu_URL="https://pecl.php.net/get/${PHPNewApcu_Ver}.tgz"
PHPApcu_Bc_URL="https://pecl.php.net/get/${PHPApcu_Bc_Ver}.tgz"
PHPSodium_URL="https://pecl.php.net/get/${PHPSodium_Ver}.tgz"
PHPSwoole_URL="https://pecl.php.net/get/${PHPSwoole_Ver}.tgz"
IonCube_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_\${ARCH}.tar.gz"
Fail2ban_URL="https://github.com/fail2ban/fail2ban/archive/refs/tags/1.0.3.tar.gz"
