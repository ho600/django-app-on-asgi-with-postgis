FROM ho600/nginx-on-alpine:python-3.10

LABEL maintainer="Amon Ho <hoamon@ho600.com>"

EXPOSE 80

# # Expose 443, in case of LTS / HTTPS
EXPOSE 443

# Install Supervisord
RUN apk add --no-cache supervisor
# Custom Supervisord config
COPY supervisord-alpine.ini /etc/supervisor.d/supervisord.ini
COPY supervisord-nginx.ini /etc/supervisor.d/nginx.ini
COPY supervisord-asgi.ini /etc/supervisor.d/asgi.ini

# By default, allow unlimited file sizes, modify it to limit the file sizes
# To have a maximum of 1 MB (Nginx's default) change the line to:
# ENV NGINX_MAX_UPLOAD 1m
ENV NGINX_MAX_UPLOAD 0

# By default, Nginx will run a single worker process, setting it to auto
# will create a worker for each CPU core
ENV NGINX_WORKER_PROCESSES 1

# By default, Nginx listens on port 80.
# To modify this, change LISTEN_PORT environment variable.
# (in a Dockerfile or with an option for `docker run`)
ENV LISTEN_PORT 80

# Used by the entrypoint to explicitly add installed Python packages 
# and uWSGI Python packages to PYTHONPATH otherwise uWSGI can't import Flask
ENV ALPINEPYTHON python3.10

# Copy start.sh script that will check for a /app/prestart.sh script and run it before starting the app
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Copy the entrypoint that will generate Nginx/... additional configs
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]

# Add demo app
COPY ./app /app
WORKDIR /app

# pip install packages for django-app
RUN apk add --no-cache build-base gcc rust cargo
RUN apk add --no-cache git openssh-client
RUN apk add --no-cache postgis gdal proj
RUN apk add --no-cache \
    musl-dev \
    postgresql-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    freetype-dev \
    fribidi-dev \
    harfbuzz-dev \
    jpeg-dev \
    lcms2-dev \
    openjpeg-dev \
    tcl-dev \
    tiff-dev \
    tk-dev \
    zlib-dev

RUN apk add --no-cache \
    python3-dev \
    py3-pip \
    py3-psycopg2 \
    py3-numpy \
    py3-grpcio \
    py3-pillow \
    py3-pandas \
    py3-lxml

RUN pip install --upgrade pip \
    "Django>=4.2,<4.3" \
    "daphne>=4.0,<4.1"

RUN ln -s /usr/lib/libproj.so.?? /usr/lib/libproj.so \
    && ln -s /usr/lib/libgdal.so.?? /usr/lib/libgdal.so \
    && ln -s /usr/lib/libgeos_c.so.? /usr/lib/libgeos_c.so # for Could not find the GDAL library

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Supervisor, which in turn will start Nginx and uWSGI
CMD ["/start.sh"]
