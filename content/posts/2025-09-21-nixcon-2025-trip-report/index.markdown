---
layout: post
title:  "NixCon 2025 Trip Report 🐝"
date:   2025-09-21 09:34:00 +02:00
categories: Artikel
tags:
- nix
---

I liked the NixOS meetup earlier this year, and at the end of the meetup they
told everyone about NixCon 2025, which would be happening in Switzerland this
year, at the very same location, the [University Of Applied Sciences
OST](https://www.ost.ch/) in Rapperswil, so I decided to go! In this trip
report, I want to give you a rough impression of how I experienced this awesome
conference :)

*The bee in the title is a NixCon inside joke ;)*

## Friday

I arrived at about 09:30 on a rainy Friday morning, meaning I hurried from the
train station into OST building 1 to show my ticket QR code and pick up my
conference badge and custom name tag that I pre-ordered. The custom ones have
your name engraved and come with a strong magnet to attach them to your clothes:

{{< img src="IMG_5775.jpg" alt="regular and custom name tag" >}}

After grabbing a bite to eat, I headed to the main lecture hall for the opening
session. [Prof. Dr. Farhad
Mehta](https://www.ost.ch/en/person/farhad-d-mehta-8699) from OST, as well as
the entire NixCon orga team, welcomed the 450 registered attendees to the 10th
NixCon! I recognized many familiar faces from the Nix meetup, but many hands
went up when the audience was asked for whom it was the first time at NixCon, or
in Switzerland in general.

I want to thank Prof. Mehta in particular for making possible such meetups and
events! 👏

If you work at a university, school or other organisation that has access to
rooms, consider offering to host a meetup (on a regular basis, or even just
once)! Locations are always hard to find, so offering a space is a great
contribution to Open Source.

### “What if GitHub Actions were local-first and built using Nix?”

The first technical talk of the day was “What if GitHub Actions were local-first
and built using Nix?” by Domen Kožar, the person behind
[cachix.org](https://cachix.org), which is a hosted Nix cache. The talk pitched
[cloud.devenv.sh](https://cloud.devenv.sh/), which is a Nix-based CI solution
(like GitHub Actions) using [devenv](https://devenv.sh/).

By using this solution, you solve the problem that you can’t easily / completely
run GitHub Actions locally (yes, we all know about
[act](https://github.com/nektos/act)), and you get to (?) write Nix configs
instead of YAML configs.

The solution seems nice, but I found the talk a little unstructured because the
presenter jumped around between slides so much. One crucial question was left
unanswered: How do you integrate this custom solution with your GitHub projects?
To me, diverging from the default way of configuring GitHub Actions does not
seem worth it for my projects. YMMV.

[→ watch the recording (46 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56408-what-if-github-actions)

### “Rewriting the Hydra Queue Runner in Rust”

Next up: “Rewriting the Hydra Queue Runner in Rust” by Simon Hauser from
[Helsinki Systems](https://helsinki-systems.de/), a small German software
company. [Hydra](https://github.com/NixOS/hydra) is the component in the
NixOS infrastructure which schedules builds: when nixpkgs changes, this is
the component that runs the build whose result ends up on
[cache.nixos.org](https://cache.nixos.org) (the Debian equivalent is
[buildd](https://wiki.debian.org/buildd)).

Simon explained that bottlenecks in the current queue runner result in
stranding of infrastructure: the project has machines available that it
cannot use fully. He outlined how they replaced a crufty SSH-based automation
with a well-designed gRPC protocol. I got the impression that a group of
people was involved in developing and reviewing this design, which is a great
sign for a healthy project.

One thing that was unfortunately missing from the talk were metrics. It would
have been great to see a few graphs that illustrate just how much better the
rewritten queue runner is.

Currently, the new queue runner is already used for Nix Community builds, but
not yet in production for NixOS itself. Hopefully soon, though!

[→ watch the recording (27 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56409-rewriting-the-hydra-que)

### “You can't spell "devshell" without "hell"”

This talk was presented by Zach Mitchell from [Flox](https://flox.dev/), which
is a Nix-based dev environment solution. Thus far, I use `nix-shell` or `nix
develop` (see [Development shells with Nix: four quick
examples](/posts/2025-07-27-dev-shells-with-nix-4-quick-examples/)), so I was
curious what I’d learn from this talk.

Zach explained that both, `nix-shell` and `nix develop` were originally
written to debug Nix package builds, not to provide general-purpose
development environments. For users, this manifests as not being able to use
your favorite shell — `nix develop` only supports Bash. One might read about
`nix develop -c exec <shell>`, but that’s wrong, because then the shell’s RC
files run **after** Nix setup, possibly destroying parts of the setup.

One interesting thing I learnt is that the Nix garbage collector scans
`/proc` to avoid removing Nix store paths that are still needed by running
processes.

Zach mentioned https://github.com/zmitchell/proctrace, which is a
bpftrace-based profiler that tracks forks/execs and generates gantt chart
syntax of the timing. Sounds cool, but is unfortunately broken right now…?
Too bad.

[→ watch the recording (45 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56410-you-cant-spell-devshell)

### “The Nix Binary Cache and AWS”

In this fireside chat, Tarus Balog shared how he ended up at AWS after 20 years
of Open Source, and how his team wants to give back to the community. One
specific way in which they’re doing that is by hosting cache.nixos.org.

[→ watch the recording (24 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56403-the-nix-binary-cache-an)

### “Nix-based development environments at Shopify (reprise)”

Josh Heinrichs from Shopify shared how they adopted Nix (again!), and I think
real-world enterprise adoption stories like these are very interesting.

In summary, Shopify had a `dev` command (since 2016), which offered declarative
configuration and then dispatched to `apt` (Linux) or `homebrew` (macOS). In the
first attempt to move to Nix, the effort didn’t reach stable footing (some folks
couldn’t use it yet) and then a company-wide shift to cloud development
happened, where the easier solution was to “just use ubuntu”.

A few years in, folks are apparently not so happy with the cloud development
environments and one day, Shopify CEO [Tobias
Lütke](https://en.wikipedia.org/wiki/Tobias_L%C3%BCtke) finds
[devenv](https://devenv.sh), which is a Nix-based solution that is remarkably
similar to Shopify’s `dev`. So Tobi adopts devenv for one of their services and
becomes supportive of using Nix. This time around, they spend a lot more time on
a successful rollout within the organization, meaning incremental adoption,
getting all stakeholders on board, etc.

The takeaway is that one specific, well-supported use-case can be the adoption
driver. And once you have your development environments on a Nix-based solution,
you can more easily adopt other parts of the ecosystem as well.

[→ watch the recording (19 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56413-nix-based-development-e)

### “My first Nix Aha!: A Newcomer’s Perspective”

In a similar spirit to the Shopify talk, Kavisha Kumar from ASML shared how she
got into Nix after seeing a colleague use `nix-shell` to obtain a clean
development shell.

Kavisha spent a lot of time at ASML to teach others about why and how to use
Nix. She shared a number of nice metaphors that explained Nix concepts through
the subject area of video gaming.

I think many people are excited about Nix, but have trouble conveying that
excitement to others. Kavisha showed us a good way that worked for her.

[→ watch the recording (19 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56414-my-first-nix-aha-a-newc)

### Lightning Talks

The rest of the day was filled with lightning talks.

Cole Mickens from [Determinate Systems](https://determinate.systems/) explained
what features they are currently shipping in their downstream distribution
“Determinate Nix” (features will be upstreamed): lazy trees (a performance
optimization for evaluating Flakes), parallel evaluation (brings evaluation
times down from 16s to 7s) and a native Linux builder for mac. Next up are Flake
Schemas, which I haven’t read about yet.

Yvan Sraka from [Numtide](https://numtide.com/), a Nix and DevOps consultancy,
showed how he manages Linux machines for friends and family with NixOS. He has
his own configuration layer on top of NixOS and only uses the system as a
base. Most actual programs are used through AppImage, Flatpaks,
[envfs](https://github.com/Mic92/envfs) and
[nix-ld](https://github.com/nix-community/nix-ld). The latter two are solutions
to use FHS based programs (those that expect `/usr/bin` and other standard
locations to be present) on non-FHS systems like NixOS. I had heard of nix-ld
before, but not of envfs.

Jacek Galowicz from [Nixcademy](https://nixcademy.com) showed how to use
systemd-sysupdate and systemd-repart to implement A/B style updates with NixOS
and systemd. It’s great to see that this technique is more and more mainstream,
as I am also using A/B style updating successfully in
[gokrazy](https://gokrazy.org/).

## Saturday

The weather on Saturday was a lot better, so I made sure to get a seat with a
view of Lake Zürich:

{{< img src="IMG_5754.jpg" alt="lake view!" >}}

### “The bikes have been shed: The official Nix formatter”

In this talk, Silvan Mosberger from Tweag (and one of the main NixCon
organizers!), explains how the official formatting tool for .nix files came to
be.

I was delighted to hear `gofmt`, the official Go formatter, being mentioned as a
source of inspiration. Just like in other language ecosystems, introducing
uniform formatting eliminates time-consuming back-and-forth in code review over
adhering to coding style. Unfortunately, the formatting folks did not replicate
one key aspect to gofmt’s success: gofmt has no options. As the famous Go
proverb goes:

> Gofmt's style is no one's favorite, yet gofmt is everyone's favorite!

Meaning that it’s more important that everyone uses the same style, compared to
everyone being able to express their personal style preferences.

[→ watch the recording (20 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56375-the-bikes-have-been-she)

### “Mastering NixOS Integration Tests: Advanced Techniques for Fast and Robust Multi-VM Tests”

In this two-hour workshop, Jacek Galowicz from
[Nixcademy](https://nixcademy.com), who is not only a Nix teacher, but also
happens to be the maintainer of the NixOS integration test driver, shows us how
to write complex integration tests with a few lines of Nix and Python.

Jacek showed an integration test example: a Bittorrent service, consisting of
tracker, clients, firewalls and multiple networks! Nixpkgs contains over 1000
such integration tests, and running one on your laptop is easy.

The various ways to debug your tests seem pretty cool: using vsock instead of
port forwardings, and enabling a debug hook that will make a failed test hang
and wait to be debugged.

I thought this was a great overview and Jacek is an engaging teacher. I would
recommend booking his classes!

### “When Not to Nix: Working with External Config and SOPS Nix”

Ryota spoke about when to use Nix and when not to use Nix. For example, you
could manage your dotfiles (config files) with Nix, or you could decide not
to. Having recently migrated more and more machines and configurations to Nix, I
found myself agreeing with this talk: It’s important to understand what you’ll
get out of declaratively or statefully managed configs, and when which approach
is better.

[→ watch the recording (19 minutes) on
media.ccc.de](https://media.ccc.de/v/nixcon2025-56381-when-not-to-nix-working)

### Lightning Talks

The rest of the day I spent in lightning talks, some of which were sponsored
talk slots. I learnt about, in no particular order:

* [Cloud Hypervisor](https://www.cloudhypervisor.org/), a KVM based hypervisor like qemu, but written in Rust.
* [nixbuild.net](https://nixbuild.net/), a pay-as-you-go offering for extra
  build capacity you can rent. On Sunday I heard someone say that their company
  is using nixbuild.net and it’s very smooth.
* [NixCI](https://nix-ci.com/), a Nix-based hosted CI. So, the cloud.devenv.sh
  service we heard about on Friday is a competitor to this service.
* [Nix in the Wild](https://flox.dev/nixinthewild/) is an effort by Flox where
  they do 45-60 minute interviews about Nix success stories. This might help you
  convince folks in your organization.
* [clan](https://clan.lol) is a fleet management solution.
* [NovaCustom](https://novacustom.com/), a one-person laptop/PC company. The
  laptops come with coreboot and work with NixOS.
* ExpressVPN is migrating their internal server setup (TrustedServer) from
  Debian to NixOS! Deploying weekly in 105+ countries.
* Cyberus, a German company, is offering NixOS LTS releases, compliant with the
  EU Cyber Resilience Act obligations.
* David’s [styx](https://github.com/dnr/styx) project is a more
  bandwidth-efficient download mechanism for NixOS updates. This uses
  [EROFS](https://en.wikipedia.org/wiki/EROFS), which seems like an interesting
  alternative to SquashFS images.

After all the talks, we met outside for a group picture followed by barbecue at
the lake:

{{< img src="NixCon2025_arik-grahl.de_CC-BY-SA-4.0-3200w-featured.jpg" alt="NixCon 2025 group picture" >}} 

*NixCon 2025 by Arik Grahl. Licensed under CC BY-SA 4.0.*

## Sunday

Before the conference, I wasn’t sure if I would even bother showing up for
Sunday (Hack day), but on Sunday, I was like “of course!”, and it was a great
decision!

Many people were still around and were working on their projects. It felt like
the answer to any Nix question was just one chat message away — there was
expertise and helping hands from many parts of the project.

I ended up meeting a couple of people I only knew from online interactions
before, and we also talked a lot about meetups. Now, I am invited to multiple
meetups to give a talk :D

## Conclusion

This was a wonderful conference! The orga team and all contributors did a great
job!

As always, the OST in Rapperswil is a great venue for Open Source events.

Ticket sales and talk submission / scheduling were done using the
[Pretix](http://pretix.eu/) and [Pretalx](https://pretalx.com/p/about/) Open
Source systems, which makes me proud to have contributed to Pretix.

The selection of talks was great: Some deeply technical, some covering only the
human side of things, and many somewhere in between. I got the impression that
all the presenters I saw genuinely cared about their topic, so the overall
energy was very good!

(You can watch the talk recordings at [media.ccc.de: NixCon
2025](https://media.ccc.de/c/nixcon2025).)

Also outside of the talks, I had many friendly interactions and interesting
conversations. There is a lot of interest and adoption of Nix, which is great to
see!

The production level of the conference was *very high* for such a
volunteer-driven event. For example, the very cool sounding break music between
talks was created specifically for NixCon: [“Lava” by
tonstr.studio](https://tonstrstudio.bandcamp.com/album/lava). Similarly, the
welcome bag contained dark Swiss chocolate, specifically made for NixCon (see
picture below). I don’t even like dark chocolate, but this one was delicious!

Thanks again to all helpers, and I look forward to coming back soon!

{{< img src="IMG_5755.jpg" alt="NixCon 2025 Swiss chocolate" >}}
