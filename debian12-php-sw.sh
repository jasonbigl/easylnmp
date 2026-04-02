#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

if ! grep -qi 'debian' /etc/os-release 2>/dev/null; then
    echo "Error: This script only supports Debian."
    exit 1
fi

DEBIAN_VER=$(grep -oP 'VERSION_ID="\K[0-9]+' /etc/os-release 2>/dev/null)
if [ "${DEBIAN_VER}" != "12" ]; then
    echo "Error: This script requires Debian 12 (bookworm). Detected: ${DEBIAN_VER}"
    exit 1
fi

if ! uname -m | grep -qi 'aarch64'; then
    echo "Error: This script requires ARM64 (aarch64). Detected: $(uname -m)"
    exit 1
fi

cur_dir=$(pwd)
SRC_DIR="${cur_dir}/src"
mkdir -p "${SRC_DIR}"

# ============================================================
# Helper functions
# ============================================================

Color_Text()
{
    echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
    echo "$(Color_Text "$1" "31")"
}

Echo_Green()
{
    echo "$(Color_Text "$1" "32")"
}

Echo_Yellow()
{
    echo "$(Color_Text "$1" "33")"
}

Echo_Blue()
{
    echo "$(Color_Text "$1" "34")"
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    if [ -s "${SRC_DIR}/${FileName}" ]; then
        echo "${FileName} [found]"
    else
        echo "Downloading ${FileName} from ${URL} ..."
        wget --progress=dot -e dotbytes=20M --prefer-family=IPv4 -O "${SRC_DIR}/${FileName}" "${URL}"
        if [ $? -ne 0 ] || [ ! -s "${SRC_DIR}/${FileName}" ]; then
            rm -f "${SRC_DIR}/${FileName}"
            Echo_Red "Error: Failed to download ${FileName} from ${URL}"
            exit 1
        fi
    fi
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    local extension=${FileName##*.}
    cd "${SRC_DIR}"
    [[ -d "${DirName}" ]] && rm -rf "${DirName}"
    echo "Uncompress ${FileName}..."
    if [ "$extension" == "gz" ] || [ "$extension" == "tgz" ]; then
        tar zxf "${FileName}" || { Echo_Red "Error: Failed to extract ${FileName}"; exit 1; }
    elif [ "$extension" == "bz2" ]; then
        tar jxf "${FileName}" || { Echo_Red "Error: Failed to extract ${FileName}"; exit 1; }
    elif [ "$extension" == "xz" ]; then
        tar Jxf "${FileName}" || { Echo_Red "Error: Failed to extract ${FileName}"; exit 1; }
    else
        Echo_Red "Error: Unknown archive format: ${FileName}"
        exit 1
    fi
    if [ -n "${DirName}" ]; then
        cd "${DirName}"
    fi
}

Make_Install()
{
    make -j "$(nproc)"
    if [ $? -ne 0 ]; then
        make
    fi
    make install
}

# Idempotent: set a line in /etc/security/limits.conf
# Usage: Set_Limit "* soft nofile" "262140"
Set_Limit()
{
    local key="$1"
    local value="$2"
    local line="${key} ${value}"
    local escaped_key
    escaped_key=$(echo "${key}" | sed 's/\*/\\*/g')

    if grep -qP "^\s*${escaped_key}\s+" /etc/security/limits.conf 2>/dev/null; then
        local current
        current=$(grep -P "^\s*${escaped_key}\s+" /etc/security/limits.conf | awk '{print $NF}')
        if [ "${current}" = "${value}" ]; then
            echo "  limits.conf: ${line} [OK, already set]"
        else
            sed -i "s|^\s*${escaped_key}\s.*$|${line}|" /etc/security/limits.conf
            echo "  limits.conf: ${line} [UPDATED]"
        fi
    else
        echo "${line}" >> /etc/security/limits.conf
        echo "  limits.conf: ${line} [ADDED]"
    fi
}

# Idempotent: set a sysctl key in /etc/sysctl.d/99-swoole.conf
# Usage: Set_Sysctl "net.core.somaxconn" "65535"
Set_Sysctl()
{
    local key="$1"
    local value="$2"
    local conf="/etc/sysctl.d/99-swoole.conf"
    local escaped_key
    touch "${conf}"

    local current
    current=$(sysctl -n "${key}" 2>/dev/null | xargs)
    escaped_key=$(printf '%s' "${key}" | sed 's/[][\/.^$*+?(){}|]/\\&/g')

    if grep -qE "^[[:space:]]*${escaped_key}[[:space:]]*=" "${conf}" 2>/dev/null; then
        local file_val
        file_val=$(grep -E "^[[:space:]]*${escaped_key}[[:space:]]*=" "${conf}" | sed -n '1s/^[^=]*=[[:space:]]*//p' | xargs)
        if [ "${file_val}" = "${value}" ]; then
            echo "  sysctl ${key} = ${value} [OK, already set]"
        else
            sed -i -E "s|^[[:space:]]*${escaped_key}[[:space:]]*=.*|${key} = ${value}|" "${conf}"
            echo "  sysctl ${key} = ${value} [UPDATED from ${file_val}]"
        fi
    else
        echo "${key} = ${value}" >> "${conf}"
        if [ "${current}" = "${value}" ]; then
            echo "  sysctl ${key} = ${value} [ADDED to conf, runtime already correct]"
        else
            echo "  sysctl ${key} = ${value} [ADDED, was ${current}]"
        fi
    fi
}

# ============================================================
# Version variables and URLs
# ============================================================

PHP_VER='php-8.4.19'
SWOOLE_VER='swoole-6.1.7'
MAXMINDDB_PHP_VER='1.12.0'
OPENRESTY_VER='openresty-1.27.1.2'

PHP_URL="https://www.php.net/distributions/${PHP_VER}.tar.bz2"
SWOOLE_URL="https://pecl.php.net/get/${SWOOLE_VER}.tgz"
MAXMINDDB_URL="https://github.com/maxmind/MaxMind-DB-Reader-php/archive/refs/tags/v${MAXMINDDB_PHP_VER}.tar.gz"
OPENRESTY_URL="https://openresty.org/download/${OPENRESTY_VER}.tar.gz"
AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
CW_AGENT_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/debian/arm64/latest/amazon-cloudwatch-agent.deb"

TIMEZONE='UTC'

exec > >(tee /root/setup-install.log) 2>&1

clear
echo "+------------------------------------------------------------------------+"
echo "|   Debian 12 ARM64 Setup Script                                         |"
echo "|   PHP ${PHP_VER} | Swoole ${SWOOLE_VER} | OpenResty                    |"
echo "+------------------------------------------------------------------------+"
echo ""

# ============================================================
# Step 1: Create Swap (size = physical memory, swappiness = 1)
# ============================================================

Echo_Blue "[+] Step 1: Configuring Swap..."

MEM_BYTES=$(free -b | awk '/^Mem:/{print $2}')
MEM_MB=$((MEM_BYTES / 1024 / 1024))

CURRENT_SWAP=$(swapon --show=SIZE --noheadings --bytes 2>/dev/null | awk '{s+=$1}END{print s+0}')

NEED_SWAP='n'
if [ "${CURRENT_SWAP}" -gt 0 ] 2>/dev/null; then
    CURRENT_SWAP_MB=$((CURRENT_SWAP / 1024 / 1024))
    Echo_Yellow "  Swap already exists: ${CURRENT_SWAP_MB}MB (target: ${MEM_MB}MB)"
    if [ "${CURRENT_SWAP_MB}" -ge "${MEM_MB}" ]; then
        Echo_Green "  Swap size is sufficient, skipping creation."
    else
        Echo_Yellow "  Existing swap is smaller than memory, creating new swap..."
        NEED_SWAP='y'
    fi
else
    Echo_Yellow "  No swap detected, creating ${MEM_MB}MB swap..."
    NEED_SWAP='y'
fi

if [ "${NEED_SWAP}" = "y" ]; then
    if [ -f /swapfile ]; then
        swapoff /swapfile 2>/dev/null
        rm -f /swapfile
    fi
    fallocate -l "${MEM_BYTES}" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo "  /etc/fstab: swap entry [ADDED]"
    else
        echo "  /etc/fstab: swap entry [OK, already set]"
    fi
    Echo_Green "  Swap created: ${MEM_MB}MB"
fi

CURRENT_SWAPPINESS=$(sysctl -n vm.swappiness 2>/dev/null)
if [ "${CURRENT_SWAPPINESS}" != "1" ]; then
    sysctl -w vm.swappiness=1 >/dev/null
    echo "  vm.swappiness = 1 [UPDATED from ${CURRENT_SWAPPINESS}]"
else
    echo "  vm.swappiness = 1 [OK, already set]"
fi

# ============================================================
# Step 2: Install apt dependencies
# ============================================================

Echo_Blue "[+] Step 2: Installing apt dependencies..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get --no-install-recommends install -y \
    build-essential gcc g++ make cmake autoconf automake re2c wget cron \
    bzip2 libzip-dev libc6-dev bison file flex m4 gawk less cpp binutils \
    diffutils unzip tar libbz2-dev libtool libevent-dev openssl libssl-dev \
    libsasl2-dev libltdl-dev zlib1g zlib1g-dev libglib2.0-0 \
    libglib2.0-dev libjpeg-dev libpng-dev libkrb5-dev curl \
    libcurl4-openssl-dev libpcre3-dev libpq-dev gettext libxml2-dev \
    libcap-dev ca-certificates psmisc patch git libc-ares-dev libicu-dev \
    e2fsprogs libxslt1.1 libxslt1-dev xz-utils libexpat1-dev libaio-dev \
    libtirpc-dev libsqlite3-dev libonig-dev lsof pkg-config libwebp-dev \
    iproute2 gzip libncurses-dev libtinfo-dev libpcre2-dev \
    libmaxminddb-dev libfreetype-dev supervisor

# ============================================================
# Step 3: ARM64 library symlinks
# ============================================================

Echo_Blue "[+] Step 3: Setting up ARM64 library symlinks..."

if [ -d /usr/lib/aarch64-linux-gnu ]; then
    ln -sf /usr/lib/aarch64-linux-gnu/libpng*.so /usr/lib/ 2>/dev/null
    ln -sf /usr/lib/aarch64-linux-gnu/libpng*.a /usr/lib/ 2>/dev/null
    ln -sf /usr/lib/aarch64-linux-gnu/libjpeg*.so /usr/lib/ 2>/dev/null
    ln -sf /usr/lib/aarch64-linux-gnu/libjpeg*.a /usr/lib/ 2>/dev/null
fi
if [ -d /usr/include/aarch64-linux-gnu/curl ]; then
    ln -sf /usr/include/aarch64-linux-gnu/curl /usr/include/curl 2>/dev/null
fi

# ============================================================
# Step 4: Build PHP 8.4.19 (CLI only)
# ============================================================

Echo_Blue "[+] Step 4: Building ${PHP_VER} (CLI only)..."

Download_Files "${PHP_URL}" "${PHP_VER}.tar.bz2"
Tar_Cd "${PHP_VER}.tar.bz2" "${PHP_VER}"

./configure \
    --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    --enable-mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-iconv \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-zlib \
    --enable-xml \
    --disable-rpath \
    --enable-bcmath \
    --enable-shmop \
    --enable-sysvsem \
    --with-curl \
    --enable-mbregex \
    --enable-mbstring \
    --enable-intl \
    --enable-pcntl \
    --enable-ftp \
    --enable-gd \
    --with-openssl \
    --with-mhash \
    --enable-sockets \
    --with-zip \
    --enable-soap \
    --with-gettext \
    --enable-fileinfo \
    --enable-opcache \
    --with-xsl \
    --with-pear

if [ $? -ne 0 ]; then
    Echo_Red "Error: PHP configure failed!"
    exit 1
fi

make ZEND_EXTRA_LIBS='-liconv' -j "$(nproc)"
if [ $? -ne 0 ]; then
    make ZEND_EXTRA_LIBS='-liconv'
fi
make install

mkdir -p /usr/local/php/{etc,conf.d}
\cp php.ini-production /usr/local/php/etc/php.ini

sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php/etc/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php/etc/php.ini
sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|g" /usr/local/php/etc/php.ini
sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php/etc/php.ini
sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php/etc/php.ini

ln -sf /usr/local/php/bin/php /usr/local/bin/php
ln -sf /usr/local/php/bin/phpize /usr/local/bin/phpize
ln -sf /usr/local/php/bin/php-config /usr/local/bin/php-config
ln -sf /usr/local/php/bin/pecl /usr/local/bin/pecl
ln -sf /usr/local/php/bin/pear /usr/local/bin/pear

Echo_Green "  ${PHP_VER} installed to /usr/local/php"

# ============================================================
# Step 5: Install Composer
# ============================================================

Echo_Blue "[+] Step 5: Installing Composer..."

cd "${SRC_DIR}"
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "${EXPECTED_CHECKSUM}" != "${ACTUAL_CHECKSUM}" ]; then
    Echo_Red "Error: Composer installer signature mismatch!"
    rm -f composer-setup.php
    exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php

if [ -x /usr/local/bin/composer ]; then
    Echo_Green "  Composer installed: $(composer --version 2>/dev/null)"
else
    Echo_Red "  Composer install failed!"
fi

# ============================================================
# Step 6: Build Swoole 6.1.7 (PHP extension)
# ============================================================

Echo_Blue "[+] Step 6: Building ${SWOOLE_VER} PHP extension..."

EXT_DIR=$(/usr/local/php/bin/php-config --extension-dir)

Download_Files "${SWOOLE_URL}" "${SWOOLE_VER}.tgz"
Tar_Cd "${SWOOLE_VER}.tgz" "${SWOOLE_VER}"

/usr/local/php/bin/phpize
./configure \
    --with-php-config=/usr/local/php/bin/php-config \
    --enable-openssl \
    --enable-http2 \
    --enable-swoole-curl \
    --enable-swoole-json

if [ $? -ne 0 ]; then
    Echo_Red "Error: Swoole configure failed!"
    exit 1
fi

make -j "$(nproc)" && make install

cat > /usr/local/php/conf.d/009-swoole.ini <<EOF
extension = "swoole.so"
EOF

cd "${SRC_DIR}"
rm -rf "${SWOOLE_VER}"

if [ -s "${EXT_DIR}/swoole.so" ]; then
    Echo_Green "  Swoole installed successfully."
else
    Echo_Red "  Swoole install failed!"
fi

# ============================================================
# Step 7: Build maxminddb PHP extension
# ============================================================

Echo_Blue "[+] Step 7: Building maxminddb PHP extension..."

MAXMINDDB_TARBALL="MaxMind-DB-Reader-php-${MAXMINDDB_PHP_VER}.tar.gz"
MAXMINDDB_DIR="MaxMind-DB-Reader-php-${MAXMINDDB_PHP_VER}"

Download_Files "${MAXMINDDB_URL}" "${MAXMINDDB_TARBALL}"
Tar_Cd "${MAXMINDDB_TARBALL}" "${MAXMINDDB_DIR}"

cd ext

/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config

if [ $? -ne 0 ]; then
    Echo_Red "Error: maxminddb configure failed!"
    exit 1
fi

make -j "$(nproc)" && make install

cat > /usr/local/php/conf.d/010-maxminddb.ini <<EOF
extension = "maxminddb.so"
EOF

cd "${SRC_DIR}"
rm -rf "${MAXMINDDB_DIR}"

if [ -s "${EXT_DIR}/maxminddb.so" ]; then
    Echo_Green "  maxminddb extension installed successfully."
else
    Echo_Red "  maxminddb extension install failed!"
fi

# ============================================================
# Step 8: Supervisor (installed via apt in step 2)
# ============================================================

Echo_Blue "[+] Step 8: Enabling Supervisor..."

systemctl enable supervisor 2>/dev/null
systemctl start supervisor 2>/dev/null

if systemctl is-active --quiet supervisor; then
    Echo_Green "  Supervisor is running."
else
    Echo_Yellow "  Supervisor installed but not active (may need reboot or manual start)."
fi

# ============================================================
# Step 9: Install AWS CLI v2
# ============================================================

Echo_Blue "[+] Step 9: Installing AWS CLI v2..."

cd "${SRC_DIR}"
Download_Files "${AWSCLI_URL}" "awscli-exe-linux-aarch64.zip"
rm -rf "${SRC_DIR}/aws"
unzip -qo "${SRC_DIR}/awscli-exe-linux-aarch64.zip" -d "${SRC_DIR}"

if [ -x /usr/local/bin/aws ]; then
    "${SRC_DIR}/aws/install" --update
else
    "${SRC_DIR}/aws/install"
fi
rm -rf "${SRC_DIR}/aws"

if command -v aws >/dev/null 2>&1; then
    Echo_Green "  AWS CLI installed: $(aws --version 2>&1)"
else
    Echo_Red "  AWS CLI install failed!"
fi

# ============================================================
# Step 10: Install amazon-cloudwatch-agent
# ============================================================

Echo_Blue "[+] Step 10: Installing amazon-cloudwatch-agent..."

Download_Files "${CW_AGENT_URL}" "amazon-cloudwatch-agent.deb"
dpkg -i "${SRC_DIR}/amazon-cloudwatch-agent.deb"

if [ -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then
    Echo_Green "  amazon-cloudwatch-agent installed."
else
    Echo_Red "  amazon-cloudwatch-agent install failed!"
fi

# ============================================================
# Step 11: Build OpenResty from source
# ============================================================

Echo_Blue "[+] Step 11: Building ${OPENRESTY_VER}..."

Download_Files "${OPENRESTY_URL}" "${OPENRESTY_VER}.tar.gz"
Tar_Cd "${OPENRESTY_VER}.tar.gz" "${OPENRESTY_VER}"

./configure \
    --prefix=/usr/local/openresty \
    --with-pcre-jit \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    -j"$(nproc)"

if [ $? -ne 0 ]; then
    Echo_Red "Error: OpenResty configure failed!"
    exit 1
fi

make -j "$(nproc)"
if [ $? -ne 0 ]; then
    make
fi
make install

cd "${SRC_DIR}"
rm -rf "${OPENRESTY_VER}"

cat > /etc/systemd/system/openresty.service <<'EOF'
[Unit]
Description=OpenResty - Full-Featured Web Platform Based on Nginx and LuaJIT
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/usr/local/openresty/nginx/logs/nginx.pid
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t -q
ExecStart=/usr/local/openresty/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openresty 2>/dev/null

if [ -x /usr/local/openresty/nginx/sbin/nginx ]; then
    Echo_Green "  OpenResty installed to /usr/local/openresty"
else
    Echo_Red "  OpenResty install failed!"
fi

# ============================================================
# Step 12: System kernel parameter tuning (Swoole official)
# ============================================================

Echo_Blue "[+] Step 12: Tuning system kernel parameters..."

echo "  --- /etc/security/limits.conf ---"
Set_Limit "* soft nofile" "262140"
Set_Limit "* hard nofile" "262140"
Set_Limit "root soft nofile" "262140"
Set_Limit "root hard nofile" "262140"
Set_Limit "* soft core" "unlimited"
Set_Limit "* hard core" "unlimited"
Set_Limit "root soft core" "unlimited"
Set_Limit "root hard core" "unlimited"

echo "  --- /etc/sysctl.d/99-swoole.conf ---"

Set_Sysctl "net.unix.max_dgram_qlen" "100"

Set_Sysctl "net.ipv4.tcp_mem" "379008 505344 758016"
Set_Sysctl "net.ipv4.tcp_wmem" "4096 16384 4194304"
Set_Sysctl "net.ipv4.tcp_rmem" "4096 87380 4194304"
Set_Sysctl "net.core.wmem_default" "8388608"
Set_Sysctl "net.core.rmem_default" "8388608"
Set_Sysctl "net.core.rmem_max" "16777216"
Set_Sysctl "net.core.wmem_max" "16777216"

Set_Sysctl "net.ipv4.tcp_tw_reuse" "1"
Set_Sysctl "net.ipv4.tcp_syncookies" "1"
Set_Sysctl "net.ipv4.tcp_fin_timeout" "30"
Set_Sysctl "net.ipv4.tcp_keepalive_time" "300"
Set_Sysctl "net.ipv4.ip_local_port_range" "20000 65000"

Set_Sysctl "net.ipv4.tcp_max_syn_backlog" "81920"
Set_Sysctl "net.ipv4.tcp_synack_retries" "3"
Set_Sysctl "net.ipv4.tcp_syn_retries" "3"
Set_Sysctl "net.ipv4.tcp_max_tw_buckets" "200000"
Set_Sysctl "net.core.somaxconn" "65535"
Set_Sysctl "net.core.netdev_max_backlog" "30000"

Set_Sysctl "fs.file-max" "6815744"
Set_Sysctl "net.ipv4.route.max_size" "5242880"

Set_Sysctl "kernel.msgmnb" "4203520"
Set_Sysctl "kernel.msgmni" "64"
Set_Sysctl "kernel.msgmax" "8192"

mkdir -p /tmp/core_files
TARGET_CORE_PATTERN="/tmp/core_files/core-%e-%p-%t"
CURRENT_CORE_PATTERN=$(sysctl -n kernel.core_pattern 2>/dev/null)
if [ "${CURRENT_CORE_PATTERN}" = "${TARGET_CORE_PATTERN}" ]; then
    echo "  kernel.core_pattern [OK, already set]"
else
    Set_Sysctl "kernel.core_pattern" "${TARGET_CORE_PATTERN}"
fi

echo "  Applying sysctl settings..."
sysctl --system >/dev/null 2>&1
Echo_Green "  Kernel parameters tuned."

# ============================================================
# Step 13: Installation summary
# ============================================================

echo ""
echo "+------------------------------------------------------------------------+"
echo "|                    Installation Summary                                |"
echo "+------------------------------------------------------------------------+"

check_result()
{
    local name="$1"
    local check="$2"
    if eval "${check}"; then
        Echo_Green "  [PASS] ${name}"
    else
        Echo_Red "  [FAIL] ${name}"
    fi
}

check_result "PHP ${PHP_VER}" \
    "[ -x /usr/local/php/bin/php ]"
check_result "Composer" \
    "[ -x /usr/local/bin/composer ]"
check_result "Swoole ${SWOOLE_VER}" \
    "[ -s \$(/usr/local/php/bin/php-config --extension-dir 2>/dev/null)/swoole.so ]"
check_result "maxminddb extension" \
    "[ -s \$(/usr/local/php/bin/php-config --extension-dir 2>/dev/null)/maxminddb.so ]"
check_result "Supervisor" \
    "command -v supervisord >/dev/null 2>&1"
check_result "AWS CLI v2" \
    "command -v aws >/dev/null 2>&1"
check_result "CloudWatch Agent" \
    "[ -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]"
check_result "OpenResty" \
    "[ -x /usr/local/openresty/nginx/sbin/nginx ]"
check_result "Swap" \
    "[ \$(swapon --show --noheadings | wc -l) -gt 0 ]"
check_result "vm.swappiness=1" \
    "[ \$(sysctl -n vm.swappiness) = '1' ]"

echo ""
echo "PHP version:"
/usr/local/php/bin/php -v 2>/dev/null
echo ""
echo "PHP modules:"
/usr/local/php/bin/php -m 2>/dev/null
echo ""
echo "+------------------------------------------------------------------------+"
Echo_Green "All done! Log: /root/setup-install.log"
echo "+------------------------------------------------------------------------+"
