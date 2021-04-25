---
layout: post
title:  "Linux and USB virtual serial devices (CDC ACM)"
date:   2021-04-27 08:18:00 +02:00
categories: Artikel
---

During my work on [Teensy 4.1](https://www.pjrc.com/store/teensy41.html) support
in [ChibiOS](https://en.wikipedia.org/wiki/ChibiOS/RT) for the QMK keyboard
firmware, I noticed that ChibiOS’s virtual serial device USB demo would
sometimes print garbled output, and that I would never see the ChibiOS shell
prompt.

This article walks you through diagnosing and working around this issue, in the
hope that it helps others who are working with micro controllers and USB virtual
serial devices.

## Background

Serial interfaces are often the easiest option when working with micro
controllers to print text: you only connect `GND` and the micro controller’s
serial `TX` pin to a USB-to-serial converter. The `RX` pin is only needed when
you want to send text to the micro controller as well.

While conceptually simple, the requirement for an extra piece of hardware
(USB-to-serial adapter) is annoying. If your micro controller has a working USB
interface and USB stack, a popular alternative is for the micro controller to
provide a virtual serial device via USB.

This way, you just need one USB cable between your micro controller and
computer, reusing the same connection you already use for programming the
device.

A popular choice within this solution is to provide a device conforming to the
USB Communications Device Class (CDC) standard, specifically its Abstract
Control Model (ACM), which is typically used for modem hardware.

On Linux, these devices show up as e.g. `/dev/ttyACM0`. In case you’re
wondering: `/dev/ttyUSB0` device names are used by more specific drivers
(vendor-specific). The blog post [What is the difference between /dev/ttyUSB and
/dev/ttyACM?](https://rfc1149.net/blog/2013/03/05/what-is-the-difference-between-devttyusbx-and-devttyacmx/)
goes into a lot more detail.

## ModemManager

One unfortunate side-effect of using a modem standard to provide a generic
serial device is that modem-related software might mistake our micro controller
for a modem.

Use the following command to disable ModemManager until the next reboot, which
otherwise might open and probe any new serial devices:

```
% sudo systemctl mask --runtime --now ModemManager
```

## Problem statement

With a regular, non-USB serial interface, you can send data at any time. If
nobody is receiving the data on the other end, the micro controller doesn’t care
and still writes serial data.

When using the ChibiOS shell with a regular serial interface, this means that if
you open the serial interface too late, you will not see the ChibiOS shell
prompt. But, if you have the serial interface already opened when powering on
your device, you will be greeted by ChibiOS’s shell prompt:

```
ChibiOS/RT Shell
ch> 
```

With a USB serial, however, the host will not transfer data from the device
until the serial interface is opened. This means that writes to the USB serial
can block, whereas writes to the UART serial will not block but may go ignored
if nobody is listening.

So when I open the USB serial interface, I would expect to see the ChibiOS shell
prompt like above. Instead, I would often not see any prompt at all, and I would
even sometimes see garbled output like this:

```
cch> biOS/RT She
```

## USB analysis with Wireshark

[Wireshark](https://en.wikipedia.org/wiki/Wireshark) allows us to analyze USB
traffic in combination with the `usbmon` Linux kernel module.

Looking through the captured packets, I noticed unexpected packets from the host
(computer) to the device (micro controller), specifically containing the
following bytes:

1. hex `0xa` = ASCII `\n`
1. hex `0xd` = ASCII `\r`

Seeing any packets in this direction is unexpected, because I am only opening
the serial interface **for reading**, and I am not consciously sending
anything. So where do the packets come from?

To verify I am not missing any nuance of the CDC protocol, I added debug
statements to the ChibiOS shell to log any incoming data. The `\n\r` bytes
indeed make it to the ChibiOS shell.

When the shell receives a line break, it prints a new prompt. This seems to be
the reason why I’m seeing garbled data: while the output is transferred to the
host, line breaks are received, causing more data transfers. It’s as if somebody
was hammering the return key really quickly.

## Linux tty echo vs. ChibiOS shell banner

The unexpected `\n\r` bytes turn out to come from the Linux USB CDC ACM driver,
or its interplay with the Linux tty driver, to be specific. The CDC ACM driver
is a kind of tty driver, so it is built atop the Linux tty infrastructure, whose
[standard settings include various `ECHO`
flags](https://elixir.bootlin.com/linux/v5.11.16/source/drivers/tty/tty_io.c#L122).

When echoing is enabled, the ChibiOS shell banner triggers echo characters,
which in turn are interpreted as input to the shell, causing garbled output.

So why is echoing enabled? Wouldn’t a terminal emulator turn off echoing first
thing?

Yes. But, when the CDC ACM driver receives the first data transfer via USB
(already queued), the standard tty settings are still in effect, because the
application did not yet have a chance to set its tty configuration up!

This can be verified by running the following command on a Linux host:

```shell
% stty -F /dev/ttyACM0 115200 -echo -echoe -echok
```

Even though the command’s sole purpose is to configure the tty, its opening of
the device still causes the banner to print, and echoing to happen, and garbled
output is the result.

It turns out this is a somewhat common problem. Hence, the Linux USB CDC ACM
driver [has a quirks
table](https://elixir.bootlin.com/linux/v5.11.16/source/drivers/usb/class/cdc-acm.c#L1708),
in which devices that print a banner select the `DISABLE_ECHO` quirk, which
results in the CDC ACM driver turning off the echoing termios flag early:

```c
static const struct usb_device_id acm_ids[] = {
	/* quirky and broken devices */
	{ USB_DEVICE(0x0424, 0x274e), /* Microchip Technology, Inc. */
	  .driver_info = DISABLE_ECHO, }, /* DISABLE ECHO in termios flag */
// …
```

So, a quick solution to turn off echoing early is to change your USB vendor and
product id (VID/PID) to an ID for which the Linux kernel applies the
`DISABLE_ECHO` quirk, e.g.:

```c
#define USB_DEVICE_VID 0x0424
#define USB_DEVICE_PID 0x274e
```


## Flushing in Screen

With tty echo disabled, I don’t see garbled output anymore, but still wouldn’t
always see the ChibiOS shell prompt!

This issue turned out to be specific to the terminal emulator program I’m
using. For many years, I have been using
[Screen](https://en.wikipedia.org/wiki/GNU_Screen) for serial devices of any
sort.

I was surprised to learn during this investigation that Screen [flushes any
pending
output](https://git.savannah.gnu.org/cgit/screen.git/tree/src/window.c?id=d7bd327fdf799c82f9a359365d461edb755056ea#n971)
when opening the device. This typically isn’t a problem because adapter-backed
serial devices are opened once and then stay open. USB virtual serial devices
however are only opened when used, and disappear when loading new program code
onto your micro controller.

I verified this is the problem by using {{< man
name="cat" section="1" >}} instead, with which I can indeed see the prompt:
```
% cat /dev/ttyACM0

ChibiOS/RT Shell
                
                ch> 
```

After commenting out the flush call in Screen’s sources, I could see the prompt
in Screen as well.

{{< note >}}

**Tip:** During the review phase of this article,
[tio](https://github.com/tio/tio/) was pointed out to me as a terminal program
which automatically reconnects. This won’t help with the problem at hand, but
seems handy nevertheless.

{{< /note >}}

## Line ending conversion

Now that we no longer flush the prompt away, why is the spacing still incorrect,
and where does it go wrong?

```

ChibiOS/RT Shell
                
                ch> 
```

If we use {{< man name="strace" section="1" >}} to see what {{< man
name="screen" section="1" >}} or {{< man name="cat" section="1" >}} read from
the driver, we see:

```
797270 read(7, "\n\nChibiOS/RT Shell\n\nch> ", 4096) = 24
```

We would have expected `"\r\nChibiOS/RT Shell\r\nch> "` instead, meaning all
Carriage Returns (`\r`) have been translated to Newlines (`\n`).

This is again due to the [Linux tty driver’s default termios
settings](https://elixir.bootlin.com/linux/v5.11.16/source/drivers/tty/tty_io.c#L122):
`c_iflag` enables option `ICRNL` by default, which translates `CR` (Carriage
Return) to `NL` (Newline).

Unfortunately, contrary to the `DISABLE_ECHO` quirk, there is no corresponding
quirk in the Linux ACM driver to turn off line ending conversion, so a fix would
need a Linux kernel driver change!

## Device-side workaround: wait until opened

At this point, we have covered a few problems that would need to be fixed:

1. Change USB VID/PID to get the `DISABLE_ECHO` quirk in the driver.
1. Recompile terminal emulator programs to remove flushing, if needed.
1. Modify kernel driver to add quirk to disable Carriage Return (`\r`) conversion.

Time for a quick reality check: this seems too hard and too long a time for all
parts of the stack to be fixed. Is there an easier way, and why don’t others run
into this problem? If only the device didn’t print its banner so early, that
would circumvent all of the problems above, too!

Luckily, the host actually notifies the device when a terminal emulator program
opens the USB serial device by sending a `CDC_SET_CONTROL_LINE_STATE` request. I
verified this behavior on Linux, Windows and macOS.

So, let’s implement a workaround in our device code! We will delay starting the
shell until:

1. The USB serial device was opened (not just configured).
1. An additional delay of 100ms has passed to give the terminal emulator
   application a chance to configure the serial device.

In our `main.c` loop, we wait until USB is active, and until we receive the
first `CDC_SET_CONTROL_LINE_STATE` request because the serial port was opened:

```c
  while (true) {
    if (SDU1.config->usbp->state == USB_ACTIVE) {
      chSemWait(&scls);
      chThdSleepMilliseconds(100);

      thread_t *shelltp = chThdCreateFromHeap(NULL, SHELL_WA_SIZE, "shell", NORMALPRIO + 1, shellThread, (void *)&shell_cfg1);
      chThdWait(shelltp);
    }
  }
```

And in our `usbcfg.c`, when receiving a `CDC_SET_CONTROL_LINE_STATE` request, we
will reset the semaphore to non-blockingly wake up all waiters:

```c
extern semaphore_t scls;

bool requests_hook(USBDriver *usbp) {
  const bool result = sduRequestsHook(usbp);

  if ((usbp->setup[0] & USB_RTYPE_TYPE_MASK) == USB_RTYPE_TYPE_CLASS &&
      usbp->setup[1] == CDC_SET_CONTROL_LINE_STATE) {
    osalSysLockFromISR();
    chSemResetI(&scls, 0);
    osalSysUnlockFromISR();
  }

  return result;
}
```

## Screenshots: Mac and Windows

Aside from Linux, I also verified the workaround works on a Mac (with Screen):

{{< img src="chibios-acm-mac.jpg" alt="USB virtual serial device on macOS" >}}

…and that it works on Windows (with PuTTY):

{{< img src="chibios-acm-windows10.jpg" alt="USB virtual serial device on Windows 10" >}}
