---
layout: post
title:  "Eclipse: Enabling Compilation Database (CDB, compile_commands.json) in NXP MCUXpresso v11.3"
date:   2021-04-01 11:59:23 +02:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1377562137858609153"
---

NXP’s Eclipse-based MCUXpresso IDE is the easiest way to make full use of the
hardware debugging features of modern NXP micro controllers such as the [i.MX
RT1060](https://www.nxp.com/products/processors-and-microcontrollers/arm-microcontrollers/i-mx-rt-crossover-mcus/i-mx-rt1060-crossover-mcu-with-arm-cortex-m7-core:i.MX-RT1060)
found on the [NXP i.MX RT1060 Evaluation Kit
(`MIMXRT1060-EVK`)](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/mimxrt1060-evk-i-mx-rt1060-evaluation-kit:MIMXRT1060-EVK),
which I use for Teensy 4 development.

For projects that are fully under your control, such as imported SDK examples,
or anything you created within Eclipse, you wouldn’t necessarily need
Compilation Database support.

When working with projects of type `Makefile Project with Existing Code`,
however, Eclipse doesn’t know about preprocessor definition flags and include
directories, unless you would manually duplicate them. In large and
fast-changing projects, this is not an option.

The lack of compiler configuration knowledge (defines and include directories)
breaks various C/C++ tooling features, such as Macro Expansion or the `Open
Declaration` feature, both of which are an essential tool in my toolbelt, and
particularly useful in large code bases such as micro controller projects with
various SDKs etc.

In some configurations, Eclipse might be able to parse GCC build output, but
when I was working with the [QMK keyboard firmware](https://qmk.fm/), I couldn’t
get the QMK makefiles to print commands that Eclipse would understand, not even
with `VERBOSE=true`.

Luckily, there is a solution! [Eclipse CDT 9.10 introduced Compilation Database
support](https://wiki.eclipse.org/CDT/User/NewIn910#Build) in 2019. MCUXpresso
v11.3.0 ships with CDT 9.11.1.202006011430, meaning it does contain Compilation
Database support.

In case you want to check which version your installed IDE has, open `Help` →
`About MCUXpresso IDE`, click `Installation Details`, open the `Features` tab,
then locate the `Eclipse CDT`, `C/C++ Development Platform` line.

For comparison, Eclipse IDE 2021-03 contains 10.2.0.202103011047, if you want to
verify that the issues I reference below are indeed fixed.

## Bug: command vs. arguments

Before we can enable Compilation Database support, we need to ensure we have a
compatible `compile_commands.json` database file. Eclipse CDT’s Compilation
Database support before version CDT 10 suffered from [Bug
563006](https://bugs.eclipse.org/bugs/show_bug.cgi?id=563006): it only
understood the `command` JSON property, not the `arguments` property.

Depending on your build system, this isn’t a problem. For example, Meson/ninja’s
`compile_commands.json` uses `command` and will work fine.

But, when using Make with [Bear](https://github.com/rizsotto/Bear), you will end
up with `arguments` by default.

Bear 3.0 allows generating a `compile_commands.json` Compilation Database with
`command`, but [requires multiple commands and config
files](https://github.com/rizsotto/Bear/issues/196#issuecomment-691748584),
which is a bit inconvenient with Eclipse.

So, let’s put the extra commands into a `commandbear.sh` script:

```bash
#!/bin/sh

set -eux

intercept --output commands.json -- "$@"
citnames \
  --input commands.json \
  --output compile_commands.json \
  --config config.json
```

The `"command_as_array": false` option goes into `config.json`:

```
{
  "compilation": {
  },
  "output": {
    "content": {
      "include_only_existing_source": true
    },
    "format": {
      "command_as_array": false,
      "drop_output_field": false
    }
  }
}
```

Don’t forget to make the script executable:

```shell
chmod +x commandbear.sh
```

Then configure Eclipse to use the `commandbear.sh` script to build:

1. Open Project Properties by right-clicking your project in the Project
   Explorer panel.
1. Select `C/C++ Build` and open the `Builder Settings` tab
1. In the `Builder` group, set the `Build command` text field to:
   `${workspace_loc:/qmk_firmware}/commandbear.sh make -j16`

Verify your build is working by selecting `Project` → `Clean…` and triggering a
build.

## Enabling Compilation Database support

1. Open Project Properties by right-clicking your project in the Project
   Explorer panel.
1. Expand `C/C++ General`, select `Preprocessor Include Paths, Macros etc.` and
   open the `Providers` tab.
1. Untick everything but:
    * MCU GCC Built-in Compiler Parser
	* MCU GCC Build Output Parser
	* Compilation Database Parser
1. Select `Compilation Database Parser`, click `Apply` to make the Compilation
   Database text field editable.
1. Put a full path to your compile_commands.json file into the text field,
   e.g. `/home/michael/kinx/workspace/qmk_firmware/compile_commands.json`. Note
   that variables will not be expanded! Support for using variables was added
   later in [Bug 559186](https://bugs.eclipse.org/bugs/show_bug.cgi?id=559186).
1. Select `MCU GCC Build Output Parser` as `Build parser`.
1. Tick the `Exclude files not in the Compilation Database` checkbox.
1. Click `Apply and Close`.

{{< img src="cdb-1.jpg" alt="Compilation Database Parser settings" >}}

You will know Compilation Database support works when its progress view shows
up:

{{< img src="cdb-2.jpg" alt="Compilation Database progress" >}}

If you have an incompatible or empty `compile_commands.json`, nothing visible
will happen (no progress indicator or error messages).

After indexing completes, you should see:

1. Files that were not used as greyed out in the `Project Explorer`
1. `Open Declaration` in the context menu of a selected identifier (or `F3`)
   should jump to the correct file. For example, my test sequence for this
   feature in the QMK repository is:
    * in `tmk_core/protocol/chibios/main.c`, open `init_usb_driver`
	* open `usbStart`, should bring up `lib/chibios` git submodule
	* open `usb_lld_start`, should bring up `MIMXRT1062` port
1. Macros expanded correctly, e.g. `MIMXRT1062_USB_USE_USB1` in the following
   example

{{< img src="cdb-6.jpg" alt="Compilation Database in effect: files greyed out and macros expanded" >}}

## Slow file exclusion in projects with many files

[Bug 565457](https://bugs.eclipse.org/bugs/show_bug.cgi?id=565457) explains an
optimization in the algorithm used to generate the list of excluded paths, which
I would summarize as “use whole directories instead of individual files”.

This optimization was introduced later, so in MCUXpresso v11.3, we still have to
endure watching the slow algorithm for a few seconds:

{{< img src="cdb-4.jpg" alt="Compilation Database exclusion slow" >}}

## Conclusion

NXP, please release a new MCUXpresso IDE with a more recent CDT version!

The improvements in the newer version would make the setup so much simpler.
