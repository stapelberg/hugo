---
layout: post
title:  "25 Gbit/s HTTP and HTTPS download speeds"
date:   2022-05-14 16:18:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1525482567096537090"
tags:
- fiber
---

Now that I [recently upgraded my internet connection to 25
Gbit/s](/posts/2022-04-23-fiber7-25gbit-upgrade/), I was curious how hard or
easy it is to download files via HTTP and HTTPS over a 25 Gbit/s link. I don’t
have another 25 Gbit/s connected machine other than my router, so I decided to
build a little lab for tests like these 🧑‍🔬

## Hardware and Software setup

I found a Mellanox ConnectX-4 Lx for the comparatively low price of 204 CHF on
digitec:

{{< img src="IMG_0209.jpg" >}}

To connect it to my router, I ordered a MikroTik XS+DA0003 SFP28/SFP+ Direct
Attach Cable (DAC) with it. I installed the network card into my old workstation
(on the right) and connected it with the 25 Gbit/s DAC to router7 (on the left):

{{< img src="IMG_0204.jpg" >}}

### 25 Gbit/s router (left)

| Component    | Model                                                                                                           |
|--------------|-----------------------------------------------------------------------------------------------------------------|
| Mainboard    | ASRock B550 Taichi                                                                                              |
| CPU          | AMD Ryzen 5 5600X 6-Core Processor                                                                              |
| Network card | [Intel XXV710](https://www.fs.com/de/products/75603.html)                                                       |
| Linux        | Linux 5.17.4 ([router7](https://router7.org))<br>curl 7.83.0 from debian bookworm<br>Go `net/http` from Go 1.18 |

router7 comes with [TCP
BBR](https://en.wikipedia.org/wiki/TCP_congestion_control#TCP_BBR) enabled by
default.

### Old workstation (right)

| Component    | Model                                              |
|--------------|----------------------------------------------------|
| Mainboard    | ASUS PRIME Z370-A                                  |
| CPU          | Intel i9-9900K CPU @ 3.60GHz                       |
| Network card | Mellanox ConnectX-4                                |
| Linux        | 5.17.5 (Arch Linux)<br>nginx 1.21.6<br>caddy 2.4.3 |


## Test preparation

Before taking any measurements, I do one full download so that the file contents
are entirely in the Linux page cache, and the measurements therefore no longer
contain the speed of the disk.

`big.img` in the tests below refers to the 35 GB test file I’m downloading,
which consists of distri-disk.img repeated 5 times.

## T1: HTTP download speed (unencrypted) {#http}

### T1.1: Single TCP connection {#http1}

The simplest test is using just a single TCP connection, for example:

```bash
curl -v -o /dev/null http://oldmidna:8080/distri/tmp/big.img
./httpget25 http://oldmidna:8080/distri/tmp/big.img
```

| Client   | Server    | Gbit/s                     |
|----------|-----------|----------------------------|
| **curl** | **nginx** | **{{< bar speed=23.4 >}}** |
| curl     | caddy     | {{< bar speed=23.4 >}}     |
| Go       | nginx     | {{< bar speed=20 >}}       |
| Go       | caddy     | {{< bar speed=20.2 >}}     |

curl can saturate a 25 Gbit/s link without any trouble.

The Go `net/http` package is slower and comes in at 20 Gbit/s.

### T1.2: Multiple TCP connections {#http4}

Running 4 of these downloads concurrently is a reliable and easy way to saturate
a 25 Gbit/s link:

```bash
for i in $(seq 0 4)
do
  curl -v -o /dev/null http://oldmidna:8080/distri/tmp/big.img &
done
```

| Client | Server | Gbit/s                 |
|--------|--------|------------------------|
| curl   | nginx  | {{< bar speed=23.4 >}} |
| curl   | caddy  | {{< bar speed=23.4 >}} |
| Go     | nginx  | {{< bar speed=23.4 >}} |
| Go     | caddy  | {{< bar speed=23.4 >}} |

## T2: HTTPS download speed (encrypted) {#https}

At link speeds this high, enabling TLS slashes bandwidth in half or worse.

Using 4 TCP connections allows saturating a 25 Gbit/s link.

Caddy uses more CPU to serve files compared to nginx.

### T2.1: Single TCP connection {#https1}

This test works the same as T1.1, but with a HTTPS URL:

```bash
curl -v -o /dev/null --insecure https://oldmidna:8443/distri/tmp/big.img
./httpget25 https://oldmidna:8443/distri/tmp/big.img
```


| Client | Server    | Gbit/s                   |
|--------|-----------|--------------------------|
| curl   | nginx     | {{< bar speed=8 >}}      |
| curl   | caddy     | {{< bar speed=7.5 >}}    |
| **Go** | **nginx** | **{{< bar speed=12 >}}** |
| Go     | caddy     | {{< bar speed=7.2 >}}    |

### T2.2: Multiple TCP connections {#https4}

This test works the same as T1.2, but with a HTTPS URL:

```bash
for i in $(seq 0 4)
do
  curl -v -o /dev/null --insecure https://oldmidna:8443/distri/tmp/big.img &
done
```

Curiously, the Go `net/http` client downloading from caddy cannot saturate a 25
Gbit/s link.

| Client | Server | Gbit/s                 |
|--------|--------|------------------------|
| curl   | nginx  | {{< bar speed=23.4 >}} |
| curl   | caddy  | {{< bar speed=23.4 >}} |
| Go     | nginx  | {{< bar speed=23.4 >}} |
| Go     | caddy  | {{< bar speed=21.6 >}} |

## T3: HTTPS with Kernel TLS (KTLS) {#httpsktls}

Linux 4.13 got support for Kernel TLS back in 2017.

nginx 1.21.4 introduced support for Kernel TLS, and they have a [blog post on
how to configure
it](https://www.nginx.com/blog/improving-nginx-performance-with-kernel-tls/).

In terms of download speeds, there is no difference with or without KTLS. But,
enabling KTLS noticeably reduces CPU usage, from ≈10% to a steady 2%.

For even newer network cards such as the Mellanox ConnectX-6, the kernel can
even offload TLS onto the network card!

### T3.1: Single TCP connection {#httpsktls1}

| Client | Server    | Gbit/s                   |
|--------|-----------|--------------------------|
| curl   | nginx     | {{< bar speed=8 >}}      |
| **Go** | **nginx** | **{{< bar speed=12 >}}** |

### T3.2: Multiple TCP connections {#httpsktls4}

| Client | Server | Gbit/s                 |
|--------|--------|------------------------|
| curl   | nginx  | {{< bar speed=23.4 >}} |
| Go     | nginx  | {{< bar speed=23.4 >}} |

## Conclusions

When downloading from nginx with 1 TCP connection, with TLS encryption enabled
(HTTPS), the Go `net/http` client is faster than curl!

Caddy is slightly slower than nginx, which manifests itself in slower speeds
with curl and even slower speeds with Go’s `net/http`.

To max out 25 Gbit/s, even when using TLS encryption, just use 3 or more
connections in parallel. This helps with HTTP and HTTPS, with any combination of
client and server.

## Appendix

<details>
<summary>Go <code>net/http</code> test program <code>httpget25.go</code></summary>

```go
package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
)

func httpget25() error {
	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	for _, arg := range flag.Args() {
		resp, err := http.Get(arg)
		if err != nil {
			return err
		}
		if resp.StatusCode != http.StatusOK {
			return fmt.Errorf("unexpected HTTP status code: want %v, got %v", http.StatusOK, resp.Status)
		}
		io.Copy(ioutil.Discard, resp.Body)
	}
	return nil
}

func main() {
	flag.Parse()
	if err := httpget25(); err != nil {
		log.Fatal(err)
	}
}
```
</details>

<details>
<summary>Caddy config file <code>Caddyfile</code></summary>

```
{
  local_certs
  http_port 8080
  https_port 8443
}

http://oldmidna:8080 {
  file_server browse
}

https://oldmidna:8443 {
  file_server browse
}
```
</details>

<details>
<summary>nginx installation instructions</summary>

```
mkdir -p ~/lab25
cd ~/lab25

wget https://nginx.org/download/nginx-1.21.6.tar.gz
tar tf nginx-1.21.6.tar.gz

wget https://www.openssl.org/source/openssl-3.0.3.tar.gz
tar xf openssl-3.0.3.tar.gz

cd nginx-1.21.6
./configure --with-http_ssl_module --with-http_v2_module --with-openssl=$HOME/lab25/openssl-3.0.3 --with-openssl-opt=enable-ktls
make -j8
cd objs
./nginx -c nginx.conf -p $HOME/lab25
```
</details>

<details>
<summary>nginx config file <code>nginx.conf</code></summary>

```
worker_processes  auto;

pid        logs/nginx.pid;

daemon off;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    access_log /home/michael/lab25/logs/access.log  combined;

    sendfile        on;
    sendfile_max_chunk 2m;

    keepalive_timeout  65;

    server {
        listen       8080;
        listen [::]:8080;
        server_name  localhost;

        root /srv/repo.distr1.org/;

        location / {
            index index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }

        location /distri {
            autoindex on;
        }
    }

    server {
        listen 8443 ssl;
        listen [::]:8443 ssl;
        server_name localhost;

        ssl_certificate nginx-ecc-p256.pem;
        ssl_certificate_key nginx-ecc-p256.key;

        #ssl_conf_command Options KTLS;

        ssl_buffer_size 32768;
        ssl_protocols TLSv1.3;

        root /srv/repo.distr1.org/;

        location / {
            index index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }

        location /distri {
            autoindex on;
        }
    }
}
```
</details>
