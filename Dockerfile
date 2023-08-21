FROM python:3.10-alpine

LABEL maintainer="Amon Ho <hoamon@ho600.com>"

# # Expose 443, in case of LTS / HTTPS
EXPOSE 8000

# Install Supervisord
RUN apk add --no-cache supervisor
# Custom Supervisord config
COPY supervisord-alpine.ini /etc/supervisor.d/supervisord.ini

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
RUN apk add --no-cache build-base gcc
RUN apk add --no-cache git openssh-client
RUN apk add --no-cache postgis gdal proj
RUN apk add --no-cache \
    py3-pip python3-dev \
    musl-dev \
    libressl-dev \
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

RUN pip install --upgrade pip && pip install \
    "psycopg2-binary==2.9.6" \
    "lxml==4.9.2" \
    "grpcio==1.57.0" \
    "pandas==2.0.2" \
    "Pillow==9.3.0"

RUN ln -s /usr/lib/libproj.so.?? /usr/lib/libproj.so \
    && ln -s /usr/lib/libgdal.so.?? /usr/lib/libgdal.so \
    && ln -s /usr/lib/libgeos_c.so.? /usr/lib/libgeos_c.so # for Could not find the GDAL library

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Supervisor, which in turn will start Nginx and uWSGI
CMD ["/start.sh"]
