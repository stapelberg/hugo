---
layout: post
title:  "Development shells with Nix: four quick examples"
date:   2025-07-27 08:50:00 +02:00
categories: Artikel
tags:
- nix
---

I wanted to use [GoCV](https://gocv.io/) for one of my projects (to find and
extract paper documents from within a larger scan), without permanently having
OpenCV on my system.

This seemed like a good example use-case to demonstrate a couple of Nix commands
I like to use, covering quick interactive one-off dev shells to fully
declarative, hermetic, reproducible, shareable dev shells.

Notably, you don’t need to use NixOS to run these commands! You can [install and
use Nix](/posts/2025-06-01-nixos-installation-declarative/#setup-nix) on any
Linux system like Debian, Arch, etc., as long as you set a Nix path or use
Flakes (see [setup](#setup)).

## For comparison: The Debian Way {#debian-way}

Before we start looking at Nix, I will show how to get GoCV running on Debian.

Let’s create a minimal Go program which uses a GoCV function like
`gocv.NewMat()`, just to verify that we can compile this program:

```go
package main

import "gocv.io/x/gocv"

func main() {
  gocv.NewMat()
}
```

If we try to build this on a Debian system, we get:

```
debian % mkdir -p /tmp/minimal
debian % cd /tmp/minimal

debian % cat > minimal.go <<'EOT'
package main
import "gocv.io/x/gocv"
func main() { gocv.NewMat(); }
EOT

debian % go mod init minimal
go: creating new go.mod: module minimal
go: to add module requirements and sums:
	go mod tidy

debian % go mod tidy
go: finding module for package gocv.io/x/gocv
go: downloading gocv.io/x/gocv v0.41.0
go: found gocv.io/x/gocv in gocv.io/x/gocv v0.41.0

debian % go build
# gocv.io/x/gocv
# [pkg-config --cflags  -- opencv4]
Package opencv4 was not found in the pkg-config search path.
Perhaps you should add the directory containing `opencv4.pc'
to the PKG_CONFIG_PATH environment variable
Package 'opencv4', required by 'virtual:world', not found
```

On Debian, we can install OpenCV as follows:

```
debian % sudo apt install libopencv-dev

[…]

Summary:
  Upgrading: 7, Installing: 512, Removing: 0, Not Upgrading: 27
  Download size: 367 MB
  Space needed: 1590 MB / 281 GB available

Continue? [Y/n]
```

Saying “yes” to this prompt downloads and installs over 500 packages (takes a
few minutes).

Now the build works:

```
debian % go build
debian % file minimal
minimal: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), […]
```

…but we have over 500 extra packages on our system that will now need to be
updated in all eternity, therefore I would like to separate this one-off
experiment from my usual system.

We could use Docker to start a Debian container and work inside that container,
but, depending on the task, this can be cumbersome precisely because it’s a
separate environment. For this example, I would need to specify a volume mount
to make my input files available to the Docker container, and I would need to
set up environment variables before programs inside the Docker container can
open graphical windows on the host…

Let’s look at how we can use Nix to help us with that!

## Setup: Nix-on-Debian (or Nix-on-Arch, or…) {#setup}

Users of NixOS can skip this section, as NixOS systems include a ready-to-use
Nix.

Before you can try the examples on your own computer, you need to complete these
three steps:

1. Install Nix
1. Enable Flakes
1. Set a Nix path

### Step 1: Install Nix {#setup-install}

Users of Debian, Arch, Fedora, or other Linux systems first need to install
Nix. Luckily, Nix is available for many popular Linux distributions:

* Debian ships [nix-setup-systemd](https://packages.debian.org/trixie/nix-setup-systemd)
* Arch Linux packages [nix](https://archlinux.org/packages/extra/x86_64/nix/)
  and provides documentation [on the Nix Arch Wiki
  page](https://wiki.archlinux.org/title/Nix). In practice, I installed the
  package and [configured a couple of `nixbld`
  users](/posts/2025-06-01-nixos-installation-declarative/#setup-nix).
* More generally, there are Nix builds (rpm, deb, pacman) available for a number
  of distributions: https://github.com/nix-community/nix-installers

### Step 2: Enable Flakes {#setup-flakes}

Nix flakes are [“a generic way to package Nix
artifacts”](https://determinate.systems/posts/flake-schemas/).

Examples 3 and 4 use Nix flakes to pin dependencies, so we need to [enable Nix
flakes](/posts/2025-06-01-nixos-installation-declarative/#enabling-flakes).

### Step 3: Set a Nix path {#setup-nix-path}

For example 1 and 2, we want to use the Nix expression `import <nixpkgs>`.

On NixOS, this expression will follow the system version, meaning if you use
`import <nixpkgs>` on a NixOS 25.05 installation, that will reference [nixpkgs
in version nixos-25.05](https://github.com/NixOS/nixpkgs/tree/nixos-25.05/).

On other Linux systems, you’ll see an error message like this:

```
debian-server % nix-shell -p pkg-config opencv
error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)

       at «string»:1:25:

            1| {...}@args: with import <nixpkgs> args; (pkgs.runCommandCC or pkgs.runCommand) "shell" { buildInputs = [ (pkg-config) (opencv) ]; } ""
             |                         ^
(use '--show-trace' to show detailed location information)
```

We need to tell Nix which version of `nixpkgs` to use by setting the [Nix search
path](https://nixos.org/guides/nix-pills/15-nix-search-paths.html):

```
debian-server % export NIX_PATH=nixpkgs=channel:nixos-25.05
debian-server % nix-shell -p pkg-config opencv
[nix-shell:/tmp/opencv]#
```

Alright! Now we are set up. Let’s jump into the first example!

## Example 1: Interactive one-offs: nix-shell {#nix-shell}

Nix provides a middle-ground between installing OpenCV on your system (`apt
install` like in the example above) and installing OpenCV in a separate Docker
container: Nix can make available OpenCV without permanently installing it.

We can run {{< man name="nix-shell" section="1" >}} to start a bash shell in
which the specified packages are available. To successfully build Go code that
uses GoCV, we need to have OpenCV available:

```
% nix-shell -p pkg-config opencv
these 194 paths will be fetched (175.80 MiB download, 764.10 MiB unpacked):
  /nix/store/ig2nk0hsha9xaailhaj69yv677nv95q4-abseil-cpp-20210324.2
  /nix/store/yw5xqn8lqinrifm9ij80nrmf0i6fdcbx-alsa-lib-1.2.13
[…]

[nix-shell:/tmp/opencv]$ pkg-config --cflags opencv4
-I/nix/store/mh5b1dx2ifv4jkp9a8lgssxwhzxssb96-opencv-4.11.0/include/opencv4
```

In case you were wondering: Yes, we do need to specify `pkg-config` in this
`nix-shell` command explicitly, otherwise running `pkg-config` will run the host
version (outside the dev shell), which cannot find `opencv4.pc`.

## Example 2: nix-shell config file: shell.nix {#shell.nix}

Once we have a combination of packages that work for our project (in our
example, just `pkg-config` and `opencv`), we can create a `shell.nix` (in any
directory, but usually in the root of a project) which `nix-shell` (without the
`-p` flag) will read:

```nix
{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    # Explicitly list pkg-config so that mkShell will arrange
    # for the PKG_CONFIG_PATH to find the .pc files.
    pkg-config
    opencv
  ];
}
```

…and then, we just run `nix-shell`:

```
% nix-shell
[nix-shell:/tmp/opencv]$ pkg-config --cflags opencv4
-I/nix/store/mh5b1dx2ifv4jkp9a8lgssxwhzxssb96-opencv-4.11.0/include/opencv4
```

If you’re curious, here are a couple of documentation pointers regarding the
boilerplate around the list of packages:

* Line 1 to 3 [declare a
  function](https://nixos.org/guides/nix-pills/05-functions-and-imports.html)
  with an argument set — this is the required structure for `nix-shell` to be
  able to call your `shell.nix` file.
* [`pkgs.mkShell`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell) is
  a convenience helper for use with `nix-shell`.
* The `with pkgs;` part allows us to write `opencv` instead of `pkgs.opencv`.

By the way: With the [nixd language
server](https://github.com/nix-community/nixd), editors with [LSP
support](https://en.wikipedia.org/wiki/Language_Server_Protocol) can show the
versions that packages resolve to, point out your spelling mistakes, or provide
features like “jump to definition”.

For example, in this screenshot, I was editing `shell.nix` in Emacs and was
curious how the Nix source of the `opencv` package looked like. By pressing
`M-.` (`xref-find-definitions`) with
[“point”](https://www.gnu.org/software/emacs/manual/html_node/elisp/Point.html)
over `opencv`, I got to `opencv/4.x.nix` in my local Nix store:

{{< img src="2025-07-19-emacs-nix-shell.jpg" alt="Emacs showing opencv/4.x.nix after jumping to definition of opencv" >}}

## Example 3: Hermetic, pinned devShells: Nix Flakes {#nix-flakes}

The previous examples used nixpkgs from your system (or Nix path), which means
you don’t need to change the `.nix` file when you upgrade your system —
depending on the use-case, I see this behavior as either convenient or
terrifying.

For use-cases where it is important that the `.nix` file is built exactly the
same way, no matter what version the surrounding OS uses, we can use [Nix
Flakes](https://wiki.nixos.org/wiki/Flakes) to build in a hermetic way, with
dependency versions pinned in the `flake.lock` file.

A `flake.nix` contains the same `mkShell` expression as above, but declares
structure around it: The `mkShell` expression goes into the
`outputs.devShells.x86_64-linux.default` attribute and the `inputs` attribute
contains [Flake
references](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html#flake-references)
that are available to this build:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs }:
    {
      devShells.x86_64-linux.default =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.mkShell {
          packages = with pkgs; [
            # Explicitly list pkg-config so that mkShell will arrange
            # for the PKG_CONFIG_PATH to find the .pc files.
            pkg-config
            opencv
          ];
        };
    };
}
```

By the way: Despite the name, it is a best practice to use
`nixpkgs.legacyPackages`, which conceptually provides a single `import nixpkgs`
result ([for
efficiency](https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8)).

Now, I can use `nix develop` to get a shell with OpenCV:

```
% nix develop
michael@midna$ pkg-config --cflags opencv4
-I/nix/store/mh5b1dx2ifv4jkp9a8lgssxwhzxssb96-opencv-4.11.0/include/opencv4
```

The first `nix develop` run creates a `flake.lock` file, so running `nix
develop` later will get us exactly the same environment. To update to newer
versions, use `nix flake update`.

**Tip:** Instead of a shell, `nix develop --command=emacs` is also a useful variant.

## Example 4: Making the Flake system-independent {#system-indep-flake}

Unfortunately, the above `flake.nix` hard-codes `x86_64-linux`, so it will not
be usable on, say, an `aarch64-linux` (ARM) computer, or on a `x86_64-darwin`
(Mac).

Having to explicitly specify the `system` by default is a long-standing
criticism of Nix Flakes.

There are a number of workarounds. For example, we can use
[numtide/flake-utils](https://github.com/numtide/flake-utils) and refactor our
`flake.nix` to use its
[`eachDefaultSystem`](https://github.com/numtide/flake-utils?tab=readme-ov-file#eachdefaultsystem--system---attrs)
convenience function:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixfmt-tree;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Explicitly list pkg-config so that mkShell will arrange
            # for the PKG_CONFIG_PATH to find the .pc files.
            pkg-config
            opencv
          ];
        };
      }
    );
}
```

Or we could use [numtide/blueprint](https://github.com/numtide/blueprint),
its spiritual successor.

LucPerkins’s dev-templates [have effectively
inlined](https://github.com/the-nix-way/dev-templates/blob/main/go/flake.nix) a
version of this technique.

For a solution that isn’t part of Nix, but Nix-adjacent:
[devenv](https://devenv.sh/) is a separate tool that is built on Nix (no longer
using the CppNix implementation, but [tvix
actually](https://devenv.sh/blog/2024/10/22/devenv-is-switching-its-nix-implementation-to-tvix/)),
but with its own .nix files.

## Tip: Keeping packages around {#profile-install}

If you notice that `nix develop` or similar commands fetch packages despite the
`flake.lock` not having changed, you can install the Flake into your profile to
[declare it as a gcroot to
Nix](https://nixos.org/guides/nix-pills/11-garbage-collector.html):

```
% nix profile install .#devShells.x86_64-linux.default
```

But wait, isn’t that getting us into the same state as [with The Debian
Way](#debian-way)? No! While OpenCV will remain available indefinitely if you
install the flake into your profile, there still is a layer of separation:
Within your system, OpenCV isn’t available, only when you start a development
shell with `nix-shell` or `nix develop`.

## Conclusion

How do the four examples above compare? Here’s an overview:

| Example                                                     | Boilerplate | Pinned? | System-dependent? |
|-------------------------------------------------------------|-------------|---------|-------------------|
| [Ex 1](#nix-shell): `nix-shell -p …`                        | 😊          | no      | no                |
| [Ex 2](#shell.nix): `shell.nix`                             | 🙂          | no      | no                |
| [Ex 3](#nix-flakes): `flake.nix`                            | 😲          | yes     | yes               |
| [Ex 4](#system-indep-flake): system-independent `flake.nix` | 🤨          | yes     | no                |

For personal one-off experiments, I use `nix-shell`.

Once the experiment works, I typically want to pin the dependencies, so I use a
`flake.nix`.

If this is software that isn’t just versioned, but also published (or worked on
with multiple people/systems), I go through the effort of making it a
system-independent `flake.nix`.

I hope in the future, it will become easier to write a system-independent flake.

Despite the rough edges, I appreciate the reproducibility and control that Nix
gives me!
