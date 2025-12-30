ARG NGINX_VERSION=1.29.4

FROM nginx:$NGINX_VERSION-alpine AS builder

ARG NGINX_VERSION=1.29.4
ARG GEOIP2_VERSION=3.4

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
        git

RUN cd /opt \
    && git clone --depth 1 -b $GEOIP2_VERSION --single-branch https://github.com/leev/ngx_http_geoip2_module.git \
    && wget -O - http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar zxfv - \
    && mv /opt/nginx-$NGINX_VERSION /opt/nginx \
    && cd /opt/nginx \
    && ./configure --with-compat --add-dynamic-module=/opt/ngx_http_geoip2_module \
    && make modules 

FROM nginx:$NGINX_VERSION-alpine

COPY --from=builder /opt/nginx/objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules

RUN grep -q 'include /etc/nginx/modules/\*.conf;' /etc/nginx/nginx.conf \
 || sed -i '2i include /etc/nginx/modules/*.conf;' /etc/nginx/nginx.conf

RUN apk add --no-cache libmaxminddb \
    && echo "load_module /usr/lib/nginx/modules/ngx_http_geoip2_module.so;" \
       > /etc/nginx/modules/ngx_http_geoip2_module.conf \
    && chmod 644 /usr/lib/nginx/modules/ngx_http_geoip2_module.so