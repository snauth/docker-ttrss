FROM ubuntu
MAINTAINER Max Snauth <snauth@eml.cc>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
  nginx supervisor php5-fpm php5-cli php5-curl php5-gd php5-json \
  php5-pgsql php5-mysql php5-mcrypt && apt-get clean && rm -rf /var/lib/apt/lists/*

# enable the mcrypt module
RUN php5enmod mcrypt

# add ttrss as the only nginx site
ADD ttrss.nginx.conf /etc/nginx/sites-available/ttrss
RUN ln -s /etc/nginx/sites-available/ttrss /etc/nginx/sites-enabled/ttrss
RUN rm /etc/nginx/sites-enabled/default

# add some plugins and themes

ADD https://github.com/HenryQW/tinytinyrss-fever-plugin/archive/master.tar.gz /var/www/plugins/fever/
ADD https://github.com/HenryQW/mercury_fulltext/archive/master.tar.gz /var/www/plugins/mercury_fulltext/
ADD https://github.com/voidstern/tt-rss-newsplus-plugin/archive/master.tar.gz /var/www/plugins/api_newsplus/ 
ADD https://raw.githubusercontent.com/jangernert/FeedReader/master/data/tt-rss-feedreader-plugin/api_feedreader/init.php /var/www/plugins/api_feedreader/
ADD https://github.com/sergey-dryabzhinsky/options_per_feed/archive/master.tar.gz /var/www/plugins/options_per_feed/ 
ADD https://github.com/levito/tt-rss-feedly-theme/archive/master.tar.gz /var/www/themes/feedly/
ADD https://github.com/DIYgod/ttrss-theme-rsshub/archive/master.tar.gz /var/www/themes/rsshub/

# install ttrss and patch configuration
WORKDIR /var/www
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -SL https://tt-rss.org/gitlab/fox/tt-rss/repository/archive.tar.gz?ref=master | tar xzC /var/www --strip-components 1 \
    && tar xzvpf /var/www/plugins/fever/master.tar.gz --strip-components=1 -C /var/www/plugins/fever tinytinyrss-fever-plugin-master && rm /var/www/plugins/fever/master.tar.gz \
    && tar xzvpf /var/www/plugins/mercury_fulltext/master.tar.gz --strip-components=1 -C /var/www/plugins/mercury_fulltext/ mercury_fulltext-master && rm /var/www/plugins/mercury_fulltext/master.tar.gz \
    && tar xzvpf /var/www/plugins/api_newsplus/master.tar.gz --strip-components=2 -C /var/www/plugins/api_newsplus tt-rss-newsplus-plugin-master/api_newsplus && rm /var/www/plugins/api_newsplus/master.tar.gz \
    && tar xzvpf /var/www/plugins/options_per_feed/master.tar.gz --strip-components=1 -C /var/www/plugins/options_per_feed options_per_feed-master && rm /var/www/plugins/options_per_feed/master.tar.gz \
    && tar xzvpf /var/www/themes/feedly/master.tar.gz --strip-components=1 -C /var/www/themes/ tt-rss-feedly-theme-master/feedly tt-rss-feedly-theme-master/feedly.css && rm -rf /var/www/themes/feedly \
    && tar xzvpf /var/www/themes/rsshub/master.tar.gz --strip-components=2 -C /var/www/themes/ ttrss-theme-rsshub-master/dist/rsshub.css && rm -rf /var/www/themes/rsshub \
    && apt-get purge -y --auto-remove curl \
    && chown www-data:www-data -R /var/www
RUN cp config.php-dist config.php

# expose only nginx HTTP port
EXPOSE 80

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure-db.php /configure-db.php
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
