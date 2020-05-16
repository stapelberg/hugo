---
layout: post
title:  "a new distri linux (fast package management) release"
date:   2020-05-16 09:13:00 +02:00
categories: Artikel
tags:
- distri
- debian
---

I just [released a new version of distri](https://distr1.org/release-notes/supersilverhaze/).

The focus of this release lies on:

* a better developer experience, allowing users to debug any installed package
  without extra setup steps
  
* performance improvements in all areas (starting programs, building distri
  packages, generating distri images)
  
* better tooling for keeping track of upstream versions

See the [release notes](https://distr1.org/release-notes/supersilverhaze/) for
more details.

The [distri research linux distribution](https://distr1.org/) project [was started in
2019](/posts/2019-08-17-introducing-distri/) to research whether a few
architectural changes could enable drastically faster package management.

While the package managers in common Linux distributions (e.g. apt, dnf, …) [top
out at data rates of only a few
MB/s](/posts/2019-08-17-linux-package-managers-are-slow/), distri effortlessly
saturates 1 Gbit, 10 Gbit and even 40 Gbit connections, resulting in fast
installation and update speeds.

