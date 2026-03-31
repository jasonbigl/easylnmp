#!/usr/bin/env bash

Nginx_Dependent()
{
    if [ "$PM" = "yum" ]; then
        rpm -e httpd httpd-tools --nodeps
        yum -y remove httpd*
        for packages in make gcc gcc-c++ gcc-g77 wget crontabs zlib zlib-devel openssl openssl-devel perl patch bzip2 initscripts xz gzip;
        do yum -y install $packages; done
        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi
    elif [ "$PM" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        dpkg -P apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-common
        for removepackages in apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker;
        do apt-get purge -y $removepackages; done
        for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make autoconf automake wget cron openssl libssl-dev zlib1g zlib1g-dev bzip2 xz-utils gzip;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

Install_Only_Nginx()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|                     Install Nginx                                     |"
    echo "+-----------------------------------------------------------------------+"
    echo "|                     A tool to only install Nginx.                     |"
    echo "+-----------------------------------------------------------------------+"
    Nginx_Selection
    Press_Install
    Echo_Blue "Install dependent packages..."
    cd ${cur_dir}/src
    Get_Dist_Version
    Modify_Source
    Nginx_Dependent
    cd ${cur_dir}/src
    Download_Files ${Pcre_URL} ${Pcre_Ver}.tar.bz2
    Install_Pcre
    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi
    ldconfig
    Download_Files ${Nginx_URL} ${Nginx_Ver}.tar.gz
    Install_Nginx
    StartUp nginx
    rm -rf ${cur_dir}/src/${Nginx_Ver}
    [[ -d "${cur_dir}/src/${Openssl_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_Ver}
    [[ -d "${cur_dir}/src/${Openssl_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_New_Ver}
    StartOrStop start nginx
    Add_Iptables_Rules
    \cp ${cur_dir}/conf/index.html ${Default_Website_Dir}/index.html
    \cp ${cur_dir}/conf/lnmp /bin/lnmp
    Check_Nginx_Files
}

DB_Dependent()
{
    if [ "$PM" = "yum" ]; then
        yum -y remove mysql-server mysql mysql-libs mariadb-server mariadb mariadb-libs
        rpm -qa|grep mysql
        if [ $? -ne 0 ]; then
            rpm -e mysql mysql-libs --nodeps
            rpm -e mariadb mariadb-libs --nodeps
        fi
        for packages in make cmake gcc gcc-c++ gcc-g77 flex bison wget zlib zlib-devel openssl openssl-devel ncurses ncurses-devel libaio-devel rpcgen libtirpc-devel patch cyrus-sasl-devel pkg-config pcre-devel libxml2-devel hostname ncurses-libs numactl-devel libxcrypt gnutls-devel initscripts libxcrypt-compat perl xz gzip;
        do yum -y install $packages; done
        if echo "${CentOS_Version}" | grep -Eqi "^8" || echo "${RHEL_Version}" | grep -Eqi "^8" || echo "${Rocky_Version}" | grep -Eqi "^8" || echo "${Alma_Version}" | grep -Eqi "^8"; then
            Check_PowerTools
            dnf --enablerepo=${repo_id} install rpcgen -y
            dnf install libarchive -y

            dnf install gcc-toolset-10 -y
        fi

        if [ "${DISTRO}" = "Oracle" ] && echo "${Oracle_Version}" | grep -Eqi "^8"; then
            Check_Codeready
            dnf --enablerepo=${repo_id} install rpcgen re2c -y
            dnf install libarchive -y
        fi

        if [ "${DISTRO}" = "Oracle" ] && echo "${Oracle_Version}" | grep -Eqi "^9"; then
            Check_Codeready
            dnf --enablerepo=${repo_id} install libtirpc-devel -y
            if [[ "${Bin}" != "y" && "${DBSelect}" = "5" ]]; then
                dnf install gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc -y
            fi
        fi

        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi

        if echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
            dnf --enablerepo=crb install libtirpc-devel libxcrypt-compat -y
            if [[ "${Bin}" != "y" && "${DBSelect}" = "5" ]]; then
                dnf install gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc -y
            fi
        fi

        if [ -s /usr/lib64/libtinfo.so.6 ]; then
            ln -sf /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5
        elif [ -s /usr/lib/libtinfo.so.6 ]; then
            ln -sf /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5
        fi

        if [ -s /usr/lib64/libncurses.so.6 ]; then
            ln -sf /usr/lib64/libncurses.so.6 /usr/lib64/libncurses.so.5
        elif [ -s /usr/lib/libncurses.so.6 ]; then
            ln -sf /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5
        fi
    elif [ "$PM" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        for removepackages in mysql-client mysql-server mysql-common mysql-server-core-5.5 mysql-client-5.5 mariadb-client mariadb-server mariadb-common;
        do apt-get purge -y $removepackages; done
        dpkg -l |grep mysql
        dpkg -P mysql-server mysql-common libmysqlclient15off libmysqlclient15-dev
        dpkg -P mariadb-client mariadb-server mariadb-common
        for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake wget openssl libssl-dev zlib1g zlib1g-dev libncurses5 libncurses5-dev bison libaio-dev libtirpc-dev libsasl2-dev pkg-config libpcre2-dev libxml2-dev libtinfo-dev libnuma-dev gnutls-dev xz-utils gzip;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

Install_Database()
{
    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        if [[ "${Bin}" = "y" && "${DBSelect}" =~ ^[2-4]$ ]]; then
            Mysql_Ver_Short=$(echo ${Mysql_Ver} | sed 's/mysql-//' | cut -d. -f1-2)
            Download_Files https://cdn.mysql.com/Downloads/MySQL-${Mysql_Ver_Short}/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz
            [[ $? -ne 0 ]] && Download_Files https://cdn.mysql.com/archives/mysql-${Mysql_Ver_Short}/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz
            if [ ! -s ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ]; then
                Echo_Red "Error! Unable to download MySQL ${Mysql_Ver_Short} Generic Binaries, please download it to src directory manually."
                sleep 5
                exit 1
            fi
        elif [[ "${Bin}" = "y" && "${DBSelect}" = "5" ]]; then
            [[ "${DB_ARCH}" = "aarch64" ]] && mysql8_glibc_ver="2.17" || mysql8_glibc_ver="2.12"
            Download_Files https://cdn.mysql.com/Downloads/MySQL-8.0/${Mysql_Ver}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz
            [[ $? -ne 0 ]] && Download_Files https://cdn.mysql.com/archives/mysql-8.0/${Mysql_Ver}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz
            if [ ! -s ${Mysql_Ver}-linux-glibc${mysql8_glibc_ver}-${DB_ARCH}.tar.xz ]; then
                Echo_Red "Error! Unable to download MySQL 8.0 Generic Binaries, please download it to src directory manually."
                sleep 5
                exit 1
            fi
        elif [[ "${Bin}" = "y" && "${DBSelect}" = "11" ]]; then
            Download_Files https://cdn.mysql.com/Downloads/MySQL-8.4/${Mysql_Ver}-linux-glibc2.17-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc2.17-${DB_ARCH}.tar.xz
            [[ $? -ne 0 ]] && Download_Files https://cdn.mysql.com/archives/mysql-8.4/${Mysql_Ver}-linux-glibc2.17-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc2.17-${DB_ARCH}.tar.xz
            if [ ! -s ${Mysql_Ver}-linux-glibc2.17-${DB_ARCH}.tar.xz ]; then
                Echo_Red "Error! Unable to download MySQL 8.4 Generic Binaries, please download it to src directory manually."
                sleep 5
                exit 1
            fi
        else
            Download_Files ${Mysql_Src_URL} ${Mysql_Ver}.tar.gz
            if [ ! -s ${Mysql_Ver}.tar.gz ]; then
                Echo_Red "Error! Unable to download MySQL source code, please download it to src directory manually."
                sleep 5
                exit 1
            fi
        fi
    elif [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        Mariadb_Version=$(echo ${Mariadb_Ver} | cut -d- -f2)
        if [ "${Bin}" = "y" ]; then
            MariaDB_FileName="${Mariadb_Ver}-linux-systemd-${DB_ARCH}"
        else
            MariaDB_FileName="${Mariadb_Ver}"
        fi
        Download_Files https://downloads.mariadb.org/rest-api/mariadb/${Mariadb_Version}/${MariaDB_FileName}.tar.gz ${MariaDB_FileName}.tar.gz
        if [ ! -s ${MariaDB_FileName}.tar.gz ]; then
            Echo_Red "Error! Unable to download MariaDB, please download it to src directory manually."
            sleep 5
            exit 1
        fi
    fi
    echo "============================check files=================================="

    Echo_Blue "Install dependent packages..."
    Get_Dist_Version
    Modify_Source
    DB_Dependent
    Check_Openssl
    if [ "${DBSelect}" = "1" ]; then
        Install_MySQL_51
    elif [ "${DBSelect}" = "2" ]; then
        Install_MySQL_55
    elif [ "${DBSelect}" = "3" ]; then
        Install_MySQL_56
    elif [ "${DBSelect}" = "4" ]; then
        Install_MySQL_57
    elif [ "${DBSelect}" = "5" ]; then
        Install_MySQL_80
    elif [ "${DBSelect}" = "6" ]; then
        Install_MariaDB_5
    elif [ "${DBSelect}" = "7" ]; then
        Install_MariaDB_104
    elif [ "${DBSelect}" = "8" ]; then
        Install_MariaDB_105
    elif [ "${DBSelect}" = "9" ]; then
        Install_MariaDB_106
    elif [ "${DBSelect}" = "10" ]; then
        Install_MariaDB_1011
    elif [ "${DBSelect}" = "11" ]; then
        Install_MySQL_84
    fi
    TempMycnf_Clean

    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    fi

    Clean_DB_Src_Dir
    Check_DB_Files
    if [[ "${isDB}" = "ok" ]]; then
        if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
            Echo_Green "MySQL root password: ${DB_Root_Password}"
            Echo_Green "Install ${Mysql_Ver} completed! enjoy it."
        elif [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
            Echo_Green "MariaDB root password: ${DB_Root_Password}"
            Echo_Green "Install ${Mariadb_Ver} completed! enjoy it."
        fi
    fi
}

PHP_Dependent()
{
    if [ "$PM" = "yum" ]; then
        for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf automake re2c wget patch \
            libjpeg libjpeg-devel libjpeg-turbo-devel libpng libpng-devel gd gd-devel \
            libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel \
            openssl openssl-devel curl curl-devel libcurl libcurl-devel \
            e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel \
            pcre-devel gettext gettext-devel gmp-devel pspell-devel libcap \
            libXpm-devel c-ares-devel libicu-devel libxslt libxslt-devel \
            sqlite-devel oniguruma-devel libwebp-devel libzip-devel \
            diffutils ca-certificates net-tools psmisc xz expat-devel \
            lsof pkg-config iproute gnutls-devel;
        do yum -y install $packages; done
        if echo "${CentOS_Version}" | grep -Eqi "^8" || echo "${RHEL_Version}" | grep -Eqi "^8" || echo "${Rocky_Version}" | grep -Eqi "^8" || echo "${Alma_Version}" | grep -Eqi "^8"; then
            Check_PowerTools
            if [ "${repo_id}" != "" ]; then
                for c8packages in rpcgen re2c oniguruma-devel;
                do dnf --enablerepo=${repo_id} install ${c8packages} -y; done
            fi
        fi
        if echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
            dnf --enablerepo=crb install oniguruma-devel libxcrypt-compat -y
        fi
        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi
    elif [ "$PM" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        apt-get autoremove -y
        apt-get -fy install
        local deb_packages="build-essential gcc g++ make cmake autoconf automake re2c wget bzip2 patch \
            libjpeg-dev libpng-dev libwebp-dev libglib2.0-dev libxml2-dev \
            zlib1g zlib1g-dev libbz2-dev openssl libssl-dev libsasl2-dev \
            curl libcurl4-openssl-dev libpcre3-dev libkrb5-dev gettext \
            libxslt1-dev libsqlite3-dev libonig-dev libzip-dev libcap-dev \
            ca-certificates psmisc libicu-dev libc-ares-dev e2fsprogs \
            xz-utils libexpat1-dev libtool libevent-dev libc6-dev \
            m4 flex bison file gawk diffutils unzip tar lsof pkg-config \
            git-core iproute2 gzip libgd-dev libXpm-dev gnutls-dev"
        if [[ "${Debian_Version}" -ge 11 ]] 2>/dev/null || echo "${Ubuntu_Version}" | grep -Eqi "^2[0-9]\."; then
            deb_packages="${deb_packages} libncurses-dev libtinfo-dev"
        else
            deb_packages="${deb_packages} libncurses5 libncurses5-dev libtinfo-dev"
        fi
        for packages in ${deb_packages}; do
            apt-get --no-install-recommends install -y $packages
        done
    fi
}

Install_Only_Database()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|           Install MySQL/MariaDB database                               |"
    echo "+-----------------------------------------------------------------------+"
    echo "|               A tool to install MySQL/MariaDB                         |"
    echo "+-----------------------------------------------------------------------+"

    Get_Dist_Name
    Check_DB
    if [ "${DB_Name}" != "None" ]; then
        echo "You have install ${DB_Name}!"
        exit 1
    fi

    Database_Selection
    if [ "${DBSelect}" = "0" ]; then
        echo "DO NOT Install MySQL or MariaDB."
        exit 1
    fi
    Echo_Red "The script will REMOVE MySQL/MariaDB installed via yum or apt-get and it's databases!!!"
    Press_Install
    Install_Database 2>&1 | tee /root/install_database.log
}

Install_Only_PHP()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|              Install PHP + PHP-FPM                                    |"
    echo "+-----------------------------------------------------------------------+"
    echo "|           A tool to only install PHP with PHP-FPM support.            |"
    echo "+-----------------------------------------------------------------------+"

    if [ -s /usr/local/php/bin/php ]; then
        Echo_Red "PHP is already installed!"
        /usr/local/php/bin/php -v
        exit 1
    fi

    PHP_Selection
    Press_Install

    Get_Dist_Version
    Print_Sys_Info
    Set_Timezone

    Echo_Blue "Install dependent packages..."
    if [ "${CheckMirror}" != "n" ]; then
        Modify_Source
    fi
    PHP_Dependent

    if [ "$PM" = "yum" ]; then
        CentOS_Lib_Opt
    elif [ "$PM" = "apt" ]; then
        Deb_Lib_Opt
    fi

    cd ${cur_dir}/src
    Download_Files ${Libiconv_URL} ${Libiconv_Ver}.tar.gz
    Download_Files ${LibMcrypt_URL} ${LibMcrypt_Ver}.tar.gz
    Download_Files ${Mcrypt_URL} ${Mcypt_Ver}.tar.gz
    Download_Files ${Mhash_URL} ${Mhash_Ver}.tar.bz2
    Download_Files ${Php_URL} ${Php_Ver}.tar.bz2

    Install_Libiconv
    Install_Libmcrypt
    Install_Mhash
    Install_Mcrypt
    Install_Freetype
    Install_Pcre
    Install_Icu4c

    Check_Openssl

    if [ `grep -L '/usr/local/lib' '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi
    ldconfig

    groupadd www 2>/dev/null
    useradd -s /sbin/nologin -g www www 2>/dev/null

    Stack="lnmp"
    Check_PHP_Option
    Install_PHP

    LNMP_PHP_Opt
    StartUp php-fpm
    StartOrStop start php-fpm
    Clean_PHP_Src_Dir

    echo "============================PHP Install Check=============================="
    Check_PHP_Files
    if [ "${isPHP}" = "ok" ]; then
        Echo_Green "PHP ${Php_Ver} with PHP-FPM installed successfully!"
        Echo_Green "PHP binary: /usr/local/php/bin/php"
        Echo_Green "PHP-FPM binary: /usr/local/php/sbin/php-fpm"
        Echo_Green "PHP config: /usr/local/php/etc/php.ini"
        Echo_Green "PHP-FPM config: /usr/local/php/etc/php-fpm.conf"
    else
        Echo_Red "PHP install failed!"
    fi
}

Install_Only_PHP_CLI()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|                Install PHP CLI Only                                   |"
    echo "+-----------------------------------------------------------------------+"
    echo "|         A tool to only install PHP CLI (without PHP-FPM).             |"
    echo "+-----------------------------------------------------------------------+"

    if [ -s /usr/local/php/bin/php ]; then
        Echo_Red "PHP is already installed!"
        /usr/local/php/bin/php -v
        exit 1
    fi

    PHP_Selection
    Press_Install

    Get_Dist_Version
    Print_Sys_Info
    Set_Timezone

    Echo_Blue "Install dependent packages..."
    if [ "${CheckMirror}" != "n" ]; then
        Modify_Source
    fi
    PHP_Dependent

    if [ "$PM" = "yum" ]; then
        CentOS_Lib_Opt
    elif [ "$PM" = "apt" ]; then
        Deb_Lib_Opt
    fi

    cd ${cur_dir}/src
    Download_Files ${Libiconv_URL} ${Libiconv_Ver}.tar.gz
    Download_Files ${LibMcrypt_URL} ${LibMcrypt_Ver}.tar.gz
    Download_Files ${Mcrypt_URL} ${Mcypt_Ver}.tar.gz
    Download_Files ${Mhash_URL} ${Mhash_Ver}.tar.bz2
    Download_Files ${Php_URL} ${Php_Ver}.tar.bz2

    Install_Libiconv
    Install_Libmcrypt
    Install_Mhash
    Install_Mcrypt
    Install_Freetype
    Install_Pcre
    Install_Icu4c

    Check_Openssl

    if [ `grep -L '/usr/local/lib' '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi
    ldconfig

    Stack="lnmp"
    Check_PHP_Option
    Install_PHP

    Clean_PHP_Src_Dir

    echo "============================PHP Install Check=============================="
    if [[ -s /usr/local/php/bin/php && -s /usr/local/php/etc/php.ini ]]; then
        Echo_Green "PHP: OK"
        Echo_Green "PHP ${Php_Ver} CLI installed successfully!"
        Echo_Green "PHP binary: /usr/local/php/bin/php"
        Echo_Green "PHP config: /usr/local/php/etc/php.ini"
    else
        Echo_Red "PHP install failed!"
    fi
}
