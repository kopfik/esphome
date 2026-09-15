# Changelog

All notable changes to this repository. Releases are git tags (`v0.1.0`, ...);
devices pin one via `ref:`. Entries under **Breaking** require editing device
YAML and include migration steps.

## Unreleased

### Changed

* `products/meteohub/core.yaml`: `ignore_missing_glyphs: true` on the Ubuntu fonts using `GF_Latin_Core`, silencing the "Font Ubuntu is missing 15 glyphs" warning (combining diacritics never drawn; explicitly requested glyphs still fail loudly).
* `README.md`, `examples/device-with-many-sensors.yaml`: the shared remote anchor now lives in a hidden top-level key (`.kopfik_esphome_remote`) instead of on the `base` package, avoiding ESPHome's "Key 'files' ... was dropped while processing a '<<' merge" warning. Examples pin `ref: v0.1.0`.

## v0.1.0 — 2026-09-15

### Breaking

* `packages/mqtt.yaml`: `topic_prefix` is now the device `${topic_prefix}` substitution (required) instead of ESPHome's default `<controller_name>`. Status (`/status`), logs (`/debug`) and all entity state/command topics move under the same prefix as the JSON values from `mqtt_publish_json`. Migration: update anything subscribing to the old `<controller_name>/...` topics, e.g. `mqtt_prefix` of `products/meteohub/pc.yaml`; clear the stale retained `<controller_name>/status` on the broker.
* `components/sensors/bmp3xx_i2c.yaml`: removed the stray `l` from MQTT topics (`pressure_${id}l` -> `pressure_${id}`, `temperature_${id}l` -> `temperature_${id}`). Existing InfluxDB series continue under the new name.
* Removed `packages/sensors.yaml`. It had become an exact copy of `packages/mqtt_publish_json.yaml` after the MCU temperature moved to `components/sensors/internal_temperature.yaml`, and including both failed with `ID mqtt_publish_json redefined`. Migration: in device YAML replace `packages/sensors.yaml` with `packages/mqtt_publish_json.yaml`; add `components/sensors/internal_temperature.yaml` separately if the MCU temperature is wanted.

### Added

* Automated tests (CI): six anonymized test devices in `tests/devices/` that together include every package, a GitHub Actions workflow (`.github/workflows/esphome.yml`) running `esphome config` and `esphome compile` for each on every push and weekly, `tests/run.sh` for the same check locally, and `tests/README.md` explaining it in plain terms.
* `products/meteohub/README.md`: map of the composed meteohub packages — layers, required order in `packages:`, fixed ids a device must provide, common errors.
* `products/meteohub/*.yaml` (Sep 2026): composed, display-size-independent meteohub built from small packages:
  * core: `core.yaml`, `core_touch.yaml`, geometry `geo_320x480.yaml` and `geo_240x320.yaml`, `bez_radaru.yaml` (radar stub);
  * backlight and extras: `podsviceni_radar.yaml`, `podsviceni_dotyk.yaml`, `segment.yaml` (TM1637), `rotace.yaml` (page slideshow);
  * dashboard and cards: `dashboard.yaml`, `dashboard_touch.yaml`, `velicina.yaml`, `karta.yaml`, `skala.yaml` (threshold colors), `svatky.yaml` (name days);
  * graphs: `senzor.yaml`, `senzor_graf.yaml`, `grafy.yaml`, `graf.yaml`, `grafy_2.yaml`, `graf_2.yaml`, `graf_multi.yaml`, `trasa.yaml`;
  * pages: `hodiny.yaml`, `hodiny_touch.yaml`, `foto.yaml`, `foto_online.yaml` (photo fetched from HA at runtime), `pc.yaml` (PC power/reset over MQTT), `menu.yaml`.
* `products/meteohub.yaml` (Sep 2026): first, monolithic meteohub UI for a 320×480 ST7796 panel. Superseded by the composed packages above; removed, see Removed.
* `components/sensors/ping.yaml`: "machine is on" binary sensor from ICMP ping with a hold time.
* `packages/base.yaml`: optional `wifi_hidden` (hidden SSID, must be network index 0) and `wifi_fast_connect` substitutions.
* `components/sensors/internal_temperature.yaml`: chip temperature as a separate package (ESP32 only), split out of the former `packages/sensors.yaml`.
* `components/outputs/ledc_pwm.yaml`: optional `inverted` var (PNP / P-MOSFET drivers).
* `components/sensors/max17048.yaml`: LiPo fuel gauge (voltage + SOC) on I2C 0x36, using the ESPHome `max17043` platform whose VCELL conversion is numerically identical for the MAX17048; raw values to MQTT plus averaged copies for HA, sharing the naming convention of `battery_stats.yaml`.
* `boards/esp32-p4-eth-esp-idf.yaml` and `packages/base_eth.yaml`: Waveshare ESP32-P4-ETH (ethernet only, no radio) with an ethernet twin of the base package.
* `components/switches/gpio_switch.yaml`: generic GPIO switch with optional `inverted` and `restore_mode` vars (default `ALWAYS_OFF`, safe for switching power).
* `components/buttons/restart_button.yaml`: HA-visible restart button with optional `name` / `btn_id` vars.
* `packages/auto_restart.yaml`: optional scheduled daily restart at a configurable hour/minute, pressing the restart button from an `interval` that checks the wall clock of the existing `packages/time.yaml` time component.
* `boards/d1mini.yaml` (ESP8266) and `packages/mqtt_publish_json.yaml` usable without ESP32-only parts.
* Displays: `components/displays/ili9xxx/st7796.yaml`, `st7789v.yaml`, `ili9488.yaml`, `ili9488_yellow_board.yaml` (calibration init sequence for a bad panel batch) and `components/displays/tm1637.yaml`.
* `components/sensors/aht20.yaml` and `components/sensors/bmp280.yaml`.
* Initial bilingual `README.md` documentation, Czech first and English second.
* Initial `CHANGELOG.md`.
* Repository documentation for the reusable ESPHome package/device configuration layout.
* Initial public skeleton export: reusable packages only, consumed via ESPHome remote (git) packages; device configs and `secrets.yaml` stay in private per-site repos.
* `examples/device-with-many-sensors.yaml` showing how a private device YAML pulls these packages remotely.
* Placeholders for `external_components/`, `media/`, and `media.local/` (no vendor/personal content published).

### Removed

* `products/meteohub.yaml`, the monolithic first-generation meteohub. No device used it anymore; all moved to the composed `products/meteohub/*.yaml`. The last version is available via `git show d431f27:products/meteohub.yaml`.

### Fixed

* `packages/auto_restart.yaml`: no longer restarts a second time right after booting within the same restart minute (requires uptime > 90 s).
* `components/sensors/battery_stats.yaml`: battery percentage clamped to 0..100 (full charge reported 104.5 %, low voltage negative values).
* `packages/mqtt_publish_json.yaml`: `snprintf` instead of `sprintf`, so an absurd sensor value cannot overflow the buffer.
* `packages/base.yaml`, `packages/base_eth.yaml`: API `reboot_timeout: 0s`, so MQTT-only devices (not added to HA) no longer reboot every 15 minutes.

### Changed

* `components/sensors/paj7620.yaml`: documented that the external component only builds with the Arduino framework (uses Arduino `String`); in tests it moved from the esp-idf test device to the Arduino one.
* `components/sensors/sgp4x.yaml`: `voc` / `nox` renamed to `voc_index` / `nox_index` (ESPHome deprecation, old keys removed in 2027.2.0). Same ids and MQTT topics; header now explains that the sensor is always sampled at 1 Hz and `update_interval` only sets how often the index is published.
* `components/lights/esp32_rmt_rgb_led.yaml`, `components/lights/ws2812_rmt.yaml`: `rgb_order` / `is_rgbw` now feed ESPHome's new `channel_colors` key (old keys removed in 2027.3.0). The vars stay the same, device YAML needs no change.
* `README.md` rewritten for the current repository: layers, full layout table, MQTT/telemetry conventions, displays, products, ESP8266 notes, tagging.
* `packages/mqtt_publish_json.yaml`, `components/sensors/paj7620.yaml`: `ts` is now real epoch milliseconds from `gettimeofday()` instead of `timestamp * 1000 + millis() % 1000`, whose millisecond part came from uptime and could make `ts` jump backwards between samples. Payload format unchanged.
* Pinned the Material Design Icons font in meteohub packages to tag `v7.4.47` (the current `master` at pin time) instead of `master`, so builds are reproducible.
* Stopped tracking `.claude/settings.local.json` (local Claude Code permissions) and added it to `.gitignore`.
* Removed the `components/displays/.gitkeep` placeholder; the directory has real display packages now.
* Removed personal names (Wi-Fi SSIDs, household, room and device names, a LAN IP) from comments in `products/meteohub.yaml`, `products/meteohub/{core,segment,foto_online,graf_2,grafy_2}.yaml` and `components/displays/tm1637.yaml`. Comments only, no functional change.
* Removed personal device names from `products/meteohub/pc.yaml`, `components/buttons/pc_button.yaml` and `components/outputs/gpio_output.yaml` examples.
* `packages/base.yaml`: `wifi_power_saver` is now optional, default `light` (ESPHome's own ESP32/RP2040 default; pass `none` explicitly on ESP8266).
* `packages/base.yaml`: API `max_connections` raised to 10 like `packages/base_eth.yaml` (ESPHome default 5 on ESP32 ran out); both configurable via optional `api_max_connections`. Pass `4` on ESP8266.
* `packages/time.yaml`: timezone configurable via optional `timezone` var, default `Europe/Prague` (previous hard-coded value).
* Made the SCD4x forced-calibration target configurable via a new optional `calibration_ppm` var (default 435 ppm), so each device can pass its own value for the calibration button.
* Exposed the SCD4x forced-calibration target as a HA-adjustable `number` entity (`calibration_ppm_<id>`), so the value can be changed at runtime without recompiling; `calibration_ppm` now only sets the initial value and the setting survives reboots.
* Imported shared ESPHome project files into Git.
* Moved board packages under `boards/`.
* Restructured reusable packages into `packages/`, `components/`, `boards/`, `templates/`, `external_components/`, and `media/`.
* Added package headers with Inline and Block include examples.
* Normalized active device YAML package layout.
* Made SNTP package configuration more generic while preserving current device behavior.
* Renamed sensor packages to better match ESPHome/platform naming:

  * `bmp58x_i2c.yaml` -> `bmp581_i2c.yaml`
  * `bmp58x.yaml` -> `bmp58x_custom.yaml`
  * `opt3xxx.yaml` -> `opt3001.yaml`
* Removed obsolete experimental `ld2450_new.yaml`.
* Added practical default-preserving sensor package variables.
* Confirmed all current devices compile in Home Assistant after the recent cleanup (June 2026).

### Notes

* History before 2026-09-15 was reconstructed from the git log and diffs; many of those commit messages were placeholders (`meteohubing12`, `touchubing4`), so entries are grouped by feature, not by commit.
* The 2026-09-15 cleanup was compile-tested on real ESP32-P4, ESP32-S3 and ESP8266 devices before the automated tests were added.
* Still open: `boards/rpipico1w.yaml` is empty; secrets/personalization split and public-template polish.
