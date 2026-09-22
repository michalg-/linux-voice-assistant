# ThinkSmart Voice on postmarketOS

This directory contains the device-specific files used by the bare-metal
installation on `pmos@192.168.68.221` (Python 3.14, OpenRC and PulseAudio).
The application source remains in the normal repository layout so the branch
can be rebased onto future upstream releases.

## Installed paths

| Repository file | Device path |
| --- | --- |
| `run-lva.sh` | `/home/pmos/linux-voice-assistant/run-lva.sh` |
| `linux-voice-assistant.initd` | `/etc/init.d/linux-voice-assistant` |
| `thinksmart-audio-keepalive.sh` | `/usr/local/bin/thinksmart-audio-keepalive` |
| `thinksmart-audio-keepalive.initd` | `/etc/init.d/thinksmart-audio-keepalive` |

The keepalive holds the QDSP6/TAS5782M PCM path open with zero samples. Without
it, the kernel powers the amplifier DSP down and its 0.7-0.8 second startup
clips short sounds and the beginning of TTS playback.

The local MicroWakeWord model currently uses about 30% of one CPU core. The
archived Wyoming setup was lighter on this device because it sent microphone
audio to the OpenWakeWord service at `192.168.68.116:10400` instead of running
wake-word inference locally.

## Enable services

```sh
doas rc-update add thinksmart-audio-keepalive default
doas rc-update add linux-voice-assistant default
doas rc-service thinksmart-audio-keepalive start
doas rc-service linux-voice-assistant start
```
