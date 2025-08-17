---
layout: post
title:  "Secret Management on NixOS with sops-nix"
date:   2025-08-24 09:56:00 +02:00
categories: Artikel
tags:
- nix
---

Passwords and secrets like cryptographic key files are everywhere in
computing. When configuring a Linux system, sooner or later you will need to put
a password somewhere — for example, when I [migrated my existing Linux Network
Storage (NAS) setup to
NixOS](/posts/2025-07-13-nixos-nas-network-storage-config/), I needed to specify
the desired Samba passwords in my NixOS config (or manage them manually, outside
of NixOS). For personal computers, this is fine, but if the goal is to share
system configurations (for example in a Git repository), we need a different
solution: Secret Management.

## What is Secret Management?

The basic idea behind Secret Management systems is to *encrypt* the secrets at
rest, meaning if somebody clones the git repository containing your NixOS system
configurations, they cannot access (and therefore, also not deploy) the
encrypted secrets.

Conceptually, we need to:
1. Encrypt the secrets such that the target system can decrypt them.
1. Encrypt the secrets such that other people working on this config can decrypt
   them.
1. Have the target system decrypt secrets at runtime.
1. Tell our software where to access the decrypted secrets.

## sops-nix setup

In this article, I will show how to accomplish the above using sops-nix. Here’s
a quick overview of the three different building blocks we will use:

* [sops](https://getsops.io/) is a tool to version-control secrets in git, in
  their encrypted form.
  * sops makes it easy to re-encrypt these secrets when adding/removing authorized keys.
  * sops is very flexible and can work with tons of other tools/providers.
* [sops-nix](https://github.com/Mic92/sops-nix) provides a way to integrate sops
  with Nix/NixOS
* Using sops with {{< man name="age" section="1" >}} allows us to use our
  existing SSH private key (humans) or SSH host private key (machines) instead
  of managing a separate set of key files.

You might wonder why I chose sops-nix over
[agenix](https://github.com/ryantm/agenix), the other contender? The
instructions for setting up sops-nix made more sense to me when I first looked
at it, and I wanted to have the option to use sops in other ways, not just with
age. If you’re curious about agenix, [check out Andreas Gohr’s blog post about
agenix](https://www.splitbrain.org/blog/2025-07/27-agenix).

### Step 1. Preparation

I ran the following instructions on an [Arch Linux machine on which I installed
the Nix tool and enabled Nix
Flakes](/posts/2025-07-27-dev-shells-with-nix-4-quick-examples/#setup). Follow
the link for instructions also for other systems like Debian or Fedora.

### Step 2. Obtain an age identity from your personal SSH key

I don’t want to manage an extra key file, so I’ll use `ssh-to-age` to derive a
key from my SSH private key file, which I already take good care of to back up:

```
midna % mkdir -p $HOME/.config/sops/age/
midna % read -s SSH_TO_AGE_PASSPHRASE; export SSH_TO_AGE_PASSPHRASE
midna % nix run nixpkgs#ssh-to-age -- \
  -private-key \
  -i $HOME/.ssh/id_ed25519 \
  -o $HOME/.config/sops/age/keys.txt
```

(The `SSH_TO_AGE_PASSPHRASE` option is documented in the [ssh-to-age
README](https://github.com/Mic92/ssh-to-age/blob/main/README.md#usage).)

To display the age recipient (public key) of this age identity (private key), I
used:

```
midna % nix shell nixpkgs#age
midna 2 % age-keygen -y $HOME/.config/sops/age/keys.txt
age10e9tt2qwq90y5hvl35dau0sm5cm4qvegtw2a70v7sz5fy99de42s9d5nkf
```

### Step 3. Obtain an age recipient for the remote machine

Similarly, I will derive an age recipient from the SSH host key of the remote
system:

```
batchn % cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
age1wnwfnrqhewjh39pmtyc8zhqw606znskt4h5p9s3pve4apd67gapqj6tr0k
```

### Step 4. Configure sops for your git repository

In my git repository (nix-configs), I have one subdirectory per NixOS system,
i.e. {{< man name="tree" section="1" >}} shows:

```
├── batchn
│   ├── configuration.nix
│   ├── disk-config.nix
│   ├── flake.lock
│   ├── flake.nix
│   ├── hardware-configuration.nix
│   ├── Makefile
│   ├── secrets
│   │   └── example.yaml
├── wiki
│   ├── configuration.nix
│   ├── disk-config.nix
│   ├── flake.lock
│   ├── flake.nix
│   ├── hardware-configuration.nix
│   ├── Makefile
…
```

In the root of the git repository (next to the `batchn` directory), I create
`.sops.yaml` like so:

```yaml
keys:
  - &admin_michael age10e9tt2qwq90y5hvl35dau0sm5cm4qvegtw2a70v7sz5fy99de42s9d5nkf
  - &server_batchn age1wnwfnrqhewjh39pmtyc8zhqw606znskt4h5p9s3pve4apd67gapqj6tr0k
# …more server keys go here…
creation_rules:
  - path_regex: batchn/secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_michael
      - *server_batchn
```

The more systems I manage, the more `keys` and `creation_rules` I will need to
configure.

The creation rules tell sops which keys to use when encrypting a file. In my
setups, I typically use only a single file per system, but I could imagine
splitting out some secrets into a separate file if I wanted to collaborate with
someone on just one aspect of the system.

### Step 5. Manage some secrets with sops

Now that we told sops which recipients to encrypt for, we can decrypt and edit
`secrets/example.yaml` in our configured editor by running:

```
midna ~/nix-configs/batchn % nix run nixpkgs#sops secrets/example.yaml
```

The simplest key file contains just one key, for example:

```yaml
api-key: hello world :)
```

After saving and exiting your editor, sops will update the encrypted
secrets/example.yaml.

### Step 6. Configure sops in NixOS

Now, we need to reference the encrypted file in NixOS and enable `sops-nix`
integration to make the decrypted secrets available on the system.

In `flake.nix`, I added `sops-nix` to the `inputs` section and added the NixOS
module. I show the entire diff because the places where the lines go are just as
important as what the lines say:

```diff
--- c/batchn/flake.nix
+++ i/batchn/flake.nix
@@ -1,85 +1,93 @@
 {
   inputs = {
     nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

     disko.url = "github:nix-community/disko";
     # Use the same version as nixpkgs
     disko.inputs.nixpkgs.follows = "nixpkgs";

     stapelbergnix.url = "github:stapelberg/nix";

     zkjnastools.url = "github:stapelberg/zkj-nas-tools";

+    sops-nix = {
+      url = "github:Mic92/sops-nix";
+      inputs.nixpkgs.follows = "nixpkgs";
+    };
+
   };

   outputs =
     {
       nixpkgs,
       disko,
       stapelbergnix,
       zkjnastools,
+      sops-nix,
       ...
     }:
     let
       system = "x86_64-linux";
       pkgs = import nixpkgs {
         inherit system;
         config.allowUnfree = false;
       };
     in
     {
       nixosConfigurations.batchn = nixpkgs.lib.nixosSystem {
         inherit system;
         inherit pkgs;
         modules = [
           disko.nixosModules.disko
           ./configuration.nix
           stapelbergnix.lib.userSettings
           # Use systemd for network configuration
           stapelbergnix.lib.systemdNetwork
           # Use systemd-boot as bootloader
           stapelbergnix.lib.systemdBoot
           # Run prometheus node exporter in tailnet
           stapelbergnix.lib.prometheusNode
           zkjnastools.nixosModules.zkjbackup
+          sops-nix.nixosModules.sops
         ];
       };
       formatter.${system} = pkgs.nixfmt-tree;
     };
 }
```

Then, in `configuration.nix`, we tell `sops-nix` to use the SSH host key as
identity, where sops will find our secrets and which secrets `sops-nix` should
realize on the remote system:

```nix
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ./secrets/example.yaml;
  sops.secrets."api-key" = { };
```

After deploying, we can access the secret on the running system:

```
batchn ~ % sudo cat /run/secrets/api-key
hello world :)%
batchn ~ %
```

Of course, even after rebooting the machine, the secrets remain available without a re-deploy:

```
batchn ~ % uptime
 22:09:23  up   0:00,  1 user,  load average: 0,32, 0,08, 0,03
batchn ~ % sudo cat /run/secrets/api-key
hello world :)%
batchn ~ %
```

## Usage Examples

Now that we have secrets stored in files under `/run/secrets`, how can we use
these secrets?

The following sections show a few common ways.

### Usage Example: command-line flags (ExecStart wrapper)

Let’s assume you have deployed a custom Go server as a systemd service on NixOS
as follows, and you want to start managing the cleartext secret passed via the
`-securecookie_hash_key` and `-securecookie_block_key` command-line flags:

```nix
{
  users.groups.fortuneserver = { };
  users.users.fortuneserver = {
    isSystemUser = true;
    group = "fortuneserver";
  };

  systemd.services.fortuneserver = {
    description = "fortuneserver";
    documentation = [ "https://michael.stapelberg.ch" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "fortuneserver";
      Group = "fortuneserver";

      ExecStart = ''
        "${pkgs.fortuneserver}/bin/fortuneserver" \
          -securecookie_hash_key="some-secret-key" \
          -securecookie_block_key="a-different-secret-key"
      '';
    };
  };
}
```

With the following sops secrets:

```yaml
fortuneserver:
    securecookie_hash_key: some-secret-key
    securecookie_block_key: a-different-secret-key
```

…we need to adjust our NixOS config to read these secret files at
runtime. Because the `ExecStart` directive is interpreted by systemd and not
passed through a shell, we use the [`writeShellScript`
helper](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellScript)
and then just `cat` the files:

{{< highlight nix "hl_lines=2-9 25-29" >}}
{
  sops.secrets."fortuneserver/securecookie_hash_key" = {
    owner = "fortuneserver";
    restartUnits = [ "fortuneserver.service" ];
  };
  sops.secrets."fortuneserver/securecookie_block_key" = {
    owner = "fortuneserver";
    restartUnits = [ "fortuneserver.service" ];
  };

  users.groups.fortuneserver = { };
  users.users.fortuneserver = {
    isSystemUser = true;
    group = "fortuneserver";
  };

  systemd.services.fortuneserver = {
    description = "fortuneserver";
    documentation = [ "https://michael.stapelberg.ch" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "fortuneserver";
      Group = "fortuneserver";

      ExecStart = pkgs.writeShellScript "fortuneserver-execstart" ''
        "${pkgs.fortuneserver}/bin/fortuneserver" \
          -securecookie_hash_key="$(cat /run/secrets/fortuneserver/securecookie_hash_key)" \
          -securecookie_block_key="$(cat /run/secrets/fortuneserver/securecookie_block_key)"
      '';
    };
  };
}
{{< /highlight >}}

### Usage Example: environment variable files

What if the service in question does not use command-line flags, but environment
variables for configuring secrets? We can put an environment variable file into
a sops-managed secret:

```yaml
translate-fe:
    env: |
        DEEPL_AUTH_KEY=my-deepl-key
```

…and then we make systemd apply these environment variables from the secrets file:

{{< highlight nix "hl_lines=2-5 13" >}}
{
  sops.secrets."translate-fe/env" = {
    owner = "translatefe";
    restartUnits = [ "translate-fe.service" ];
  };

  systemd.services.translate-fe = {
    documentation = [ "https://michael.stapelberg.ch" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "translatefe";

      EnvironmentFile = [ config.sops.secrets."translate-fe/env".path ];

      ExecStart = "${translatefeExecstart}/bin/translate-fe";
    };
  };
}
{{< /highlight >}}

If you are configuring a NixOS module (instead of declaring a custom service),
the option might not always be called `EnvironmentFile`. For example, for the
oauth2-proxy service, you would need to configure the
[`services.oauth2-proxy.keyFile`
option](https://search.nixos.org/options?channel=25.05&show=services.oauth2-proxy.keyFile&from=0&size=50&sort=relevance&type=packages&query=oauth2-proxy):

```nix
  services.oauth2-proxy = {
    keyFile = config.sops.secrets."oauth2-proxy/env".path;
    enable = true;
    # …
  };
```

### Usage Example: systemd credentials

In the previous examples, we configured the `owner` of each secret to the user
account under which the service is running. But what if there is no such user
account, because the service use systemd’s `DynamicUser` feature?

We can use systemd’s `LoadCredential` feature! For example, I supply the SMTP
password to my Prometheus Alertmanager as follows:

{{< highlight nix "hl_lines=2-4 6-8 18" >}}
{
  sops.secrets."alertmanager/smtp_pw" = {
    restartUnits = [ "alertmanager.service" ];
  };

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "smtp_pw:${config.sops.secrets."alertmanager/smtp_pw".path}"
  ];

  services.prometheus.alertmanager = {
    enable = true;

    configuration = {
      global = {
        smtp_smarthost = "smtp.gmail.com:587";
        smtp_from = "alerts@example.net";
        smtp_auth_username = "alerts@example.net";
        smtp_auth_password_file = "/run/credentials/alertmanager.service/smtp_pw";
      };

      # …remaining config goes here…
    };
  };
}
{{< /highlight >}}

### Usage Example: samba users/passwords

In my blog post [“Migrating my NAS from CoreOS/Flatcar Linux to
NixOS”](/posts/2025-07-13-nixos-nas-network-storage-config/#samba-nixos), I
describe how to configure samba users and passwords (from sops-managed secrets)
with an `ExecStartPre` shell script (which is very similar to the techniques
already explained).

## Conclusion

Managing secrets as separately-encrypted files in your config repository makes
sense to me!

age’s ability to work with SSH keys makes for a really convenient setup, in my
opinion. Encrypting secrets for the destination system’s SSH host key feels very
elegant.

I hope the examples above are sufficient for you to efficiently configure
secrets in NixOS!
