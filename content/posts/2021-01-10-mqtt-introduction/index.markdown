---
layout: post
title:  "A quick introduction to MQTT for IOT"
date:   2021-01-10 15:26:00 +01:00
categories: Artikel
---

While I had heard the abbreviation [MQTT](https://en.wikipedia.org/wiki/MQTT)
many times, I never had a closer look at what MQTT is.

Here are a few quick notes about using MQTT as [Pub/Sub
bus](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) in a home
IOT network.

## Motivation

Once you have a few [IOT
devices](https://en.wikipedia.org/wiki/Internet_of_things), an obvious question
is how to network them.

If all your devices are from the same vendor, the vendor takes care of it.

In my home, I have many different vendors/devices, such as (incomplete list):

* [Nuki Opener](https://nuki.io/en/opener/) Smart Intercom
* [Sonoff S26 Smart Plug](https://www.itead.cc/sonoff-s26-wifi-smart-plug.html) (WiFi-controlled socket outlet)
* [Aqara Door & Window Sensors](https://www.aqara.com/en/door_and_window_sensor.html)
* [IKEA Home Smart](https://en.wikipedia.org/wiki/IKEA#Smart_home) (formerly TRÅDFRI) Smart Lights

Here is how I combine these devices:

* When I’m close to my home (geo-fencing), the Nuki Opener enables Ring To Open (RTO): when I ring the door bell, it opens the door for me.
* When I open the apartment door, the Smart Lights in the hallway turn on.
* When I’m home, my stereo speakers should be powered on so I can play music.

A conceptually simple way to hook this up is to connect things directly: listen
to the Aqara Door Sensor and instruct the Smart Lights to turn on, for example.

But, connecting everything to an MQTT bus has a couple of advantages:

1. Unification: everything is visible in one place, the same tools work for all
   devices.
1. Your custom logic is uncoupled from vendor details: you can receive and send
   MQTT.
1. Compatibility with existing software, such as [Home
   Assistant](https://www.home-assistant.io/) or
   [openHAB](https://www.openhab.org/)

## Step 1. Set up an MQTT broker (server)

A broker is what relays messages between publishers and subscribers. As an
optimization, the most recent value of a topic can be retained, so that e.g. a
subscriber does not need to wait for the next change to obtain the current
state.

The most popular choice for broker software seems to be
[Mosquitto](https://mosquitto.org/), but since I like to run Go software on
https://gokrazy.org/, I kept looking and found https://github.com/fhmq/hmq.

One downside of `hmq` might be that it does not seem to support persisting
retained messages to disk. I’ll treat this as a feature for the time being,
enforcing a fresh start on every daily reboot.

To restrict hmq to only listen in my local network, I’m using [gokrazy’s flag
file
feature](https://github.com/gokrazy/tools/commit/fdd90fc6817876e08b352fae84f2a2794524ccc0):

```
mkdir -p flags/github.com/fhmq/hmq
echo --host=10.0.0.217 > flags/github.com/fhmq/hmq/flags.txt
```

Note that you’ll need https://github.com/fhmq/hmq/pull/105 in case your network
does not come up quickly.

### MQTT broker setup: displaying/sending test messages

To display all messages going through your MQTT broker, subscribe using the
[Mosquitto](https://mosquitto.org/) tools:

```
% sudo pacman -S mosquitto
% mosquitto_sub --id "${HOST}_all" --host dr.lan --topic '#' --verbose
```

The `#` sign denotes an [MQTT
wildcard](https://subscription.packtpub.com/book/application_development/9781787287815/1/ch01lvl1sec18/understanding-wildcards),
meaning subscribe to all topics in this case.

Be sure to set a unique id for each `mosquitto_sub` command you run, so that you
can see which subscribers are connected to your MQTT bus. Avoid id clashes,
otherwise the subscribers will disconnect each other!

Now, when you send a test message, you should see it:

```
% mosquitto_pub --host dr.lan --topic 'cmnd/tasmota_68462F/Power' -m 'ON'
```

Tip: If you have binary data on your MQTT bus, you can display it in hex with
timestamps:

```
% mosquitto_sub \
  --id "${HOST}_bell" \
  --host dr.lan \
  --topic 'doorbell/#' \
  -F '@Y-@m-@dT@H:@M:@S@z : %t : %x'
```

## Step 2. Integrate with MQTT

Now that communication via the bus works, what messages do we publish on which
topics?

MQTT only defines that topics are hierarchical; messages are arbitrary byte
sequences.

There are a few popular conventions for what to put onto MQTT:

* [The Homie convention](https://homieiot.github.io/)

* Home Assistant has its own convention, but [allows full configuration](https://www.home-assistant.io/integrations/switch.mqtt/#full-configuration). Home Assistant does [not support the homie convention yet](https://community.home-assistant.io/t/home-assistant-homie-compatibility/17135/8).

* openHAB [refers to Home Assistant and
  Homie](https://www.openhab.org/addons/bindings/mqtt.generic/).

If you design everything yourself, Homie seems like a good option. If you plan to
use Home Assistant or similar, stick to the Home Assistant convention.

### Best practices for your own structure

In case you want/need to define your own topics, keep these tips in mind:

* devices publish their state on a single, retained topic
  * the topic name could be e.g. `stat/tasmota_68462F/POWER`
  * retaining the topic allows consumers to catch up after (re-)connecting to the bus
* publish commands on a single, possibly-retained topic
  * e.g. publish `ON` to topic `cmnd/tasmota_68462F/Power`
  * publish the desired state: publish `ON` or `OFF` instead of `TOGGLE`
  * if you retain the topic and publish `TOGGLE` commands, your lights will mysteriously go off/on when they unexpectedly re-establish their MQTT connection

### Integration: Shelly devices with MQTT built-in

[Shelly](https://shelly.cloud/) has a number of smart devices that come with
MQTT out of the box! This sounds like the easiest solution if you’re starting
from scratch.

I haven’t used these devices personally, but I hear good things about them.

### Integration: Zigbee2MQTT for Zigbee devices

[Zigbee2MQTT](https://www.zigbee2mqtt.io/) supports well [over 1000 Zigbee
devices](https://www.zigbee2mqtt.io/information/supported_devices.html) and
exposes them on the MQTT bus.

For example, this is what you would use to connect your IKEA TRÅDFRI Smart
Lights to MQTT.

### Integration: ESPHome for micro controllers + sensors

The [ESPHome](https://esphome.io/) system is a ready-made solution to connect a
wide array of sensors and devices to your home network via MQTT.

If you want to use your own ESP-based micro controllers and sensors, this seems
like the easiest way to get them programmed.

### Integration: Mongoose OS for micro controllers

Mongoose OS is an IOT firmware development framework, taking care of device
management, Over-The-Air updates, and more.

[Mongoose comes with MQTT
support](https://mongoose-os.com/docs/mongoose-os/cloud/mqtt.md), and with just
a few lines you can build, flash and configure your device. Here’s an example
for the NodeMCU (ESP8266-based):

```
% yay -S mos-bin
% mos clone https://github.com/mongoose-os-apps/demo-js app1
% cd app1
% mos --platform esp8266 build
% mos --platform esp8266 --port /dev/ttyUSB1 flash
% mos --port /dev/ttyUSB1 config-set mqtt.enable=true mqtt.server=dr.lan:1883
```

Pressing the button on the NodeMCU publishes a message to MQTT:

```
% mosquitto_sub --host dr.lan --topic devices/esp8266_F4B37C/events
{"ram_free":31260,"uptime":27.168680,"btnCount":2,"on":false}
```

### Integration: Arduino for custom micro controller firmware

Arduino has an [MQTT Client
library](https://www.arduino.cc/reference/en/libraries/mqtt-client/). If your
microcontroller is networked, e.g. an ESP32 with WiFi, you can publish MQTT
messages from your Arduino sketch:

```c
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient wificlient;
PubSubClient client(wificlient);

void callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("] ");
    for (int i = 0; i < length; i++) {
      Serial.print((char)payload[i]);
    }
    Serial.println();
  
    if (strcmp(topic, "doorbell/cmd/unlock") == 0) {
  		// …
    }
}

void taskmqtt(void *pvParameters) {
	for (;;) {
		if (!client.connected()) {
			client.connect("doorbell" /* clientid */);
			client.subscribe("doorbell/cmd/unlock");
		}

		// Poll PubSubClient for new messages and invoke the callback.
		// Should be called as infrequent as one is willing to delay
		// reacting to MQTT messages.
		// Should not be called too frequently to avoid strain on
		// the network hardware:
		// https://github.com/knolleary/pubsubclient/issues/756#issuecomment-654335096
		client.loop();
		vTaskDelay(pdMS_TO_TICKS(100));
	}
}

void setup() {
	connectToWiFi(); // WiFi configuration omitted for brevity

	client.setServer("dr.lan", 1883);
	client.setCallback(callback);

	xTaskCreatePinnedToCore(taskmqtt, "MQTT", 2048, NULL, 1, NULL, PRO_CPU_NUM);
}

void processEvent(void *buf, int telegramLen) {
	client.publish("doorbell/events/scs", buf, telegramLen);
}
```

## Integration: Webhook to MQTT

The Nuki Opener doesn’t support MQTT out of the box, but the Nuki Bridge can
send Webhook requests. In a few lines of Go, you can forward what the Nuki
Bridge sends to MQTT:

```go
package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

func nukiBridge() error {
	opts := mqtt.NewClientOptions().AddBroker("tcp://dr.lan:1883")
	opts.SetClientID("nuki2mqtt")
	opts.SetConnectRetry(true)
	mqttClient := mqtt.NewClient(opts)
	if token := mqttClient.Connect(); token.Wait() && token.Error() != nil {
		return fmt.Errorf("MQTT connection failed: %v", token.Error())
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/nuki", func(w http.ResponseWriter, r *http.Request) {
		b, err := ioutil.ReadAll(r.Body)
		if err != nil {
			log.Print(err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		mqttClient.Publish(
			"zkj-nuki/webhook", // topic
			0, // qos
			true, // retained
			string(b)) // payload
	})

	return http.ListenAndServe(":8319", mux)
}

func main() {
	if err := nukiBridge(); err != nil {
		log.Fatal(err)
	}
}
```

See [Nuki’s Bridge HTTP-API](https://developer.nuki.io/t/bridge-http-api/26)
document for details on how to configure your bridge to send webhook callbacks.

## Step 3. Express your logic

[Home Assistant](https://www.home-assistant.io/) and
[Node-RED](https://nodered.org/) are both popular options, but also large
software packages.

Personally, I find it more fun to express my logic directly in a full
programming language (Go).

I call the [resulting program `regelwerk` (“collection of
rules”)](https://github.com/stapelberg/regelwerk). The program consists of:

1. various control loops that progress independently from each other
1. an MQTT message dispatcher feeding these control loops
1. a debugging web interface to visualize state

This architecture is by no means a new approach: as
[moquette](https://github.com/rs/moquette) describes it, this is to MQTT what
`inetd` is to IP. I find `moquette`’s one-process-per-message model to be too
heavyweight and clumsy to deploy to https://gokrazy.org, so `regelwerk` is
entirely in-process and a single, easy-to-deploy binary, both to computers for
notifications, or to headless Raspberry Pis.

### regelwerk: control loops definition

`regelwerk` defines a control loop as a stateful function that accepts an event
(from MQTT) and returns messages to publish to MQTT, if any:

```go
type controlLoop interface {
	sync.Locker

	StatusString() string // for human introspection

	ProcessEvent(MQTTEvent) []MQTTPublish
}

// Like mqtt.Message, but with timestamp
type MQTTEvent struct {
	Timestamp time.Time
	Topic     string
	Payload   interface{}
}

// Parameters for mqtt.Client.Publish()
type MQTTPublish struct {
	Topic    string
	Qos      byte
	Retained bool
	Payload  interface{}
}
```

### regelwerk: MQTT dispatcher

Our MQTT message handler dispatches each incoming message to all control loops,
in one goroutine per message and loop. With typical message volumes on a
personal MQTT bus, this is a simple yet effective design that brings just enough
isolation.

```go
type mqttMessageHandler struct {
	dryRun bool
	loops  []controlLoop
}

func (h *mqttMessageHandler) handle(client mqtt.Client, m mqtt.Message) {
	log.Printf("received message %q on %q", m.Payload(), m.Topic())
	ev := MQTTEvent{
		Timestamp: time.Now(), // consistent for all loops
		Topic:     m.Topic(),
		Payload:   m.Payload(),
	}

	for _, l := range h.loops {
		l := l // copy
		go func() {
			// For reliability, we call each loop in its own goroutine
			// (yes, one per message), so that when one loop gets stuck,
			// the others still make progress.
			l.Lock()
			results := l.ProcessEvent(ev)
			l.Unlock()
			if len(results) == 0 {
				return
			}
			for _, r := range results {
				log.Printf("publishing: %+v", r)
				if !h.dryRun {
					client.Publish(r.Topic, r.Qos, r.Retained, r.Payload)
				}
			}
			// …input/output logging omitted for brevity…
		}()
	}
}
```

### regelwerk: control loop example

Now that we have the definition and dispatching out of the way, let’s take a
look at an actual example control loop.

This control loops looks at whether my PC is unlocked (in use) or whether my
phone is home, and then turns off/on my stereo speakers accordingly.

The inputs come from
[runstatus](https://github.com/stapelberg/zkj-nas-tools/blob/master/runstatus/runstatus.go)
and
[dhcp4d](https://github.com/rtr7/router7/blob/c30bf38438b3ba00ae13dff914f0ef4f05684250/cmd/dhcp4d/dhcp4d.go#L405-L433),
the output goes to a Sonoff S26 Smart Power Plug running
[Tasmota](https://tasmota.github.io/docs/).

```go
type avrPowerLoop struct {
	statusLoop // for l.statusf() debugging

	midnaUnlocked          bool
	michaelPhoneExpiration time.Time
}

func (l *avrPowerLoop) ProcessEvent(ev MQTTEvent) []MQTTPublish {
	// Update loop state based on inputs:
	switch ev.Topic {
	case "runstatus/midna/i3lock":
		var status struct {
			Running bool `json:"running"`
		}
		if err := json.Unmarshal(ev.Payload.([]byte), &status); err != nil {
			l.statusf("unmarshaling runstatus: %v", err)
			return nil
		}
		l.midnaUnlocked = !status.Running

	case "router7/dhcp4d/lease/Michaels-iPhone":
		var lease struct {
			Expiration time.Time `json:"expiration"`
		}
		if err := json.Unmarshal(ev.Payload.([]byte), &lease); err != nil {
			l.statusf("unmarshaling router7 lease: %v", err)
			return nil
		}
		l.michaelPhoneExpiration = lease.Expiration

	default:
		return nil // event did not influence our state
	}

	// Publish desired state changes:
	now := ev.Timestamp
	phoneHome := l.michaelPhoneExpiration.After(now)
	anyoneHome := l.midnaUnlocked || (now.Hour() > 8 && phoneHome)
	l.statusf("midnaUnlocked=%v || (now.Hour=%v > 8 && phoneHome=%v)",
		l.midnaUnlocked, now.Hour(), phoneHome)

	payload := "OFF"
	if anyoneHome {
		payload = "ON"
	}
	return []MQTTPublish{
		{
			Topic:    "cmnd/tasmota_68462F/Power",
			Payload:  payload,
			Retained: true,
		},
	}
}

```

## Conclusion

I like the Pub/Sub pattern for home automation, as it nicely uncouples all
components.

It’s a shame that standards such as [The Homie
convention](https://homieiot.github.io/) aren’t more widely supported, but it
looks like software makes up for that via configuration options.

There are plenty of existing integrations that should cover most needs.

Ideally, more Smart Home and IOT vendors would add MQTT support out of the box,
like [Shelly](https://shelly.cloud/).
