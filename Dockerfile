FROM ubuntu:trusty

MAINTAINER Eric Hansander <eric@erichansander.com>

RUN apt-get update

# Install Apache and extensions
# [Known PHP depepndencies](http://docs.withknown.com/en/latest/install/requirements.html),
# as of the 0.6.4 ("Dunham") release:
# - curl
# - date (included in libapache2-mod-php5)
# - dom (included in libapache2-mod-php5)
# - gd
# - json (included in libapache2-mod-php5)
# - libxml (included in libapache2-mod-php5)
# - mbstring (included in libapache2-mod-php5)
# - mongo or mysql
# - reflection (included in libapache2-mod-php5)
# - session (included in libapache2-mod-php5)
# - xmlrpc
RUN apt-get -yq  --no-install-recommends install \
		apache2 \
		libapache2-mod-php5 \
		php5-curl \
		php5-gd \
		php5-mysql \
		php5-xmlrpc

# Configure Apache
RUN cd /etc/apache2/mods-enabled \
	&& ln -s ../mods-available/rewrite.load .

# Install Known
RUN apt-get -yq  --no-install-recommends install \
		curl \
		mysql-client
RUN mkdir -p /var/www/known \
	&& curl -SL http://assets.withknown.com/releases/known-0.6.5.tgz \
		| tar -xzC /var/www/known/

# Configure Known
COPY config.ini /var/www/known/
RUN cd /var/www/known \
	&& chmod 644 config.ini \
	&& mv htaccess-2.4.dist .htaccess \
	&& chown -R root:www-data /var/www/known/

COPY apache2/sites-available/known.conf /etc/apache2/sites-available/
RUN cd /etc/apache2/sites-enabled \
	&& chmod 644 ../sites-available/known.conf \
	&& rm -f 000-default.conf \
	&& ln -s ../sites-available/known.conf .

# Clean-up
RUN rm -rf /var/lib/apt/lists/*

# Set up container entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 700 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]


EXPOSE 80
CMD ["apache2", "-DFOREGROUND"]
