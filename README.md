## About container:

Container combining AdGuard Home and Unbound. I don't like the fact you cannot use 127.0.0.1 as an Upstream DNS server when trying to 
combine these two programs as seperate containers. The only way I found was using the Docker container IP address, which to me isn't 
reliable enough.

**Base**: alpine:3.18 \
**Unbound**: 1.17.1-r1 \
**AdGuard Home**: v0.107.37

Use the same volumemappings as the original AdGuardHome container. In fact, you can just swap in this image and everything still works. You only have to update your Upstream DNS server to __127.0.0.1:5053__, which enables Unbound.

As with the original AdGuardHome image, this exposes the following: \
**Volumes:** \
/opt/adguardhome/work \
/opt/adguardhome/conf

For Unbound: \
/opt/unbound (Needs unbound.conf)

**Ports:**
53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 853/tcp 853/udp 3000/tcp 5053/tcp 5053/udp

## hestia cp, certbot with cloudflare, docker compose adguard home + unbound
### Steps:
1) Install DNSSEC key and root hints
```
sudo apt update && sudo apt install dns-root-data
```
2) for QUIC
```
cat << EOF >> /etc/sysctl.conf
net.core.rmem_max=2500000
EOF
sysctl -p
```
3) In [hestia cp](https://hestiacp.com) create with [cli](https://hestiacp.com/docs/reference/cli.html) new user, for example `dns`, then add your domain, for example `dns.example.com`: 
```
v-add-user dns P4$$w@rD dns@example.com
v-add-domain dns dns.example.com
```
4) Create folders
```
mkdir -p /home/dns/{docker,nginx,ssl}
mkdir -p /home/dns/docker/agh-unbound/{work,conf}
mkdir -p /home/dns/docker/agh-unbound/conf/{agh,unbound}
chown -R dns:dns /home/dns/{docker,nginx,ssl,web} && \
find /home/dns/web -type d -name 'public_html' -exec chown dns:www-data {} \;
```
5) Use certbot for generating certificate
- Add dns records in cloudflare [dashboard](https://dash.cloudflare.com): `A` and `AAAA` for `dns.example.com`, `CNAME` for `*.dns.example.com` and don't forget to change `example.com` to your domain
```
A dns your_ipv4 DNS only
AAAA dns your_ipv6 DNS only
CNAME *.dns dns.example.com
```
- Create `cloudflare.ini` with [`dns_cloudflare_api_token`](https://dash.cloudflare.com/profile/api-tokens) and don't forget to change `your_tocken_here` to your value:
```
echo "dns_cloudflare_api_token = your_tocken_here" > /home/dns/cloudflare.ini && \
chown dns:dns /home/dns/cloudflare.ini && chmod 0600 /home/dns/cloudflare.ini
```
- Run certbot docker image [dns-cloudflare](https://hub.docker.com/r/certbot/dns-cloudflare) and don't forget to change `your_cloudflare_mail@example.com` and `example.com` to your values
```
sudo docker run -it --rm \
 --name certbot \
 -v "/home/dns/ssl:/etc/letsencrypt" \
 -v "/home/dns/cloudflare.ini:/cloudflare.ini" \
 certbot/dns-cloudflare certonly --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini \
 -m your_cloudflare_mail@example.com --agree-tos --preferred-chain "ISRG Root X1" \
 --no-eff-email --dns-cloudflare-propagation-seconds 20 \
 --cert-name example.com -d *.dns.example.com -d dns.example.com
```
- Add [`renew_dns_cert`](https://raw.githubusercontent.com/seb81/adguard-unbound/master/usr/local/hestia/bin/renew_dns_cert) to `/usr/local/hestia/bin` and make it executable (don't forget to change example.com to your domain)
```
nano /usr/local/hestia/bin/renew_dns_cert
chmod +x /usr/local/hestia/bin/renew_dns_cert
```
- Then add to cron this command `sudo /usr/local/hestia/bin/renew_cert` in hestia cp for user `admin` (for example for every 30 days)
6) Put files [`sb_agh.stpl`](https://raw.githubusercontent.com/seb81/adguard-unbound/master/usr/local/hestia/data/templates/web/nginx/php-fpm/sb_agh.stpl) and [`sb_agh.tpl`](https://raw.githubusercontent.com/seb81/adguard-unbound/master/usr/local/hestia/data/templates/web/nginx/php-fpm/sb_agh.tpl) in a folder `/usr/local/hestia/data/templates/web/nginx/php-fpm/`. Then change template for your domain in hestia cp (don't forget to change `example.com` for your domain)
```
v-change-web-domain-tpl dns dns.example.com sb_agh
```
7) If you wish build your own docker image
```
cd /home/dns/docker
git clone https://github.com/seb81/adguard-unbound
cd /home/dns/docker/adguard-unbound
docker build --tag sb/adguard-unbound .
```
8) Create [`docker-compose.yaml`](https://raw.githubusercontent.com/seb81/adguard-unbound/master/docker-compose.yaml)
```
nano /home/dns/docker/agh-unbound/docker-compose.yaml
```
9) Create [`unbound.conf`](https://raw.githubusercontent.com/seb81/adguard-unbound/master/files/unbound/unbound.conf)
```
nano /home/dns/docker/agh-unbound/conf/unbound/unbound.conf
```
10) Start and use wiki for configure [Adguard Home](https://github.com/AdguardTeam/AdGuardHome/wiki)

## Docker compose commands
```
# create and start
docker compose \
 -f /home/dns/docker/agh-unbound/docker-compose.yaml up -d
# stop and remove
docker compose \
 -f /home/dns/docker/agh-unbound/docker-compose.yaml down
```








