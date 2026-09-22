#!/bin/sh
set -eu

cd /home/pmos/linux-voice-assistant

export PULSE_SERVER=/run/user/10000/pulse/native
export XDG_RUNTIME_DIR=/run/user/10000

# PulseAudio belongs to the pmos user session and can appear after OpenRC.
while [ ! -S "$PULSE_SERVER" ]; do
  sleep 2
done

# postmarketOS enables global role-based ducking. LVA already manages its own
# players, and the global module can repeatedly attenuate wake/TTS playback.
ducking_module="$(pactl list short modules 2>/dev/null | awk '$2 == "module-role-ducking" { print $1; exit }')"
if [ -n "$ducking_module" ]; then
  pactl unload-module "$ducking_module"
fi

exec ./.venv/bin/python -m linux_voice_assistant \
  --name "ThinkSmart Voice LVA" \
  --network-interface wlan0 \
  --port 6053 \
  --audio-input-device "Built-in Audio Stereo Microphone" \
  --audio-input-channels 2 \
  --audio-output-device "pulse/alsa_output.platform-c051000.sound-card.HiFi__Speaker__sink" \
  --music-output-device "pulse/alsa_output.platform-c051000.sound-card.HiFi__Speaker__sink" \
  --wake-word-dir /home/pmos/linux-voice-assistant/wakewords \
  --wake-model okay_nabu \
  --stop-model stop \
  --download-dir /home/pmos/linux-voice-assistant/local \
  --preferences-file /home/pmos/linux-voice-assistant/preferences.json \
  --wakeup-sound /home/pmos/linux-voice-assistant/sounds/voice-pe-soft/wake.flac \
  --start-listening-sound /home/pmos/linux-voice-assistant/sounds/voice-pe-soft/start.flac \
  --timer-finished-sound /home/pmos/linux-voice-assistant/sounds/timer_finished.flac \
  --processing-sound /home/pmos/linux-voice-assistant/sounds/voice-pe-soft/processing.wav \
  --mute-sound /home/pmos/linux-voice-assistant/sounds/custom-loud/mute_switch_on.flac \
  --unmute-sound /home/pmos/linux-voice-assistant/sounds/custom-loud/mute_switch_off.flac \
  --peripheral-startup-wait 0 \
  "$@"

