# ngnix docker テンプレート

docker-compose で nginx を起動し、公開する設定テンプレートです。

Let's EncryptによるWeb認証による証明書取得機能つきです。

nginx.conf が /etc/nginx/nginx.conf, conf.d が /etc/nginx/conf.d としてマウントされます。

アクセスログ・エラーログは起動時に log ディレクトリが作成され、こちらに保存されます。( コンテナ内部では /log )

# 必要なもの

	* 外部に公開できるサーバ
	* Docker
	* docker-compose

### 起動

	$ docker-compose up -d

### 停止

	$ docker-compose down

# Let's Encrypt の Web認証

事前にサーバへドメイン名を割り当てておく(A レコードにサーバのIPアドレスを設定)必要があります。

以下のスクリプトを次のように実行すると、nginxの設定を生成しながらWeb認証を完了することができます。

example.com のところをドメイン名、name@example.com をメールアドレスに置き換えてください。
メールアドレスはLet's Encryptに送信されます。

	$ ./letsencrypt-web-auth.sh example.com name@example.com

以下のプロンプトがでたら、内容を確認して回答してください。

	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	Please read the Terms of Service at
	https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
	agree in order to register with the ACME server at
	https://acme-v02.api.letsencrypt.org/directory
	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	(A)gree/(C)ancel: A
	
	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	Would you be willing to share your email address with the Electronic Frontier
	Foundation, a founding partner of the Let's Encrypt project and the non-profit
	organization that develops Certbot? We'd like to send you email about our work
	encrypting the web, EFF news, campaigns, and ways to support digital freedom.
	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	(Y)es/(N)o: Y

Congratulations! Your certificate and chain have been saved at... と表示されれば取得成功です。

取得に成功すると ./letsencrypt/etc/live/[DOMAIN_NAME]/ 以下に証明書が保存されます。

証明書は定期的更新しないと90日で失効します。

更新スクリプトとして letsencrypt/update.sh, cron設定として letsencrypt/cron が生成されますので、以下の方法でcronに登録してください。

月に一回強制的に更新が実行されます。

	$ sudo cp letsencrypt/cron /etc/cron.d/letsencrypt
	$ sudo chown root:root /etc/cron.d/letsencrypt
	$ sudo chmod 644 /etc/cron.d/letsencrypt

# License

MIT

