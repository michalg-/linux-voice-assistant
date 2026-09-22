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

The launcher uses `parec` to provide stereo signed 16-bit PCM directly from
PulseAudio. This avoids the CPU-heavy float conversion in the Python
`soundcard` capture path while retaining the second reference channel used for
AEC. The stop-word model only runs while TTS or a finished timer can actually
be stopped. Together these changes reduce idle voice-assistant usage from
about 36% to 17% of one CPU core on this device.

The archived Wyoming setup remains lighter because it sends microphone audio
to the OpenWakeWord service at `192.168.68.116:10400` instead of running
wake-word inference locally.

## Enable services

```sh
doas rc-update add thinksmart-audio-keepalive default
doas rc-update add linux-voice-assistant default
doas rc-service thinksmart-audio-keepalive start
doas rc-service linux-voice-assistant start
```
