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
# A muted in-server stream keeps the sink active without copying continuous
# zero PCM through a separate pacat client.
sink="alsa_output.platform-c051000.sound-card.HiFi__Speaker__sink"
module_id=""
sleep_pid=""

cleanup() {
  if [ -n "$sleep_pid" ]; then
    kill "$sleep_pid" 2>/dev/null || true
  fi
  if [ -n "$module_id" ]; then
    pactl unload-module "$module_id" 2>/dev/null || true
  fi
}

trap cleanup 0
trap 'exit 0' HUP INT TERM

module_id="$(pactl load-module module-sine sink="$sink" frequency=1)"

attempts=0
sink_input=""
while [ -z "$sink_input" ]; do
  sink_input="$(
    pactl list sink-inputs | awk -v module="$module_id" '
      /^Sink Input #/ { id=$3; sub("#", "", id) }
      /^[[:space:]]*Owner Module:/ && $3 == module { print id; exit }
    '
  )"
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 10 ]; then
    echo "Unable to find keepalive sink input" >&2
    exit 1
  fi
  [ -n "$sink_input" ] || sleep 1
done

pactl set-sink-input-volume "$sink_input" 0%
pactl set-sink-input-mute "$sink_input" 1

# If PulseAudio restarts and drops the module, exit so supervise-daemon can
# recreate the keepalive stream against the new server.
while pactl list short modules | awk -v module="$module_id" '$1 == module { found=1 } END { exit !found }'; do
  sleep 30 &
  sleep_pid=$!
  wait "$sleep_pid" || true
  sleep_pid=""
done

exit 1
