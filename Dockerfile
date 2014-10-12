FROM    ubuntu:14.04

# Environment Variables
# =====================
ENV     DEBIAN_FRONTEND noninteractive
ENV     JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# Install Prerequisites 
# =====================
RUN     apt-get -y update
RUN     apt-get -y upgrade
RUN     apt-get -y install software-properties-common
RUN     add-apt-repository -y ppa:chris-lea/node.js
RUN     apt-get -y update
RUN     apt-get -y install \
          python-django-tagging python-simplejson python-memcache python-ldap python-cairo  \
          python-pysqlite2 python-support python-pip gunicorn supervisor apache2 apache2-utils \
          git wget curl openjdk-7-jre-headless build-essential python-dev nodejs

# Install Collectd
# ================
RUN     apt-get -y install collectd

# Install Elasticsearch
# =====================
RUN     cd ~ && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.1.deb 
RUN     cd ~ && dpkg -i elasticsearch-1.2.1.deb && rm elasticsearch-1.2.1.deb

# Install Statsd
# ==============
RUN     mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd

# Install Graphite
# ========================================
RUN     pip install Twisted==11.1.0
RUN     pip install Django==1.5
RUN     pip install whisper
RUN     pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
RUN     pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# Install Grafana
# ===============
RUN     mkdir /src/grafana && cd /src/grafana &&\
        wget http://grafanarel.s3.amazonaws.com/grafana-1.8.1.tar.gz &&\
        tar xzvf grafana-1.8.1.tar.gz --strip-components=1 && rm grafana-1.8.1.tar.gz

# Configure Elasticsearch
# =======================
ADD     elasticsearch/run /usr/local/bin/run_elasticsearch
RUN     chown -R elasticsearch /var/lib/elasticsearch
RUN     mkdir -p /tmp/elasticsearch && chown elasticsearch:elasticsearch /tmp/elasticsearch

# Configure Statsd
# ================
ADD     statsd/config.js /src/statsd/config.js

# Configure Collectd
# ==================
ADD     collectd/collectd.conf /etc/collectd/collectd.conf

# Configure Graphite
# ==================
ADD     graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
ADD     graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
ADD     graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
ADD     graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
ADD     graphite/storage-aggregation.conf /var/lib/graphite/conf/storage-aggregation.conf
RUN     mkdir -p /var/lib/graphite/storage/whisper
RUN     touch /var/lib/graphite/storage/graphite.db /var/lib/graphite/storage/index
RUN     chown -R www-data /var/lib/graphite/storage  
RUN     chmod 0775 /var/lib/graphite/storage /var/lib/graphite/storage/whisper
RUN     chmod 0664 /var/lib/graphite/storage/graphite.db
RUN     cd /var/lib/graphite/webapp/graphite && python manage.py syncdb --noinput

# Configure Grafana
# =================
ADD     grafana/config.js /src/grafana/config.js

# Configure Apache
# ================
ADD     apache/apache.conf /etc/apache2/sites-available/000-default.conf
RUN     a2enmod proxy &&\
        a2enmod proxy_http &&\
        a2enmod proxy_ajp &&\
        a2enmod rewrite &&\
        a2enmod deflate &&\
        a2enmod headers &&\
        a2enmod proxy_balancer &&\
        a2enmod proxy_connect &&\
        a2enmod proxy_html

# Configure supervisor
# ====================
ADD     supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Volumes
# =======
VOLUME  /var/log/supervisor
VOLUME  /var/lib/graphite/conf
VOLUME  /var/lib/graphite/storage
VOLUME  /var/lib/elasticsearch

# Expose Grafana
# ==============
EXPOSE  80

# Expose Collectd
# ===============
EXPOSE  25826/udp

# Expose StatsD UDP port
# ======================
EXPOSE  8125/udp

CMD     ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
