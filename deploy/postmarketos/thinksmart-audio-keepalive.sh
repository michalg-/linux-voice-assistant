#!/bin/sh
set -eu

export PULSE_SERVER=/run/user/10000/pulse/native
export XDG_RUNTIME_DIR=/run/user/10000

while [ ! -S "$PULSE_SERVER" ]; do
  sleep 1
done

# The postmarketOS tas5805m driver powers the TAS5782M DSP down whenever the
# last playback stream closes. Reinitialising it takes about 0.7-0.8 seconds,
# which drops the beginning of the next sound and may mute its buffered tail.
# Keep real PCM flowing through the Qualcomm DSP. A muted module-sine stream
# leaves the PulseAudio sink in RUNNING state but does not reliably keep this
# hardware route alive and can leave playback blocked until a full reboot.
exec /usr/bin/pacat \
  --playback \
  --device=alsa_output.platform-c051000.sound-card.HiFi__Speaker__sink \
  --raw \
  --format=s16le \
  --rate=48000 \
  --channels=2 \
  /dev/zero
