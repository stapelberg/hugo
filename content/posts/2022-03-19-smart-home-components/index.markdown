---
layout: post
title:  "Smart Home components 🏠"
date:   2022-03-19 14:51:20 +01:00
categories: Artikel
---

I have tried a bunch of different Smart Home products over the last few years
and figured I would give an overview of which ones I liked, which ones I
disliked, and how I would go about selecting good Smart Home products to buy.

## Smart Lights

To me, the primary advantage of Smart Lights is the flexibility in where you
place extra light switches, and the extra functions that become much easier with
Smart Lights.

For example, I have added an extra light switch in the bed and next to the
couch, without having to have an electrician tear up the walls to add more
wiring. An “all-off” button is super handy at the end of the day or when
watching a movie.

Other attractive use-cases include controlling lights based on time of the day,
based on whether people are home, or based on a motion sensor.

I used the RGB color light bulb version of all of the below systems. In
practice, we typically don’t change the color much, but it is nice to be able to
adjust the color and brightness to something that fits the respective room. And,
every once in a while, scenes that use color are fun!

### Moved away from: IKEA TRÅDFRI 👎 {#tradfri}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_4166.jpg" >}}
</div>

The first smart light system I used was IKEA TRÅDFRI. I figured as a system with
a large user base, they would be inclined to improve it over time, and
compatibility should be more likely than with other, smaller vendors.

Unfortunately the system is pretty much unchanged from when I first bought it
many years ago.

You can easily find documentation about the API for using the TRÅDFRI gateway
programmatically, but when I looked for available Go packages, I decided to
use COAP and DTLS myself back in 2019 for lack of an attractive Go package.

The **light switches** are good in terms of features, and easy to install: you
can just remove the old switch and glue the TRÅDFRI switch over the existing
switch.

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1em">
{{< img src="IMG_4620.jpg" >}}
{{< img src="IMG_4622.jpg" >}}
</div>

The downside of the light switches is that they are flimsy: because the switch
is magnetically held in place in its case, it can easily fall on the floor when
you bump against it.

Pairing the devices was always tricky for me. It got easier when I turned off
all other ZigBee devices in my apartment before doing anything with IKEA
devices.

At multiple points, the devices lost their pairing. It might have been when they
ran out of battery.

The **battery lifetime** of the light switches was very poor — only about a year
on average. They use the CR2032 form factor, which my charger does not support,
so I couldn’t use rechargables.

Swapping out the batteries and re-pairing the system every year or so quickly
becomes tedious!

### Moved away from: Shelly Bulb 👎 {#shellybulb}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_4164.jpg" >}}
</div>

Because I also bought some [Shelly 1L smart relays](#shelly1l), I figured I’d
give the [Shelly
Bulb](https://shelly.cloud/products/shelly-bulb-smart-home-automation-device/) a
try.

Instead of ZigBee, the Shelly Bulbs use WiFi. This makes them easy to get into
your home network and does not require a separate gateway.

At 2 bulbs per room+hallway, and 2 buttons each, that sums up to having 16 extra
devices in your WiFi network. This wasn’t a problem for me in practice, but
depending on how stable your WiFi network is, it might be a concern.

Notably, this also means your lights can’t be controlled while your WiFi is unavailable.

In terms of physical **light switches**, you’ll need to use a separate product
such as the Shelly Button. This is the weakest point of the system. The latency
is noticeable, even when configuring a static IP address, which does make things
better, but still not good. The Shelly Button is extremely simple, so dimming
has to be emulated with double or triple-press actions.

Given that one typically interacts with this system multiple times a day via its
switches, I think it makes sense to chose a system that has good switches.

On the plus side, the Shelly Button uses a rechargable battery that can be
charged from a USB power bank, which is a concept I really like.

### Philips Hue 👍 {#hue}

After the Shelly Bulb, I figured I’d try Philips Hue. It’s by far the most
expensive system of the ones I have tried, but also by far the most polished and
user-friendly.

<div style="max-width: 150px; float: left; margin-right: 1em">
{{< img src="IMG_4514.jpg" >}}
</div>

People recommended the [Feller Smart Light
Control](https://www.feller.ch/de/Produktangebot/Funktaster) switches, which use
energy harvesting (from you clicking them!) and hence don’t require a battery.

This makes it easy to place them anywhere, like next to the couch in the picture
on the left.

<br style="clear: both">

Feller recommends extending existing installations by buying the next-larger
mounting plate. Extending the box in the wall is not required, as no wires or
in-wall space are needed. Drilling new holes for extra screws is required for
stability, but that’s a lot more doable than extending the whole box. Here are
some pictures before, during and after the installation:

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1em">
{{< img src="IMG_3883.jpg" >}}
{{< img src="IMG_4146.jpg" >}}
{{< img src="IMG_4513_featured.jpg" >}}
</div>

### Shelly 1L 👍 {#shelly1l}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_4453.jpg" >}}
</div>

The Shelly 1L is a very interesting device. It goes behind your existing device
into the wall and makes it smart!

This allows you to make smart any existing lights that can’t easily be replaced
by smart lights, for example a bathroom light built into the bathroom mirror
cabinet.

You can also make existing light switches smart if you like the ones you already
have and can’t exchange them.

Another use-case is to easily connect buttons or sensors into your network, for
example door bells or door sensors.

The Shelly 1L is special in that this specific model can be installed when all
you have is a live wire (i.e. wiring for a light switch).

One potential issue is that depending on the configuration and connected
device’s power usage, the Shelly might emit a slight hum noise. So, don’t
install one right next to your bed.

Another limitation is that while the Shelly does work with both, light
**switches** (changes state) and light **buttons** (generates an impulse), it
can only distinguish between short and long press events when you use a light
button. Newer light switches from Feller can be re-configured to function as a
button, but if your model is too old you might need to replace a light switch
with a button.

One weird issue I ran into was that after installing a new bathroom mirror
cabinet, the relay of the connected Shelly 1L would no longer function correctly
— the light just remained on, even when turning it off via the Shelly. I read on
the Shelly forum that this could be caused by running the Shelly upside-down,
and indeed, after turning it around, it started to work again!

## Smart Heating

Smart Heating systems are often advertised to save cost. I wanted to try it out,
and was also interested in the temperature logging because my apartment is on
the more humid side and I wanted some data to optimize the situation.

### HomeMatic 😐 {#homematicheating}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_3512.jpg" >}}
</div>

I bought some HomeMatic temperature sensors and heating valve drives back
in 2017. The hardware feels solid and was easy enough to install.

One massive downside of the system was the poor software quality of their
Central Control Unit (CCU2). The web interface was super slow, looked very
dated, and the whole thing kept running out of memory every 2 weeks or so. It
was so bad that I [re-implemented my own CCU in
Go](/posts/2017-04-16-homematic-reimplementation/). I hear that by now, they
have a new and better Control Unit version, though.

So far, one valve drive has failed with error code F1; I replaced it with a new
one.

Turns out smart control of our heating does not seem to make any measurable
difference. The rooms feel the same as before. No money is saved because the
utility bill is divided equally among all tenants across the building (which
seems to be standard in Switzerland), not billed for individual usage.

So, overall, I would not install smart heating valve drives again. The
temperature sensors I still keep an eye on from time to time, but there are
cheaper options if you only need temperature!

## Smart Lock

### Nuki 👍 {#nuki}

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1em">
{{< img src="IMG_4549.jpg" >}}
{{< img src="IMG_3691.jpg" >}}
{{< img src="IMG_3484.jpg" >}}
{{< img src="IMG_3780.jpg" >}}
</div>

During the pandemic, I was receiving packages at home and hence I was relying on
my door bell much more than usual. Hence, I was looking for a way to make it
smarter!

The first device I got was the [Nuki Opener](https://nuki.io/en/opener/), a
smart intercom system. It allows you to get notifications on your phone when the
doorbell is rung, and to unlock the door from your phone.

I got this device because it was specifically marketed as compatible with the
BTicino intercom system our house uses. Unfortunately, this turned out to [be
incorrect](/posts/2020-11-30-scs-processing-microcontroller/), so I ended up
[building a hardware-modified intercom
unit](/posts/2021-03-13-smart-intercom-backpack/) that is connected to the Nuki
Opener in analogue mode.

Once it actually works, it’s a convenient system, and having your doorbell
generate desktop notifications with sound is just super useful when wearing
headphones! Strongly recommended.

As you can see on the pictures, I’m powering the Nuki Opener via USB. It
normally runs on batteries, but I want to minimize battery usage and swapping. A
built-in rechargeable battery like in the Shelly devices would be a neat
improvement to the Nuki Opener, so that the device could still work during power
outages!

After I had the Nuki Opener, I also added a [Nuki Smart
Lock](https://nuki.io/en/smart-lock/) so that we can not only open the house
front door, but also the apartment door itself in case one of us forgets their
key.

The Nuki Smart Lock was easy to install and works great. It also shows with an
elegant LED ring whether the door is currently locked or not, which I find
handy.

## Motion Sensors

Not having to turn on lights myself is something I find convenient, in
particular in the kitchen, but also in the bathroom. When carrying plates or
glasses into the kitchen, it’s nice to have the lights turn on while my hands
are full.

### Moved away from: Feller Motion Sensors 😐 {#fellermotion}

First I tried Feller’s Motion Sensors, because they physically fit well into the
existing Feller light switch installation:

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1em">
{{< img src="IMG_4311.JPG" >}}
{{< img src="IMG_4407.JPG" >}}
</div>

But, their limitations made me move away from them quickly: while you can change
one or two basic settings, you cannot, for example, disable the motion sensor
after a certain time of day, or manually disable it for a certain time period.

Also, because the device is installed in a fixed position (determined by where
your light switch is), it isn’t necessarily in the best place to spot all the
motion you want to detect.

### Shelly Motion 👍 {#shellymotion}

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1em">
{{< img src="IMG_4552.jpg" >}}
{{< img src="IMG_4550.jpg" >}}
{{< img src="shellymotion-webinterface.jpg" >}}
</div>

The [Shelly
Motion](https://shelly.cloud/shelly-motion-smart-home-automation-sensor/) Sensor
seems like a good motion sensor to me! It has a number of useful settings and
can easily trigger any REST API endpoint or can be used via MQTT.

Like with the Shelly Button, this device has a built-in rechargeable battery
that can be charged via USB. Depending on the location of the sensor, you can
either attach a USB powerbank once a year, or remove the sensor from its fixture
and charge it elsewhere.

The positioning of the Shelly Motion can either be easy (as it was in my
kitchen) or tricky to get right (in my bathroom). I don’t know if other motion
sensors are better in terms of range.

One thing to note is that the Shelly Motion only reports state changes (motion
start or motion end), and no continuous events while motion is detected.

For my kitchen, [my regelwerk
code](https://github.com/stapelberg/regelwerk/blob/8693602b899ae3bd682bea3b08289de782791483/motion.go#L94-L128)
directly translates motion on/off into light on/off commands (to Philips Hue and
Shelly 1L), with the exception that a long-press turns off all motion control
for the next 10 minutes. The granularity of the Shelly Motion is to report after
no motion for 1 minute, which works well for me for the kitchen.

For my bathroom, I don’t want the lights to immediately turn off when no motion
is detected anymore, to err on the side of not turning off the light while
people are still using the bathroom and are just not seen by the motion
sensor. To implement that, I found that using the Shelly 1L’s timer
functionality works best. So, [in my
configuration](https://github.com/stapelberg/regelwerk/blob/511198c89bf27bb39b0ba03bd33fe44a1ab4b182/motion.go#L48-L104),
motion on means lights on, and motion off means lights on for 10 minutes, then
off. Turning off the light manually disables that logic.

Note that the Shelly Motion should really be mounted in the orientation
recommended by the manual. When the motion sensor lays on the side (or is upside
down), detection is much poorer.

## Smart Power Plug

A smart plug is an easy way to turn off a power-hungry device while you’re away,
to make a lamp smart, or to power on a connected device like a kettle to boil
water for making a tea.

My current use-cases are saving power for the stereo sound system connected to
my PC, and saving power by [powering up the
devices](https://github.com/gokrazy/bakery/commit/a32e6d0a12693d70ce0544617ff3e391480c4b5a)
in my [gokrazy Continuous Integration test
environment](https://gokrazy.org/platforms/) on-demand only.

While there are tons of vendors selling smart plugs, the selection narrows
considerably when you look for one with a [Swiss power
plug](https://en.wikipedia.org/wiki/SN_441011).

### HomeMatic 👎 {#homematicplug}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_4548.jpg" >}}
</div>

The HomeMatic smart plug is expensive (55 CHF) and super bulky! As you can see,
even if you connect it at the very end of a power strip, it still blocks the
adjacent connector.

Worse: the way it’s built (bulky side pointing away from the earth pin), I can’t
even insert it into 2 of the 3 power strips you see on the picture.

Somehow, even though it’s so bulky, the device feels flimsy at the same
time. I’m never 100% sure if the plug is inserted fully and correctly, and it’s
easy to accidentally turn off power when bumping against the smart plug with
your foot.

Because it’s a HomeMatic device, you need a working Central Control Unit (CCU)
to control it programmatically. Conceptually, I prefer smart plugs that can be
used with a REST or MQTT API.

The only upside of this smart plug is that it can measure power. I occasionally
use it for that.

### Sonoff 😐 {#sonoff}

<div style="max-width: 250px; float: left; margin-right: 1em">
{{< img src="IMG_1345.JPG" >}}
</div>

The Sonoff S26 are much cheaper (≈12 USD when I bought mine) and come in a Swiss
plug variant. Contrary to the HomeMatic ones, the Sonoff smart plugs are built
“the right way around”, meaning I can plug them into many Swiss power
strips. Unfortunately, they also block adjacent connectors, but at least not as
many as the HomeMatic.

The [Open Source firmware Tasmota](https://tasmota.github.io/docs/) supports the
Sonoff S26, but flashing them is a painful experience. You can’t do it over the
air; you need to access rather small serial console pins inside the device.

Once you have them flashed with Tasmota, the devices work great.

One feature they lack is power measurement.

I would love to find a smart plug with a Swiss plug, that supports power
measurement, and that is compatible with Tasmota (or builtin MQTT support), but
until that product comes along, the Sonoff S26 are what I’m going to use.

## Architecture as of March 2022

Here is an architecture diagram of the devices I’m currently using:

{{< img src="2022-03-06-smart-home-architecture.svg" >}}

To tie these different systems together, I use a Raspberry Pi running
[gokrazy](https://gokrazy.org/), which in turn runs my
[regelwerk](/posts/2021-01-10-mqtt-introduction/) program. regelwerk only talks
to MQTT, so all the different devices are connected to MQTT using small adapter
programs such as my [hue2mqtt](https://github.com/stapelberg/hue2mqtt) or
[shelly2mqtt](https://github.com/stapelberg/shelly2mqtt).

A more off-the-shelf solution would be to use [Node-RED](https://nodered.org/),
if you want to do a little programming, or [Home
Assistant](https://www.home-assistant.io/) if you want to do barely any
programming.

## My strategy for selecting components

I don’t look for one vendor or one system that has components for
everything. Instead, I chose the leading vendor in each domain. Compatibility
between systems is generally poor, so I try to keep my compatibility
requirements to a minimum.

To programmatically interact with the devices, the best bet are devices that are
designed to be developer-friendly (e.g. Shelly devices support MQTT) or at least
have an official API with modules in my favorite programming language
(e.g. Philips Hue). In terms of API, I expect to talk to a gateway device in my
local network — I tried talking e.g. Zigbee directly but found it inconvenient
due to poor software support, sparse documentation and strange compatibility
issues.

Direct device-to-device communication is nice from a reliability perspective,
but on some battery-powered systems you pay for it with reduced battery
runtime. For example, when using multiple light switches for the same room with
IKEA TRÅDFRI, you pair one to the other, which also makes all signals go through
it.

If possible, I select devices that have an open firmware available. Ideally, I
can keep using the vendor’s firmware, but if the vendor unexpectedly goes out of
business, it’s handy to have an alternative firmware available. Also, if the
devices require a cloud service to function, using open firmware typically
allows using them in your local network.

I have come to avoid WiFi where latency is important, e.g. between light
switches and lights.

I stopped looking at the price too much and instead look at the user
experience. Smart home is about comfort and convenience, and if a product
doesn’t delight in daily usage, why bother with it? Targeting the high end of
mid-range devices seems like the sweet spot to me. Avoid anything more expensive
than that, though — established players often re-brand third-party solutions and
you only pay for the company name, not quality.
