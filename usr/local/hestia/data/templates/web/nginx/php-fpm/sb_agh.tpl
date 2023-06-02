#=======================================================================#
# AGH Web Domain Template                                               #
# DO NOT MODIFY THIS FILE! CHANGES WILL BE LOST WHEN REBUILDING DOMAINS #
#=======================================================================#

server {
    listen      %ip%:80;
    include %home%/%user%/web/%domain%/public_html/ipv6[.]conf;

    server_name %domain_idn% *.%domain_idn%;

    root /dev/null;

    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    location / {
       return 301 https://$host$request_uri;
    }

}

server {
    listen      %ip%:%web_ssl_port% ssl http2;
    # include ipv6
    include %home%/%user%/web/%domain%/public_html/sipv6[.]conf;
    server_name %domain_idn% *.%domain_idn%;
    root        %sdocroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    ssl_certificate      %home%/%user%/nginx/%domain%/fullchain.pem;
    ssl_certificate_key  %home%/%user%/nginx/%domain%/privkey.pem;
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    # verify chain of trust of OCSP response using Root CA and Intermediate certs
    ssl_trusted_certificate %home%/%user%/nginx/%domain%/chain.pem;

    # intermediate configuration
    #ssl_protocols TLSv1.2 TLSv1.3;
    #ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    #ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        location ~* ^.+\.(jpeg|jpg|png|webp|gif|bmp|ico|svg|css|js)$ {
            expires     max;
            fastcgi_hide_header "Set-Cookie";
        }
    }

    location ~ [^/]\.php(/|$) {
        types { } default_type "text/html";
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~ /\.(?!well-known\/) {
       deny all;
       return 404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    proxy_hide_header Upgrade;

    # include Redirect configuration file
    include %home%/%user%/web/%domain%/public_html/redirect[.]conf;

    # include Security configuration file
    include %home%/%user%/web/%domain%/public_html/security[.]conf;
}
