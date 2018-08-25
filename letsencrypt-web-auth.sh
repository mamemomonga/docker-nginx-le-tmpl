#!/bin/bash
set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LETSENCRYPT_DIR="$BASEDIR/letsencrypt"

cd $BASEDIR

function usage {
	echo "USAGE: $0 DOMAIN_NAME ADMIN_EMAIL"
	exit 1
}

DOMAIN_NAME="${1:-}"
ADMIN_EMAIL="${2:-}"

if [ -z "${DOMAIN_NAME:-}" ]; then
	echo "DOMAIN_NAME not set"
	usage
fi

if [ -z "${ADMIN_EMAIL:-}" ]; then
	echo "ADMIN_EMAIL not set"
	usage
fi

if [ -e "./conf.d/$DOMAIN_NAME.conf" ]; then
	echo "$DOMAIN_NAME.conf already exists."
	exit 1
fi

echo "DOMAIN_NAME: $DOMAIN_NAME"
echo "ADMIN_EMAIL: $ADMIN_EMAIL"
echo

mkdir -p $LETSENCRYPT_DIR/webroot/$DOMAIN_NAME/webroot

cat > conf.d/$DOMAIN_NAME.conf << EOS
server {
	listen 80;
	server_name $DOMAIN_NAME;
	location /.well-known {
		root /letsencrypt/webroot/$DOMAIN_NAME;
	}
	location / {
		return 404;
	}
}
EOS

docker-compose down
docker-compose up -d

mkdir -p $LETSENCRYPT_DIR/webroot/$DOMAIN_NAME
docker run --rm -it \
	-v $LETSENCRYPT_DIR/webroot/$DOMAIN_NAME:/webroot \
	-v $LETSENCRYPT_DIR/etc:/etc/letsencrypt \
	certbot/certbot certonly \
	-d $DOMAIN_NAME \
	-m $ADMIN_EMAIL \
	--webroot --webroot-path /webroot

cat > conf.d/$DOMAIN_NAME.conf << EOS
server {
	listen 80;
	server_name $DOMAIN_NAME;
	location /.well-known {
		root /letsencrypt/webroot/$DOMAIN_NAME;
	}
	location / {
		return 301 https://\$host\$request_uri;
	}
}
server {
	listen 443 ssl http2;
#	listen [::]:443 ssl http2;
	server_name $DOMAIN_NAME;

	ssl_protocols TLSv1.2;
	ssl_ciphers HIGH:!MEDIUM:!LOW:!aNULL:!NULL:!SHA;
	ssl_prefer_server_ciphers on;
	ssl_session_cache shared:SSL:10m;

	ssl_certificate     /letsencrypt/etc/live/$DOMAIN_NAME/fullchain.pem;
	ssl_certificate_key /letsencrypt/etc/live/$DOMAIN_NAME/privkey.pem;

	location / {
		root   /usr/share/nginx/html;
		index  index.html index.htm;
	}
}

EOS

docker-compose down
docker-compose up -d

cat > letsencrypt/update.sh << EOS
#!/bin/bash
set -eux
	cd $BASEDIR
	docker run --rm \\
		-v $LETSENCRYPT_DIR/webroot:/webroot \\
		-v $LETSENCRYPT_DIR/etc:/etc/letsencrypt \\
		certbot/certbot renew --force-renew
	/usr/local/bin/docker-compose down
	/usr/local/bin/docker-compose up -d
EOS

chmod 755 letsencrypt/update.sh
echo "Write: letsencrypt/update.sh"
perl -e "printf('%02d %02d %02d * * $(whoami) $BASEDIR/letsencrypt/update.sh'.qq{\n},int(rand()*59),3,int(rand()*30)+1)" > $BASEDIR/letsencrypt/cron

echo "Write: letsencrypt/cron"

echo
echo " *** SERVER IS READY ***"
echo "   https://$DOMAIN_NAME/"

