---
layout: post
title:  "DIY out-of-band management: remote power button"
date:   2022-10-09 16:27:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1579117792384540672"
tags:
- pc
---

I was pleasantly surprised by how easy it was to make it possible to push a PC’s
power button remotely via MQTT by wiring up an ESP32 microcontroller, a MOSFET,
a resistor, and a few jumper wires.

While a commercial solution like IPMI offers many more features like remote
serial, or remote image mounting, this DIY solution feels really magical, and
has great price performance if all you need is power management.

{{< img src="IMG_1085_featured.jpg" alt="The inside of a PC case, where an ESP32 micro controller on an Adafruit Perma-Proto bread board is mounted inside the case and wired up to the mainboard with jumper wires for remote power control" >}}

## Motivation

To save power, I want to shut down my [network storage PC](/posts/2019-10-23-nas/) when it isn’t currently needed.

For this plan to work out, my daily backup automation needs to be able to turn on the network storage PC, and power it back off when done.

Usually, I implement that via [Wake On LAN
(WOL)](https://en.wikipedia.org/wiki/Wake-on-LAN). But, for this particular
machine, I don’t have an ethernet network link, I only [have a fiber
link](/posts/2020-08-09-fiber-link-home-network/). Unfortunately, it seems like
none of the 3 different 10 Gbit/s network cards I tested has functioning Wake On
LAN, and when I asked on Twitter, none of my followers had ever seen functioning
WOL on any 10 Gbit/s card. I suppose it’s not a priority for the typical target
audience of these network cards, which go into always-on servers.

I didn’t want to run an extra 10 Gbit/s switch just for WOL over an ethernet
connection, because switches like the MikroTik CRS305-1G-4S+IN consume at least
10W. As the network storage PC only consumes about 20W overall, I wanted a more
power-efficient option.

## Hardware and Wiring

The core of this DIY remote power button is a WiFi-enabled micro controller such
as the ESP32. To power the micro controller, I use the 5V standby power on the
mainboard’s USB 2.0 pin headers, which is also available when the PC is turned
off and only the power supply (PSU) is turned on. A micro controller with an
on-board 5V voltage regulator is convenient for this.

{{< note >}}

I verified the 5V standby power with a multimeter in DC power measurement
mode. Some embedded machines don’t have always-on 5V standby power, even if they
use an ATX power supply!

{{< /note >}}

Aside from the micro controller, we also need a transistor or logic-level MOSFET
to simulate a push of the power button, and a resistor to control the
transistor. An opto coupler is not needed, since the ESP32 is powered from the
mainboard, not from a separate power supply.

The mainboard’s front panel header contains a `POWERBTN#` signal (3.3V), and a
`GND` signal. When connecting a typical PC case power button to the header, you
don’t need to pay attention to the polarity. This is because the power button
just physically connects the two signals.

In our case, the polarity matters, because we need the 3.3V on the transistor’s
drain pin, otherwise we won’t be able to control the transistor via its base
pin. The `POWERBTN#` 3.3V signal is typically labeled `+` on the mainboard (or
in the manual), whereas `GND` is labeled `-`. If you are unsure, double-check
the voltage using a multimeter.

## Bill of Materials

* WiFi-enabled microcontroller with 5V power input, e.g. the [Espressif ESP32
  Pico
  Kit](https://docs.platformio.org/en/latest/boards/espressif32/pico32.html#board-espressif32-pico32)
* transistor or logic-level MOSFET for working with 3.3V, e.g. [2N7000
  (→digikey)](https://www.digikey.com/en/products/detail/onsemi/2N7000/244278)
* 1K resistor for controlling the transistor,
  e.g. [CF14JT1K00](https://www.digikey.com/en/products/detail/stackpole-electronics-inc/CF14JT1K00/1741314)
* a bread board and/or case for mounting, e.g. [Adafruit
  Perma-Proto](https://www.adafruit.com/product/571).

## Schematic

<a href="2022-10-08-remote-power-button.svg"><img src="2022-10-08-remote-power-button.svg" width="100%"></a>

## Software: ESPHome

I wanted a quick solution (with ideally no custom firmware development) and was
already familiar with [ESPHome](https://esphome.io/), which turns out to very
easily implement the functionality I wanted :)

In addition to a standard ESPHome configuration, I have added the following
lines to make the GPIO pin available through MQTT, and make it a momentary
switch instead of a toggle switch, so that it briefly presses the power button
and doesn’t hold the power button:

```yaml
switch:
  - platform: gpio
    pin: 25
    id: powerbtn
    name: "powerbtn"
    restore_mode: ALWAYS_OFF
    on_turn_on:
    - delay: 500ms
    - switch.turn_off: powerbtn
```

I have elided the full configuration for brevity, but you can click here to see it:

<details>
<summary>full ESPHome YAML configuration</summary>

```yaml
esphome:
  name: poweresp

esp32:
  board: pico32
  framework:
    type: arduino

# Enable logging
logger:

mqtt:
  broker: 10.0.0.54

ota:
  password: ""

wifi:
  ssid: "essid"
  password: "secret"

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Poweresp Fallback Hotspot"
    password: "secret2"

captive_portal:

switch:
  - platform: gpio
    pin: 25
    id: powerbtn
    name: "powerbtn"
    restore_mode: ALWAYS_OFF
    on_turn_on:
    - delay: 500ms
    - switch.turn_off: powerbtn
```

</details>

For the first flash, I used:

```
docker run --rm \
  -v "${PWD}":/config \
  --device=/dev/ttyUSB0 \
  -it \
  esphome/esphome \
    run poweresp.yaml
```

To update over the network after making changes (serial connection no longer needed), I used:

```
docker run --rm \
  -v "${PWD}":/config \
  -it \
  esphome/esphome \
    run poweresp.yaml
```

In case you want to learn more about the relevant ESPHome concepts, here are a
few pointers:

* https://esphome.io/components/wifi.html might need to set `use_address`
* https://esphome.io/components/switch/index.html
  * and https://esphome.io/components/switch/gpio.html
* https://esphome.io/components/mqtt.html

## Integration into automation

To push the power button remotely from Go, I’m using the following code:

```go
func pushMainboardPower(mqttBroker, clientID string) error {
	opts := mqtt.NewClientOptions().AddBroker(mqttBroker)
	if hostname, err := os.Hostname(); err == nil {
		clientID += "@" + hostname
	}
	opts.SetClientID(clientID)
	opts.SetConnectRetry(true)
	mqttClient := mqtt.NewClient(opts)
	if token := mqttClient.Connect(); token.Wait() && token.Error() != nil {
		return fmt.Errorf("connecting to MQTT: %v", token.Error())
	}

	const topic = "poweresp/switch/powerbtn/command"
	const qos = 0 // at most once (no re-transmissions)
	const retained = false
	token := mqttClient.Publish(topic, qos, retained, string("on"))
	if token.Wait() && token.Error() != nil {
		return fmt.Errorf("publishing to MQTT: %v", token.Error())
	}

	return nil
}
```

## Conclusion

I hope this small project write-up is useful to others in a similar situation!

If you need more features than that, check out the next step on the feature and
complexity ladder: [PiKVM](https://pikvm.org/) or
[TinyPilot](https://tinypilotkvm.com/). See also [this comparison by Jeff
Geerling](https://www.jeffgeerling.com/blog/2021/raspberry-pi-kvms-compared-tinypilot-and-pi-kvm-v3).
