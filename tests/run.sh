#!/bin/sh
# Lokalni spusteni stejne kontroly, jakou dela CI na GitHubu.
#
#   sh tests/run.sh              # esphome config pro vsechna testovaci zarizeni (sekundy)
#   sh tests/run.sh compile      # plny preklad (minuty, poprve stahuje toolchainy)
#   sh tests/run.sh config d1mini   # jen jedno zarizeni
#
# Potrebuje docker. Spoustet z korene repa nebo odkudkoliv -- cestu si najde sam.
# Konci chybou (exit 1), kdyz aspon jedno zarizeni neprojde.

set -u
cd "$(dirname "$0")/.." || exit 1

ACTION="${1:-config}"
ONLY="${2:-}"
IMAGE="ghcr.io/esphome/esphome:latest"
FAILED=""

for f in tests/devices/*.yaml; do
  name=$(basename "$f" .yaml)
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  echo "=== $ACTION $name"
  if docker run --rm -v "$PWD:/config" -w /config "$IMAGE" "$ACTION" "$f" > "/tmp/esphome-test-$name.log" 2>&1; then
    echo "    OK"
  else
    echo "    CHYBA -- posledni radky logu (cely log: /tmp/esphome-test-$name.log):"
    tail -n 15 "/tmp/esphome-test-$name.log" | sed 's/^/    /'
    FAILED="$FAILED $name"
  fi
done

if [ -n "$FAILED" ]; then
  echo "NEPROSLO:$FAILED"
  exit 1
fi
echo "Vsechno proslo."
