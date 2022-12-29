This is a reverse http proxy poc.

Used to translate xml to json, and json to xml.

---

Client talks to proxy sending and receiving xml.

Proxy talks to back-end sending and receiving json.

---
Getting started:

build docker image

```shell
docker build . -t openresty-sbrw:latest
```

run container
```shell
docker run -p 8080:80 openresty-sbrw:latest
```

test some request
```shell
curl --compressed -v http://127.0.0.1:8080/soapbox/Engine.svc/systeminfo
```

---

Running real backend

start your json api backend somewhere, at some port (ex. 192.168.0.2:8888/myapi)

run container with real backend config:
```shell
docker run -p 8080:80 -e API_PATH=myapi -e API_URL=http://192.168.0.2:8888 openresty-sbrw:latest
```

test some request
```shell
curl --compressed -v http://127.0.0.1:8080/soapbox/Engine.svc/systeminfo
```

---

refs:

https://openresty.org/

https://github.com/manoelcampos/xml2lua

---