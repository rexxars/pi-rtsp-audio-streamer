# pi-rtsp-audio-streamer

Turn a Raspberry Pi with a USB microphone into an RTSP audio streamer. Lightweight.

I use this for a Raspberry Pi Zero 2 W with a USB microphone, and add the RTSP stream as a source in [birdnet-go](https://github.com/tphakala/birdnet-go) (should work for [birdnet-pi](https://github.com/Nachtzuster/BirdNET-Pi) too, or anything that takes an RTSP stream, obviously). That means this is preconfigured to use 48kHz mono audio (PRs to make this configurable is welcome).

RTSP stream will be available on rtsp://${PI-HOSTNAME}.local:8554/mic 

## TL;DR

```sh
curl -o- https://raw.githubusercontent.com/rexxars/pi-rtsp-audio-streamer/main/bootstrap.sh | bash
```

## Features

- Uses [go2rtc](https://github.com/AlexxIT/go2rtc) under the hood - lightweight, single-binary
- (Tries to) automatically find the correct USB microphone using `arecord`
- Installs systemd service to auto-restart on crash (and on boot)
- Disables swap, moves logs and tmp folders to ram and sets noatime for reduced SD-card wear

## Statistics

- Less than 4 GB of SD card space
- On a Zero 2W:
  - ~1W when idle
  - Less than 1.5W with 1 client connected
  - CPU usage usually <10% on a single core
  - Memory usage of system <80MB, about 18MB used by go2rtc

## Installation

1. Get the hardware required:
    - [Raspberry Pi](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/) (pretty much any ARM-based ones should work, I used the Zero 2 W)
       - If you got a Zero, you will probably need a [Micro USB to USB A adapter](https://www.amazon.com/StarTech-com-5in-Micro-Host-Adapter/dp/B00B4GGW5Q?)
    - USB microphone (I'm not an expert, but personally using a [Movo M1 Lavalier Lapel](https://www.amazon.com/Movo-Omnidirectional-Microphone-Podcasting-Streaming/dp/B0176NRE1G))
    - USB power supply (make sure you get one with the right USB connector and power specifications based on the pi you chose).
    - MicroSD card of at least 4GB. These days you'll have trouble finding something below 16GB for not a ton of money. Given that we tune the OS for minimal SD card writes, you likely don't need anything super fancy or durable, but the price difference isn't huge these days.
      - Something to write the Raspberry Pi image onto the SD card. The MacBook Pro has an SD card reader, and a lot of the MicroSD cards come with an adapter - but whatever works for ya.
2. Install [Raspberry Pi OS](https://www.raspberrypi.com/software/). Using the Raspberry Pi Imager, I'd recommend:
    - Choosing Raspberry Pi OS Lite (32-bit). You'll find it under "Raspberry Pi OS (Other)". There's no need for a desktop environment, and 64-bit isn't gonna give us any leg up here.
    - When it asks for OS customization, make sure you configure it with:
       - A hostname of your choice. Makes it easier to find once it boots - available as `<your-hostname>.local`.
       - The wireless LAN options, so it automatically connects. Without this you won't be streaming anywhere.
       - Under the "Services" tab, enable SSH - unless you're planning to run the bootstrap script manually with a keyboard and monitor (with the Zero 2W you'll likely need the Micro USB -> USB A adapter for the keyboard _and_ a Mini-HDMI to HDMI adapter, so SSH is my preferred choice to avoid having to do this).
3. Insert the MicroSD card into the Raspberry Pi, the mic into it's USB, and give it power.
4. Run the bootstrap script from this repo: `curl -o- https://raw.githubusercontent.com/rexxars/pi-rtsp-audio-streamer/main/bootstrap.sh | bash` (or whatever method you prefer, source is at [bootstrap.sh](https://github.com/rexxars/pi-rtsp-audio-streamer/blob/main/bootstrap.sh))
5. Done, hopefully! Try the stream with VLC or similar (file -> open network)

## License

MIT © [Espen Hovlandsdal](https://espen.codes/)
