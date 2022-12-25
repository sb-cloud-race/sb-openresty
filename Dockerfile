FROM openresty/openresty:1.21.4.1-4-alpine-fat

RUN luarocks install xml2lua

COPY lua/xml2lua-modded.lua /usr/local/openresty/luajit/share/lua/5.1/xml2lua.lua

COPY conf.d /etc/nginx/conf.d

COPY debug /usr/local/openresty/nginx/html/debug

COPY lua /lua-src