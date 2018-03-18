---
layout: post
title:  "Making GitLab authenticate against dex"
date:   2017-10-21 15:19:00 +02:00
categories: Artikel
Aliases:
  - /Artikel/gitlab-with-dex
---

Because I found it frustratingly hard to make GitLab and dex talk to each other,
this article walks you through what I did step-by-step.

Let’s establish some terminology:

* [dex](https://github.com/coreos/dex) is our OpenID Connect (OIDC) “Provider
  (OP)”<br>in other words: the component which verifies usernames and passwords.

* [GitLab](https://gitlab.com/) is our OpenID Connect (OIDC) “Relying Party
  (RP)”<br>in other words: the component where the user actually wants to log
  in.

### Step 1: configure dex

First, I followed dex’s [Getting
started](https://github.com/coreos/dex/blob/master/Documentation/getting-started.md)
guide until I had dex serving the example config.

Then, I made the following changes to
[examples/config-dev.yaml](https://github.com/coreos/dex/blob/master/examples/config-dev.yaml):

1. Change the issuer URL to be fully qualified and use HTTPS.
2. Configure the HTTPS listener.
3. Configure GitLab’s redirect URI.

Here is a diff:

```diff
--- /proc/self/fd/11	2017-10-21 15:01:49.005587935 +0200
+++ /tmp/config-dev.yaml	2017-10-21 15:01:47.121632025 +0200
@@ -1,7 +1,7 @@
 # The base path of dex and the external name of the OpenID Connect service.
 # This is the canonical URL that all clients MUST use to refer to dex. If a
 # path is provided, dex's HTTP service will listen at a non-root URL.
-issuer: http://127.0.0.1:5556/dex
+issuer: https://dex.example.net:5554/dex
 
 # The storage configuration determines where dex stores its state. Supported
 # options include SQL flavors and Kubernetes third party resources.
@@ -14,11 +14,9 @@
 
 # Configuration for the HTTP endpoints.
 web:
-  http: 0.0.0.0:5556
-  # Uncomment for HTTPS options.
-  # https: 127.0.0.1:5554
-  # tlsCert: /etc/dex/tls.crt
-  # tlsKey: /etc/dex/tls.key
+  https: dex.example.net:5554
+  tlsCert: /etc/letsencrypt/live/dex.example.net/fullchain.pem
+  tlsKey: /etc/letsencrypt/live/dex.example.net/privkey.pem
 
 # Uncomment this block to enable the gRPC API. This values MUST be different
 # from the HTTP endpoints.
@@ -50,7 +48,7 @@
 staticClients:
 - id: example-app
   redirectURIs:
-  - 'http://127.0.0.1:5555/callback'
+  - 'http://gitlab.example.net/users/auth/mydex/callback'
   name: 'Example App'
   secret: ZXhhbXBsZS1hcHAtc2VjcmV0
```

### Step 2: configure GitLab

First, I followed [GitLab Docker
images](https://docs.gitlab.com/omnibus/docker/) to get GitLab running in
Docker.

Then, I swapped out the image with
[computersciencehouse/gitlab-ce-oidc](https://hub.docker.com/r/computersciencehouse/gitlab-ce-oidc/),
which is based on the official image, but adds OpenID Connect support.

I added the following config to `/srv/gitlab/config/gitlab.rb`:

```
gitlab_rails['omniauth_enabled'] = true

# Must match the args.name (!) of our configured omniauth provider:
gitlab_rails['omniauth_allow_single_sign_on'] = ['mydex']

# By default, third-party authentication results in a newly created
# user which needs to be unblocked by an admin. Disable this
# additional safety mechanism and directly create users:
gitlab_rails['omniauth_block_auto_created_users'] = false

gitlab_rails['omniauth_providers'] = [
  {
    name: 'openid_connect',  # identifies the omniauth gem to use
    label: 'OIDC',
    args: {
      # The name shows up in the GitLab UI in title-case, i.e. “Mydex”,
      # and must match the name in client_options.redirect_uri below
      # and omniauth_allow_single_sign_on above.
      #
      # NOTE that if you change the name after users have already
      # signed up through the provider, you will need to update the
      # “identities” PostgreSQL table accordingly:
      # echo "UPDATE identities SET provider = 'newdex' WHERE \
      #   provider = 'mydex';" | gitlab-psql gitlabhq_production
      'name':          'mydex',

      # Scope must contain “email”.
      'scope':         ['openid', 'profile', 'email'],

      # Discover all endpoints from the issuer, specifically from
      # https://dex.example.net:5554/dex/.well-known/openid-configuration
      'discovery':     true,

      # Must match the issuer configured in dex:
      # Note that http:// URLs did not work in my tests; use https://
      'issuer':        'https://dex.example.net:5554/dex',

      'client_options': {
        # identifier, secret and redirect_uri must match a
	# configured client in dex.
        'identifier':   'example-app',
        'secret':       'ZXhhbXBsZS1hcHAtc2VjcmV0',
        'redirect_uri': 'https://gitlab.example.net/users/auth/mydex/callback'
      }
    }
  }
]

```

### Step 3: patch omniauth-openid-connect

Until [dex issue #376](https://github.com/coreos/dex/issues/376) is fixed, the
following patch for the omniauth-openid-connect gem is required:

```diff
--- /opt/gitlab/embedded/lib/ruby/gems/2.3.0/gems/omniauth-openid-connect-0.2.3/lib/omniauth/strategies/openid_connect.rb.orig	2017-10-21 12:31:50.777602847 +0000
+++ /opt/gitlab/embedded/lib/ruby/gems/2.3.0/gems/omniauth-openid-connect-0.2.3/lib/omniauth/strategies/openid_connect.rb	2017-10-21 12:34:20.063308560 +0000
@@ -42,24 +42,13 @@
       option :send_nonce, true
       option :client_auth_method
 
-      uid { user_info.sub }
-
+      uid { @email }
       info do
-        {
-          name: user_info.name,
-          email: user_info.email,
-          nickname: user_info.preferred_username,
-          first_name: user_info.given_name,
-          last_name: user_info.family_name,
-          gender: user_info.gender,
-          image: user_info.picture,
-          phone: user_info.phone_number,
-          urls: { website: user_info.website }
-        }
+        { email: @email }
       end
 
       extra do
-        {raw_info: user_info.raw_attributes}
+        {raw_info: {}}
       end
 
       credentials do
@@ -165,6 +154,7 @@
               client_id: client_options.identifier,
               nonce: stored_nonce
           )
+          @email = _id_token.raw_attributes['email']
           _access_token
         }.call()
       end
```