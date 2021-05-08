---
layout: post
title:  "Measure and reduce keyboard input latency with QMK on the Kinesis Advantage"
date:   2021-05-08 15:57:00 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1391031601182695426"
tags:
- kinX
---

Over the last few years, I worked on a few projects around keyboard input latency:

In 2018, I introduced the [kinX keyboard controller with 0.2ms of input
latency](/posts/2018-04-17-kinx/).

In 2020, I introduced the [kinT keyboard
controller](/posts/2020-07-09-kint-kinesis-keyboard-controller/), which works
with a wide range of Teensy micro controllers, and both the old KB500 and the
newer KB600 Kinesis Advantage models.

While the 2018 kinX controller had built-in latency measurement, I was starting
from scratch with the kinT design, where I wanted to use the QMK keyboard
firmware instead of my own firmware.

That got me thinking: instead of adjusting the firmware to self-report latency
numbers, is there a way we can do latency measurements externally, ideally
without software changes?

This article walks you through how to set up a measurement environment for your
keyboard controller’s input latency, be it original or self-built. I’ll use a
Kinesis Advantage keyboard, but this approach should generalize to all
keyboards.

I will explain a few common causes for extra keyboard input latency and show you
how to fix them in the QMK keyboard firmware.

## Measurement setup

The idea is to connect a [Teensy 4.0](https://www.pjrc.com/store/teensy40.html)
(or similar), which simulates pressing the Caps Lock key and measures the
duration until the keypress resulted in a Caps Lock LED change.

We use the Caps Lock key because it is one of the few keys that results in an
LED change.

Here you can see the Teensy 4.0 connected to the [kinT
controller](https://github.com/kinx-project/kint/), connected to a laptop:

{{< img src="endtoend_measure_featured.jpg" alt="measurement setup" >}}

### Enable the debug console in QMK

Let’s get our QMK working copy ready for development! I like to work in a
separate QMK working copy per project:

```
% docker run -it -v $PWD:/usr/src archlinux
# pacman -Sy && pacman -S qmk make which diffutils
# cd /usr/src
# qmk clone -b develop qmk/qmk_firmware $PWD/qmk-input-latency
# cd qmk-input-latency
```

I compile the firmware for my keyboard like so:
```
# make kinesis/kint36:stapelberg
```

To enable the debug console, I need to edit my QMK keymap `stapelberg` by
updating `keyboards/kinesis/keymaps/stapelberg/rules.mk` to contain:

```
CONSOLE_ENABLE = yes
```

After compiling and flashing the firmware, the `hid_listen` tool will detect the
device and listen for QMK debug messages:

```
% sudo hid_listen
Waiting for device:...
Listening:
```

### Finding the pins

Let’s locate the Caps Lock key’s corresponding row and column in our keyboard matrix!

We can make QMK show which keys are recognized after each scan by adding to
`keyboards/kinesis/keymaps/stapelberg/keymap.c` the following code:

```c
void keyboard_post_init_user() {
  debug_config.enable = true;
  debug_config.matrix = true;
}
```

Now we’ll see in the `hid_listen` output which key is active when pressing Caps Lock:

```
r/c 01234567
00: 00100000
01: 00000000
[…]
```

For our kinT controller, Caps Lock is on QMK matrix row 0, column 2.

In the [kinT
schematic](https://github.com/kinx-project/kint/blob/master/schematic-v2021-04-25.pdf),
the corresponding signals are `ROW_EQL` and `COL_2`.

To hook up the Teensy 4.0 latency measurement driver, I am making the following
GPIO connections to the kint36, kint41 or kint2pp (with voltage converter!)
keyboard controllers:

| driver 4.0 | signal          | kint36, kint41 | kint2pp (5V!) |
|------------|-----------------|----------------|---------------|
| GND        | `GND`           | GND            | GND           |
| pin 10     | `ROW_EQL`       | pin 8          | D7            |
| pin 11     | `COL_2`         | pin 15         | F7            |
| pin 12     | `LED_CAPS_LOCK` | pin 12         | C1            |

{{< note >}}

**Note:** Unfortunately, the signals are not available on the Teensy 4.x dev kit
[NXP i.MX RT1060 Evaluation Kit
(`MIMXRT1060-EVK`)](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/mimxrt1060-evk-i-mx-rt1060-evaluation-kit:MIMXRT1060-EVK). Here,
pin 8 (`B1_00`) is used for the LVDI interface instead.

{{< /note >}}

### Eager Caps Lock LED {#eagercaps}

When the host signals to the keyboard that Caps Lock is now turned on, the QMK
firmware first updates a flag in the USB interrupt handler, but only updates the
Caps Lock LED pin after the next matrix scan has completed.

This is fine in normal usage, but our measurement readings will get more precise
if we immediately update the Caps Lock LED pin. We can do this in
`set_led_transfer_cb` in `tmk_core/protocol/chibios/usb_main.c`, which is called
from the USB interrupt handler:

{{< highlight c "hl_lines=12-16" >}}
#include "gpio.h"

static void set_led_transfer_cb(USBDriver *usbp) {
    if (usbp->setup[6] == 2) { /* LSB(wLength) */
        uint8_t report_id = set_report_buf[0];
        if ((report_id == REPORT_ID_KEYBOARD) || (report_id == REPORT_ID_NKRO)) {
            keyboard_led_state = set_report_buf[1];
        }
    } else {
        keyboard_led_state = set_report_buf[0];
    }
    if ((keyboard_led_state & 2) != 0) {
      writePinLow(C7); // turn on CAPS_LOCK LED
    } else {
      writePinHigh(C7); // turn off CAPS_LOCK LED
    }
}
{{< /highlight >}}

### Host side (Linux)

On the USB host, i.e. the Linux computer, I switch to a [Virtual Terminal
(VT)](https://en.wikipedia.org/wiki/Virtual_console) by stopping my login
manager (killing my current graphical session!):

```
% sudo systemctl stop gdm
```

With the Virtual Terminal active, we know that the Caps Lock key press will be
handled entirely in kernel driver code without having to round-trip to
userspace.

We can verify this by collecting stack traces with {{< man name="bpftrace"
section="8" >}} when the kernel executes the [`kbd_event` function in
`drivers/tty/vt`](https://elixir.bootlin.com/linux/v5.12/source/drivers/tty/vt/keyboard.c#L1521):

```
% sudo bpftrace -e 'kprobe:kbd_event { @[kstack] = count(); }'
```

After pressing Caps Lock and cancelling the `bpftrace` process, you should see a
stack trace.

I then measured the baseline end-to-end latency, using [my `measure-fw`
firmware](https://github.com/kinx-project/measure-fw) running on the FRDM-K66F
eval kit, a cheap and widely available USB 2.0 High Speed device. The firmware
measures the latency between a button press and the USB HID report for the Caps
Lock LED, but without any additional matrix scanning delay or similar:

```
% cat /dev/ttyACM0
sof=74 μs	report=393 μs
sof=42 μs	report=512 μs
sof=19 μs	report=512 μs
sof=39 μs	report=488 μs
sof=20 μs	report=518 μs
sof=90 μs	report=181 μs
sof=42 μs	report=389 μs
sof=7 μs	report=319 μs
```

This is the quickest reaction we can get out of this computer. Anything on top
(e.g. X11, application) will be slower, so this measurement establishes a lower
bound.

### Code to simulate key presses and take measurements

I’m running the [latencydriver Arduino
sketch](https://github.com/kinx-project/latencydriver), with the Arduino IDE
configured for:

Teensy 4.0 (USB Type: Serial, CPU Speed: 600 MHz, Optimize: Faster)

Here’s how we set up the pins in the measurement driver Teensy 4.0:

```c
void setup() {
  Serial.begin(9600);

  // Connected to kinT pin 15, COL_2
  pinMode(11, OUTPUT);
  digitalWrite(11, HIGH);

  // Connected to kinT pin 8, ROW_EQL.
  // Pin 11 will be high/low in accordance with pin 10
  // to simulate a key-press, and always high (unpressed)
  // otherwise.
  pinMode(10, INPUT_PULLDOWN);
  attachInterrupt(digitalPinToInterrupt(10), onScan, CHANGE);

  // Connected to the kinT LED_CAPS_LOCK output:
  pinMode(12, INPUT_PULLDOWN);
  attachInterrupt(digitalPinToInterrupt(12), onCapsLockLED, CHANGE);
}
```

In order to make a key read as pressed, we need to connect the column with the
row in the keyboard matrix, but only when the column is scanned. We do that in
the interrupt handler like so:

```c
bool simulate_press = false;

void onScan() {
  if (simulate_press) {
    // connect row scan signal with column read
    digitalWrite(11, digitalRead(10));
  } else {
    // always read not pressed otherwise
    digitalWrite(11, HIGH);
  }
}
```

In our text interface, we can now start a measurement like so:

```c
caps_lock_on_to_off = capsLockOn();
Serial.printf("# Caps Lock key pressed (transition: %s)\r\n",
  caps_lock_on_to_off ? "on to off" : "off to on");
simulate_press = true;
t0 = ARM_DWT_CYCCNT;
emt0 = 0;
eut0 = 0;
```

The next keyboard matrix scan will detect the key as pressed, send the HID
report to the OS, and when the OS responds with its HID report containing the
Caps Lock LED status, our Caps Lock LED interrupt handler is called to finish
the measurement:

```c
void onCapsLockLED() {
  const uint32_t t1 = ARM_DWT_CYCCNT;
  const uint32_t elapsed_millis = emt0;
  const uint32_t elapsed_micros = eut0;
  uint32_t elapsed_nanos = (t1 - t0) / cycles_per_ns;

  Serial.printf("# Caps Lock LED (pin 12) is now %s\r\n", capsLockOn() ? "on" : "off");
  Serial.printf("# %u ms == %u us\r\n", elapsed_millis, elapsed_micros);
  Serial.printf("BenchmarkKeypressToLEDReport 1 %u ns/op\r\n", elapsed_nanos);
  Serial.printf("\r\n");
}
```



### Running measurements

Connect the Teensy 4.0 to your computer and open its USB serial console:

```shell
% screen /dev/ttyACM0 115200
```

You should be greeted by a welcome message:
```
# kinT latency measurement driver
#   t  - trigger measurement
```

To save your measurements to file, use `C-a H` in `screen` to make it write to
file `screenlog.0`.

Press `t` a few times to trigger a few measurements and close `screen` using
`C-a k`.

You can summarize the measurements using
[`benchstat`](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat):

```
% benchstat screenlog.0
name                 time/op
KeypressToLEDReport  1.82ms ±20%
```


### Scan-to-scan delay {#scantoscandelay}

The measurement output on the USB serial console also contains the matrix
scan-to-scan delay:

```
# scan-to-scan delay: 422475 ns
```

Each keyboard matrix scan turns on each row one-by-one, then reads all the columns.

This means that in each matrix scan, `ROW_EQL` will be set high once, then low again.

The Teensy 4.0 measures scan-to-scan delay by timing the activations of
`ROW_EQL`.

We can verify this approach by making QMK self-report its scan rate. Enable the
matrix scan rate debug option in `keyboards/kinesis/keymaps/stapelberg/config.h`
like so:

```c
#pragma once

#define DEBUG_MATRIX_SCAN_RATE
```

Using `hid_listen` we can now see the following QMK debug messages:

```
% sudo hid_listen
Waiting for new device:..
Listening:
matrix scan frequency: 2300
matrix scan frequency: 2367
matrix scan frequency: 2367
```

A matrix scan rate/frequency of 2367 scans per second corresponds to 422μs per
scan:

```
1000000 μs / 2367 scans/second = 422μs
```

Yet another way of verifying the approach is by short-circuiting an end-to-end
measurement with a one-line change in our QMK keyboard code:

```c
bool process_action_kb(keyrecord_t *record) {
#define LED_CAPS_LOCK LINE_PIN12
#define ledTurnOn writePinLow
  ledTurnOn(LED_CAPS_LOCK);
  return true;
}
```

Repeating the measurements, this gives us:

```
% benchstat screenlog.0     
name                 time/op
KeypressToLEDReport  693µs ±26%
```

This value is between [0, 2 * 422μs] because a key might be pressed
after it was already scanned by the in-progress matrix scan, meaning it will
need to wait until the next scan completed (!) before it can be registered as
pressed.


## Measurement harness

Now that we have our general measurement environment all set up, it’s time to
connect our Teensy 4.0 to a few different keyboard controllers!

### kint36, kint41: GPIO

If you have an un-soldered micro controller you want to measure, setup is easy:
just connect all GPIOs to the Teensy 4.0 latency test driver directly! I’m using
this for the `kint36` and `kint41`:

{{< img src="kint41_gpio_measure.jpg" alt="GPIO measurement" >}}

(build in `/home/michael/kinx/kintpp/rebased`, last results in `screenlog-kint36-eager-caps.0`)

### kint2pp: 5V

Because the Teensy++ uses 5V logic levels, we need to convert the levels from/to
3.3V. This is easily done using e.g. the [SparkFun Logic Level Converter
(Bi-Directional)](https://www.sparkfun.com/products/12009) on a breadboard:

{{< img src="kint2pp_levelshifter.jpg" alt="kint2pp with level shifter" >}}

### kinX: FPC

But what if you have a design where the micro controller doesn’t come
standalone, only soldered to a keyboard controller board, such as my earlier
kinX controller?

You can use a spare FPC connector ([Molex
39-53-2135](https://octopart.com/39-53-2135-molex-7670149?r=sp)) and solder
jumper wires to the pins for `COL_2` and `ROW_EQL`. For Caps Lock and Ground,
I soldered jumper wires to the board:

{{< img src="kinx_fpc_measure.jpg" alt="kinX measurement" >}}

{{< note >}}

**Note:** The
[adapter-use-kb600-with-kb500-controller](https://github.com/kinx-project/adapter-use-kb600-with-kb500-controller)
unfortunately cannot be used for this purpose: the required pins are connected
to the ground plane.

{{< /note >}}

### Original Kinesis controller

But what if you don’t want to solder jumper wires directly to the board?

The least invasive method is to connect the FPC connector break-out, and hold
probe heads onto the contacts while doing your measurements:

{{< img src="kinesis_original_measure.jpg" alt="kinesis original controller measurement" >}}


## QMK input latency

Now that the measurement hardware is set up, we can go through the code.

The following sections each cover one possible contributor to input latency.

### Eager debounce {#eagerdebounce}

Key switches don’t generate a clean signal when pressed, instead they show a
ripple effect. Getting rid of this ripple is called
[debouncing](https://en.wiktionary.org/wiki/debounce), and every keyboard
firmware does it.

See [QMK’s documentation on the Debounce
API](https://beta.docs.qmk.fm/using-qmk/software-features/feature_debounce_type)
for a good explanation of the differences between the different debounce approaches.

QMK’s default debounce algorithm `sym_defer_g` is chosen very cautiously. I
don’t know what the criteria are specifically for which types of key switches
suffer from noise and therefore need the `sym_defer_g` algorithm, but I know
that Cherry MX key switches with diodes like used in the Kinesis Advantage don’t
have noise and hence can use the other debounce algorithms, too.

While the default `sym_defer_g` debounce algorithm is robust, it also adds 5ms
of input latency:

```
% benchstat screenlog-kint36.0
name                 time/op
KeypressToLEDReport  7.61ms ± 8%
```

For lower input latency, we need an `eager` algorithm. Specifically, I am
chosing the `sym_eager_pk` debounce algorithm by adding to my
`keyboards/kinesis/kint36/rules.mk`:

```
DEBOUNCE_TYPE = sym_eager_pk
```

Now, the extra 5ms are gone:

```
% benchstat screenlog-kint36-eager.0
name                 time/op
KeypressToLEDReport  2.12ms ±16%
```

Example change: https://github.com/qmk/qmk_firmware/pull/12626

### Quicker USB polling interval {#quickusbpolling}

The USB host (computer) divides time into fixed-length segments called frames:

* USB Full Speed (USB 1.0) uses frames that are 1ms each.
* USB High Speed (USB 2.0) introduces micro frames, which are 125μs.

Each USB device specifies in its device descriptor how frequently (in frames)
the device should be polled. The [quickest polling
rate](https://en.wikipedia.org/wiki/USB_(Communications)#Transaction_latency)
for USB 1.0 is 1 frame, meaning the device can send data after at most
1ms. Similarly, for USB 2.0, it’s 1 micro frame, i.e. send data every 125μs.

Of course, a quicker polling rate also means occupying resources on the USB bus
which are then no longer available to other devices. On larger USB hubs, this
might mean fewer devices can be used concurrently. The specifics of this
limitation depend on a lot of other factors, too. The polling rate plays a role,
in combination with the max. packet size and the number of endpoints.

Note that we are only talking about concurrent device usage, not about hogging
bandwidth: the bulk transfers that USB mass storage devices use are not any
slower in my tests. I achieve about 37 MiB/s with or without the kint41 USB 2.0
High Speed controller with `bInterval=1` present.

Even connecting two kint41 controllers at the same time still leaves enough
resources to use a Logitech C920 webcam in its most bandwidth-intensive pixel
format and resolution. The same cannot be said for e.g. NXP’s LPC-Link2 debug
probe.

{{< note >}}

**Open question:** Would declaring multiple alternate settings in our USB device
descriptor dynamically reduce resource usage? Our keyboard could offer one
alternate setting with `bInterval=1` and one with `bInterval=10`.

{{< /note >}}

To display the configured interval, the Linux kernel provides a debug pseudo file:

```
% sudo cat /sys/kernel/debug/usb/devices

[…]
T:  Bus=01 Lev=02 Prnt=09 Port=02 Cnt=02 Dev#= 53 Spd=480  MxCh= 0
D:  Ver= 2.00 Cls=00(>ifc ) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
P:  Vendor=1209 ProdID=345c Rev= 0.01
S:  Manufacturer="https://github.com/stapelberg"
S:  Product="kinT (kint41)"
C:* #Ifs= 3 Cfg#= 1 Atr=a0 MxPwr=500mA
I:* If#= 0 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=01 Prot=01 Driver=usbhid
E:  Ad=81(I) Atr=03(Int.) MxPS=   8 Ivl=125us
I:* If#= 1 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=00 Prot=00 Driver=usbhid
E:  Ad=82(I) Atr=03(Int.) MxPS=  32 Ivl=125us
I:* If#= 2 Alt= 0 #EPs= 2 Cls=03(HID  ) Sub=00 Prot=00 Driver=usbhid
E:  Ad=83(I) Atr=03(Int.) MxPS=  32 Ivl=125us
E:  Ad=04(O) Atr=03(Int.) MxPS=  32 Ivl=125us
[…]
```

Alternatively, you can display the USB device descriptor using e.g. `sudo lsusb
-v -d 1209:345c` and interpret the `bInterval` setting yourself.

The above shows the best case: a USB 2.0 High Speed device (`Spd=480`) with
`bInterval=1` in its device descriptor (`Iv=125us`).

The original Kinesis Advantage 2 keyboard controller (KB600) uses USB 2.0, but
in Full Speed mode (`Spd=12`), i.e. no faster than USB 1.1. In addition, they
specify `bInterval=10`, which results in a 10ms polling interval (`Ivl=10ms`):

```
T:  Bus=01 Lev=02 Prnt=09 Port=02 Cnt=02 Dev#= 52 Spd=12   MxCh= 0
D:  Ver= 2.00 Cls=00(>ifc ) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
P:  Vendor=29ea ProdID=0102 Rev= 1.00
S:  Manufacturer=Kinesis
S:  Product=Advantage2 Keyboard
C:* #Ifs= 3 Cfg#= 1 Atr=a0 MxPwr=100mA
I:* If#= 0 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=01 Prot=02 Driver=usbhid
E:  Ad=83(I) Atr=03(Int.) MxPS=   8 Ivl=10ms
I:* If#= 1 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=01 Prot=01 Driver=usbhid
E:  Ad=84(I) Atr=03(Int.) MxPS=   8 Ivl=2ms
I:* If#= 2 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=00 Prot=00 Driver=usbhid
E:  Ad=85(I) Atr=03(Int.) MxPS=   8 Ivl=2ms
```

My recommendation:

* With USB 1.1 Full Speed, definitely specify `bInterval=1`. I’m not aware of
  any downsides.
* With USB 2.0 High Speed, I also think `bInterval=1` is a good choice, but I am
  less certain. If you run into trouble, reduce to `bInterval=3` and send me a
  message :)

For details on measuring, see [Appendix B: USB polling interval (device
side)](#appendixb).

Example change: https://github.com/qmk/qmk_firmware/pull/12625

### Faster matrix scan {#fastmatrixscan}

The purpose of a keyboard controller is reporting pressed keys after scanning
the key matrix. The more scans a keyboard controller can do per second, the
faster it can react to your key press.

How many scans your controller does depends on multiple factors:

* The clock speed of your micro controller. It’s worth checking if your micro
  controller model supports running at faster clock speeds, or upgrading your
  keyboard to a faster model to begin with. There is a point of diminishing
  returns, which I would guess is at ≈100 MHz. Comparing e.g. the kint36 at 120
  MHz vs. 180 MHz, the difference in scan-to-scan is 5μs.

* How much other code your firmware runs aside from matrix scanning. If you
  enable any non-standard QMK features, or even self-written code, it’s worth
  disabling and measuring.
* Whether you run scans back-to-back or e.g. synchronized with USB
  start-of-frame interrupts. QMK runs scans back-to-back, so this point is only
  relevant for other firmwares.
* How long you need to sleep to let the signal settle. Reducing your sleep times
  results in more scans per second, but if you don’t sleep long enough, you’ll
  see ghost key presses. See also the next section about Shorter sleeps.

For details on measuring, see the [Scan-to-scan delay section](#scantoscandelay)
above.

I also tried configuring the GPIOs to be faster to see if that would reduce the
required unselect delay, but unfortunately there was no difference between the
default setting and the fastest setting: drive strength 6 (`DSE=6`), fast
slew rate (`SRE=1`), 200 MHz (`SPEED=3`).

### Shorter sleeps {#shortsleeps}

QMK calls [ChibiOS’s `chThdSleepMicroseconds`
function](https://www.chibios.org/dokuwiki/doku.php?id=chibios:documentation:books:rt:kernel_threading#delays_api)
in its matrix scanning code. This function unfortunately has a rather long
shortest sleep duration of 1 ChibiOS tick: if you tell it to sleep less than
100μs, it will still sleep at least 100μs!

This is a problem on controllers such as the kint41, where we want to sleep for
only 10μs.

The length of a ChibiOS tick is determined by how the ARM SysTick timer is set
up on the specific micro controller you’re using. While the SysTick timer itself
could be configured to fire more frequently, it is not advisable to shorten
ChibiOS ticks: `chSysTimerHandlerI()` [must be executable in less than one
tick](http://forum.chibios.org/viewtopic.php?t=3712#p27851).

Instead, I found it easier to implement short delays by busy-looping until the
ARM Cycle Counter Register (`CYCCNT`) indicates enough time has passed. Here’s
an example from `keyboards/kinesis/kint41/kint41.c`:

```c
// delay_inline sleeps for |cycles| (e.g. sleeping for F_CPU will sleep 1s).
//
// delay_inline assumes the cycle counter has already been initialized and
// should not be modified, i.e. is safe to call during keyboard matrix scan.
//
// ChibiOS enables the cycle counter in chcore_v7m.c.
static void delay_inline(const uint32_t cycles) {
  const uint32_t start = DWT->CYCCNT;
  while ((DWT->CYCCNT - start) < cycles) {
    // busy-loop until time has passed
  }
}

void matrix_output_unselect_delay(void) {
  // 600 cycles at 0.6 cycles/ns == 1μs
  const uint32_t cycles_per_us = 600;
  delay_inline(10 * cycles_per_us);
}
```

Of course, the cycles/ns value is specific to the frequency at which your micro
controller runs, so this code needs to be adjusted for each platform.

## Results

With the QMK keyboard firmware configured for lowest input latency, how do the
different Kinesis keyboard controller compare? Here are my measurements:

| model    | CPU speed | USB poll interval | scan-to-scan | scan rate    | caps-to-report |
|----------|-----------|-------------------|--------------|--------------|----------------|
| kint41   | 600 MHz   | 125μs             | 181μs        | 5456 scans/s | 930µs ±17%     |
| kinX     | 120 MHz   | 125μs             | 213μs        | 4694 scans/s | 953µs ±15%     |
| kint36   | 180 MHz   | 1000μs            | 444μs        | 2252 scans/s | 1.97ms ±15%    |
| kint2pp  | 16 MHz    | 1000μs            | 926μs        | 1078 scans/s | 3.27ms ±32%    |
| original | 60 MHz    | 10000μs           | 1936μs       | 516 scans/s  | 13.6ms ±21%    |

The changes required to obtain these results are included since QMK 0.12.38
(2021-04-20).

[kint41 support is being added](https://github.com/kinx-project/kint/issues/5)
with all required changes to begin with, but still in progress.

The following sections go into detail about the results.

### kint41

I am glad that the most recent Teensy 4.1 micro controller takes the lead! The
kinX controller achieved similar numbers, but was quite difficult to build, so
few people ended up using it.

The key improvement compared to the Teensy 3.6 is the now-available USB 2.0 High
Speed, and the powerful clock speed of 600 MHz allows for an even faster matrix
scan rate.

### kinX

In my [previous article about the kinX
controller](/posts/2018-04-17-kinx-keyboard-controller/), I measured the kinX
scan delay as ≈100μs. During my work on this article, I learnt that the ≈100μs
figure was misleading: the measurement code turned off interrupts to measure
only the scan function. While that is technically correct, it is not a useful
measure, as in practice, [interrupts should not be
disabled](https://github.com/kinx-project/mk66f-fw/commit/cae21f3d13331061bcd8c9d411adbb0d7d8c0ae4),
and the scanning function is interrupted frequently enough that it comes in at
≈208μs.

I also fixed the USB polling interval in the kinX firmware, which [wasn’t set to
`bInterval=1`](https://github.com/kinx-project/mk66f-fw/commit/b40ae0287ed3b042886e29621dbeecefba1c148b).

### Original Kinesis

The original keyboard controller that the Kinesis Advantage 2 (KB600) keyboard
comes with uses [an AT32UC3B0256 micro
controller](https://www.microchip.com/wwwproducts/en/AT32UC3B0256#datasheet-toggle)
which is clocked at 60 MHz, but the measured input latency is much higher than
even the slowest kint controller (kint2pp at 16 MHz). What gives?

Here’s what we can deduce without access to their firmware:

1. They seem to be using an [eager debounce algorithm](#eagerdebounce) (good!),
   otherwise we would observe even higher latency.
1. Their [USB polling interval](#quickusbpolling) setting (`bInterval=10`) is
   excessively high, even more so because they are using USB Full Speed with
   longer USB frames. I would recommend they change it to `bInterval=1` for up
   to 10ms less input latency!
1. The matrix scan rate is twice as slow as with my kint2pp. I can’t say for
   sure why this is. Perhaps their firmware does a lot of other things between
   matrix scans.

Note that we could not apply the [Eager Caps Lock LED](#eagercaps) firmware
change to the original controller, which is why the measurement variance is
±21%. This variance includes ± 1.9ms for finishing a matrix scan before updating
the LED state.

## Conclusion

After analyzing the different controllers in my measurement environment, I think
the following factors play the largest role in keyboard input latency, ordered
by importance:

1. Does the firmware use an [eager debounce algorithm](#eagerdebounce)?
1. Does the device specify a [quick USB polling rate (`bInterval`
   setting)](#quickusbpolling)?
1. Is the matrix scan frequency in the expected range, or are there unexpected
   slow-downs?

Hopefully, this article gives you all the tools you need to measure and reduce
keyboard input latency of your own keyboard controller!

## Appendix A: isitsnappy

The iPhone app [Is It Snappy?](https://isitsnappy.com/) records video using the
iPhone’s 240 fps camera and allows you to mark the frame that starts
respectively ends the measurement.

The app does a good job of making this otherwise tedious process of navigating a
video frame by frame much more pleasant.

However, for measuring keyboard input latency, I think this approach is futile:

* The resolution is too imprecise. At 240 fps, that means each frame represents
  4.6ms of time, which is already higher than the input latency of our slowest
  micro controller.
* Visually deciding whether a key switch is pressed or not pressed, at
  frame-perfect precision, seems impossible to me.

I believe the app can work, provided the latency you want to measure is really
high. But with the devices covered in this article, the app couldn’t measure
even 10ms of injected input latency.

## Appendix B: USB polling interval (device side) {#appendixb}

You can also verify the USB polling interval on the device side. In the SOF
(Start Of Frame) interrupt in `tmk_core/protocol/chibios/usb_main.c`, we can
print the cycle delta to the previous SOF callback, every second:

```c
#include "timer.h"

static uint32_t last_sof = 0;
static uint32_t sof_timer = 0;
void kbd_sof_cb(USBDriver *usbp) {
  (void)usbp;

  uint32_t now = DWT->CYCCNT;
  uint32_t delta = now - last_sof;
  last_sof = now;

  uint32_t timer_now = timer_read32();
  if (TIMER_DIFF_32(timer_now, sof_timer) > 1000) {
    sof_timer = timer_now;
    dprintf("sof delta: %u cycles", delta);
  }
}
```

Using `hid_listen`, we expect to see ≈75000 cycles of delta, which
corresponds to the 125μs microframe latency of USB 2.0 High Speed with
`bInterval=1` in the USB device descriptor:

125μs * 1000 * 0.6 cycles/ns = 75000 cycles

