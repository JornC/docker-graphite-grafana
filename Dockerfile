# DOCKER-VERSION 1.12.1

from	centos:latest 

# Install required packages
run	yum -y update
run	yum -y install epel-release
run	yum -y install gcc python-devel pycairo pyOpenSSL python-memcached \
	bitmap bitmap-fonts python-pip python-django-tagging \
	python-sqlite2 python-rrdtool memcached python-simplejson python-gunicorn \
	supervisor sudo nginx
run	pip install --upgrade pip
run	yum clean all

# Install graphite and carbon
run	pip install whisper
run 	pip install Twisted==11.1.0
run 	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
run 	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# Add system service config
add	./nginx.conf /etc/nginx/nginx.conf
add	./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add graphite config
add	./initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
add	./local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
add	./carbon.conf /var/lib/graphite/conf/carbon.conf
add	./storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
run	mkdir -p /var/lib/graphite/storage/whisper
run	touch /var/lib/graphite/storage/graphite.db /var/lib/graphite/storage/index
run	chown -R nginx /var/lib/graphite/storage
run	chmod 0775 /var/lib/graphite/storage /var/lib/graphite/storage/whisper
run	chmod 0664 /var/lib/graphite/storage/graphite.db
run	cd /var/lib/graphite/webapp/graphite && python manage.py syncdb --noinput

# Grafana
add	./grafana.repo /etc/yum.repos.d/grafana.repo
run 	yum -y install grafana

# Add grafana config
add	./grafana-defaults.ini /usr/share/grafana/conf/defaults.ini

# Nginx
expose	:80
# Carbon line receiver port
expose	:2003
# Carbon pickle receiver port
expose	:2004
# Carbon cache query port
expose	:7002
# Grafana
expose	:3000

VOLUME	["/usr/share/grafana/data"]
VOLUME	["/var/lib/graphite/storage/whisper"]
VOLUME	["/var/lib/graphite/conf/"]

cmd	/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
