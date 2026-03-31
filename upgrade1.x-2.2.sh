#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cur_dir=$(pwd)
isSSL=$1

. lnmp.conf
. include/main.sh
. include/init.sh

Get_Dist_Name
Check_Stack
Check_DB

Upgrade_Dependent()
{
    if [ "$PM" = "yum" ]; then
        Echo_Blue "[+] Yum installing dependent packages..."
        Get_Dist_Version
        for packages in patch wget crontabs unzip tar ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel bzip2 bzip2-devel libaio-devel rpcgen libtirpc-devel perl cyrus-sasl-devel sqlite-devel oniguruma-devel re2c pkg-config libarchive hostname ncurses-libs numactl-devel libxcrypt libwebp-devel gnutls-devel initscripts iproute libxcrypt-compat;
        do yum -y install $packages; done
        yum -y update nss

        if echo "${CentOS_Version}" | grep -Eqi "^8" || echo "${RHEL_Version}" | grep -Eqi "^8" || echo "${Rocky_Version}" | grep -Eqi "^8" || echo "${Alma_Version}" | grep -Eqi "^8" || echo "${Anolis_Version}" | grep -Eqi "^8" || echo "${OpenCloudOS_Version}" | grep -Eqi "^8"; then
            Check_PowerTools
            if [ "${repo_id}" != "" ]; then
                echo "Installing packages in PowerTools repository..."
                for c8packages in rpcgen re2c oniguruma-devel;
                do dnf --enablerepo=${repo_id} install ${c8packages} -y; done
            fi
            dnf install libarchive -y

            dnf install gcc-toolset-10 -y
        fi

        if [ "${DISTRO}" = "Oracle" ] && echo "${Oracle_Version}" | grep -Eqi "^8"; then
            Check_Codeready
            for o8packages in rpcgen re2c oniguruma-devel;
            do dnf --enablerepo=${repo_id} install ${o8packages} -y; done
            dnf install libarchive -y
        fi

        if echo "${CentOS_Version}" | grep -Eqi "^9"; then
            crb_source_check=$(yum repolist all | grep -E '^crb' | awk '{print $1}')

            if [[ ! -n "$crb_source_check" ]]; then
                echo "Add crb source..."
                cat > /etc/yum.repos.d/centos-crb.repo << EOF
[CRB]
name=CentOS-\$releasever - CRB - mirrors.ustc.edu.cn
#failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/centos-stream/\$stream/CRB/\$basearch/os/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos-stream/RPM-GPG-KEY-CentOS-Official
EOF
            fi
        fi
        if echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
            for cs9packages in oniguruma-devel libzip-devel libtirpc-devel libxcrypt-compat;
            do dnf --enablerepo=crb install ${cs9packages} -y; done
        fi

        if echo "${CentOS_Version}" | grep -Eqi "^7" || echo "${RHEL_Version}" | grep -Eqi "^7"  || echo "${Aliyun_Version}" | grep -Eqi "^2" || echo "${Alibaba_Version}" | grep -Eqi "^2" || echo "${Oracle_Version}" | grep -Eqi "^7" || echo "${Anolis_Version}" | grep -Eqi "^7"; then
            if [ "${DISTRO}" = "Oracle" ]; then
                yum -y install oracle-epel-release
            else
                yum -y install epel-release
                Get_Country
                if [ "${country}" = "CN" ]; then
                    sed -e 's!^metalink=!#metalink=!g' \
                        -e 's!^#baseurl=!baseurl=!g' \
                        -e 's!//download\.fedoraproject\.org/pub!//mirrors.ustc.edu.cn!g' \
                        -e 's!//download\.example/pub!//mirrors.ustc.edu.cn!g' \
                        -i /etc/yum.repos.d/epel*.repo
                fi
            fi
            yum -y install oniguruma oniguruma-devel
            if [ "${CheckMirror}" = "n" ]; then
                rpm -ivh ${cur_dir}/src/oniguruma-6.8.2-1.el7.x86_64.rpm ${cur_dir}/src/oniguruma-devel-6.8.2-1.el7.x86_64.rpm
            fi
        fi

        if [ "${DISTRO}" = "UOS" ]; then
            Check_PowerTools
            if [ "${repo_id}" != "" ]; then
                echo "Installing packages in PowerTools repository..."
                for uospackages in rpcgen re2c oniguruma-devel;
                do dnf --enablerepo=${repo_id} install ${uospackages} -y; done
            fi
        fi

        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
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
        Echo_Blue "[+] apt-get installing dependent packages..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        for packages in debian-keyring debian-archive-keyring build-essential bison libkrb5-dev libcurl3-gnutls libcurl4-gnutls-dev libcurl4-openssl-dev libcap-dev ca-certificates libc-client2007e-dev psmisc patch git libc-ares-dev libicu-dev e2fsprogs libxslt1.1 libxslt1-dev libc-client-dev xz-utils libexpat1-dev bzip2 libbz2-dev libaio-dev libtirpc-dev libsqlite3-dev libonig-dev pkg-config libtinfo-dev libnuma-dev libwebp-dev gnutls-dev;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

if [ "${isSSL}" == "ssl" ]; then
    echo "+--------------------------------------------------+"
    echo "|  A tool to upgrade lnmp 1.4 certbot to acme.sh   |"
    echo "+--------------------------------------------------+"
    if [[ "${Get_Stack}" =~ "lnmp" ]]; then
        domain=""
        while :;do
            Echo_Yellow "Please enter domain(example: www.example.com): "
            read domain
            if [ "${domain}" != "" ]; then
                if [ "${WebServer}" = "nginx" ]; then
                    if [ ! -f "/usr/local/nginx/conf/vhost/${domain}.conf" ]; then
                        Echo_Red "${domain} is not exist,please check!"
                        exit 1
                    else
                        echo " Your domain: ${domain}"
                        if ! grep -q "/etc/letsencrypt/live/${domain}/fullchain.pem" "/usr/local/nginx/conf/vhost/${domain}.conf"; then
                            Echo_Red "SSL configuration NOT found in the ${domain} config file!"
                            exit 1
                        fi
                        break
                    fi
                elif [ "${WebServer}" = "caddy" ]; then
                    if [ ! -f "/etc/caddy/Caddyfile" ]; then
                        Echo_Red "Caddy configuration file not found!"
                        exit 1
                    else
                        echo " Your domain: ${domain}"
                        if ! grep -q "${domain}" "/etc/caddy/Caddyfile"; then
                            Echo_Red "Domain ${domain} NOT found in Caddyfile!"
                            exit 1
                        fi
                        break
                    fi
                fi
            else
                Echo_Red "Domain name can't be empty!"
            fi
        done

        Echo_Yellow "Enter more domain name(example: example.com *.example.com): "
        read moredomain
        if [ "${moredomain}" != "" ]; then
            echo " domain list: ${moredomain}"
        fi

        vhostdir="/home/wwwroot/${domain}"
        echo "Please enter the directory for the domain: $domain"
        Echo_Yellow "Default directory: /home/wwwroot/${domain}: "
        read vhostdir
        if [ "${vhostdir}" == "" ]; then
            vhostdir="/home/wwwroot/${domain}"
        fi
        echo "Virtual Host Directory: ${vhostdir}"

        if [ ! -d "${vhostdir}" ]; then
            Echo_Red "${vhostdir} does not exist or is not a directory!"
            exit 1
        fi

        if [ ! -s /usr/local/acme.sh/account.conf ] || ! cat /usr/local/acme.sh/account.conf | grep -Eq "^ACCOUNT_EMAIL="; then
            while :;do
                Echo_Yellow "Please enter your email address: "
                read email_address
                if [[ "${email_address}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
                    echo "Email address ${email_address} is valid."
                    break
                else
                    echo "Email address ${email_address} is invalid! Please re-enter."
                fi
            done
        fi

        letsdomain=""
        if [ "${moredomain}" != "" ]; then
            letsdomain="-d ${domain}"
            for i in ${moredomain};do
                letsdomain=${letsdomain}" -d ${i}"
            done
        else
            letsdomain="-d ${domain}"
        fi

        if [ -s /usr/local/acme.sh/acme.sh ]; then
            echo "/usr/local/acme.sh/acme.sh [found]"
        else
            cd /tmp
            [[ -f latest.tar.gz ]] && rm -f latest.tar.gz
            wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.tar.gz -O latest.tar.gz --prefer-family=IPv4
            tar zxf latest.tar.gz
            cd acme.sh
            ./acme.sh --install --accountemail ${email_address} --home /usr/local/acme.sh
            cd ..
            rm -rf acme.sh
        fi

        if [ ! -s /usr/local/acme.sh/account.conf ]; then
            echo "acme.sh install failed!"
            exit 1
        fi

        if [ "${WebServer}" = "nginx" ]; then
            if [ -s /usr/local/nginx/conf/vhost/${domain}.conf ]; then
                mv /usr/local/nginx/conf/vhost/${domain}.conf /usr/local/nginx/conf/vhost/${domain}.conf.bak
            fi
        elif [ "${WebServer}" = "caddy" ]; then
            if [ -s /etc/caddy/Caddyfile ]; then
                mv /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak
            fi
        fi

        if [ "${WebServer}" = "nginx" ]; then
            cat > /usr/local/nginx/conf/vhost/${domain}.conf << EOF
server {
    listen 80;
    server_name ${domain} ${moredomain};
    root ${vhostdir};
    index index.html index.htm index.php;
    include enable-php-${PHPSelect}.conf;
    include /usr/local/nginx/conf/rewrite/none.conf;
    access_log  /home/wwwlogs/${domain}.log;
}
EOF
        elif [ "${WebServer}" = "caddy" ]; then
            cat > /etc/caddy/Caddyfile << EOF
${domain} ${moredomain} {
    root ${vhostdir}
    index index.html index.htm index.php
    php_fastcgi unix /tmp/php-cgi.sock
    gzip
    log {
        output file /home/wwwlogs/${domain}.log
        format json
    }
}
EOF
        fi

        if [ "${WebServer}" = "nginx" ]; then
            /usr/local/nginx/sbin/nginx -t
            if [ $? -eq 0 ]; then
                /usr/local/nginx/sbin/nginx -s reload
            else
                mv /usr/local/nginx/conf/vhost/${domain}.conf.bak /usr/local/nginx/conf/vhost/${domain}.conf
                Echo_Red "Nginx configuration error!"
                exit 1
            fi
        elif [ "${WebServer}" = "caddy" ]; then
            /usr/local/bin/caddy fmt /etc/caddy/Caddyfile
            if [ $? -eq 0 ]; then
                systemctl reload caddy
            else
                mv /etc/caddy/Caddyfile.bak /etc/caddy/Caddyfile
                Echo_Red "Caddy configuration error!"
                exit 1
            fi
        fi

        if [ -s /usr/local/acme.sh/acme.sh ]; then
            /usr/local/acme.sh/acme.sh --issue --standalone ${letsdomain} --keylength ec-256 --force
            if [ $? -eq 0 ]; then
                if [ "${WebServer}" = "nginx" ]; then
                    cat > /usr/local/nginx/conf/vhost/${domain}.conf << EOF
server {
    listen 80;
    server_name ${domain} ${moredomain};
    root ${vhostdir};
    index index.html index.htm index.php;
    include enable-php-${PHPSelect}.conf;
    include /usr/local/nginx/conf/rewrite/none.conf;
    access_log  /home/wwwlogs/${domain}.log;
    ssl_certificate /usr/local/acme.sh/${domain}_ecc/fullchain.cer;
    ssl_certificate_key /usr/local/acme.sh/${domain}_ecc/${domain}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    add_header Strict-Transport-Security "max-age=63072000" always;
}
EOF
                elif [ "${WebServer}" = "caddy" ]; then
                    cat > /etc/caddy/Caddyfile << EOF
${domain} ${moredomain} {
    root ${vhostdir}
    index index.html index.htm index.php
    php_fastcgi unix /tmp/php-cgi.sock
    gzip
    log {
        output file /home/wwwlogs/${domain}.log
        format json
    }
    tls {
        protocols tls1.2 tls1.3
        ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        curves x25519
    }
}
EOF
                fi

                if [ "${WebServer}" = "nginx" ]; then
                    /usr/local/nginx/sbin/nginx -t
                    if [ $? -eq 0 ]; then
                        /usr/local/nginx/sbin/nginx -s reload
                    else
                        mv /usr/local/nginx/conf/vhost/${domain}.conf.bak /usr/local/nginx/conf/vhost/${domain}.conf
                        Echo_Red "Nginx configuration error!"
                        exit 1
                    fi
                elif [ "${WebServer}" = "caddy" ]; then
                    /usr/local/bin/caddy fmt /etc/caddy/Caddyfile
                    if [ $? -eq 0 ]; then
                        systemctl reload caddy
                    else
                        mv /etc/caddy/Caddyfile.bak /etc/caddy/Caddyfile
                        Echo_Red "Caddy configuration error!"
                        exit 1
                    fi
                fi

                echo "SSL certificate has been installed successfully!"
            else
                if [ "${WebServer}" = "nginx" ]; then
                    mv /usr/local/nginx/conf/vhost/${domain}.conf.bak /usr/local/nginx/conf/vhost/${domain}.conf
                elif [ "${WebServer}" = "caddy" ]; then
                    mv /etc/caddy/Caddyfile.bak /etc/caddy/Caddyfile
                fi
                Echo_Red "SSL certificate installation failed!"
                exit 1
            fi
        fi
    else
        Echo_Red "Stack not found!"
        exit 1
    fi
else
    echo "+--------------------------------------------------+"
    echo "|  A tool to upgrade lnmp 1.4 to 2.2               |"
    echo "+--------------------------------------------------+"
    if [[ "${Get_Stack}" =~ "lnmp" ]]; then
        Upgrade_Dependent
        if [ "${WebServer}" = "nginx" ]; then
            Install_Nginx
        elif [ "${WebServer}" = "caddy" ]; then
            Install_Caddy
        fi
        Install_PHP
        LNMP_PHP_Opt
        Creat_PHP_Tools
        Add_Iptables_Rules
        Add_LNMP_Startup
        Check_LNMP_Install
    else
        Echo_Red "Stack not found!"
        exit 1
    fi
fi 