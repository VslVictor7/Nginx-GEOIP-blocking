ARG NGINX_VERSION=1.31.6
ARG GEOIP2_VERSION=3.4

FROM alpine:3.24 AS builder

ARG NGINX_VERSION
ARG GEOIP2_VERSION

RUN apk --update --no-cache add \
        gcc \
        make \
        libc-dev \
        g++ \
        openssl-dev \
        linux-headers \
        pcre-dev \
        zlib-dev \
        libtool \
        automake \
        autoconf \
        libmaxminddb-dev \
        tzdata \
        git

RUN cd /opt \
    && git clone --depth 1 -b $GEOIP2_VERSION --single-branch https://github.com/leev/ngx_http_geoip2_module.git \
    && wget -O - http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar zxfv - \
    && mv /opt/nginx-$NGINX_VERSION /opt/nginx \
    && cd /opt/nginx \
    && ./configure --with-compat --add-dynamic-module=/opt/ngx_http_geoip2_module \
    && make modules


FROM nginx:$NGINX_VERSION-alpine3.24-slim

ENV TZ=America/Sao_Paulo

COPY --from=builder \
    /opt/nginx/objs/ngx_http_geoip2_module.so \
    /usr/lib/nginx/modules/

COPY --from=builder \
    /usr/share/zoneinfo/America/Sao_Paulo \
    /usr/share/zoneinfo/America/Sao_Paulo

COPY --from=builder \
    /usr/share/zoneinfo/America/Sao_Paulo \
    /etc/localtime

RUN echo "America/Sao_Paulo" > /etc/timezone \
    && grep -q 'include /etc/nginx/modules/\*.conf;' /etc/nginx/nginx.conf \
        || sed -i '2i include /etc/nginx/modules/*.conf;' /etc/nginx/nginx.conf

RUN apk add --no-cache libmaxminddb \
    && echo "load_module /usr/lib/nginx/modules/ngx_http_geoip2_module.so;" \
       > /etc/nginx/modules/ngx_http_geoip2_module.conf \
    && chmod 644 /usr/lib/nginx/modules/ngx_http_geoip2_module.so