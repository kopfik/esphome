# Changelog

## Unreleased

### Breaking

* `packages/mqtt.yaml`: `topic_prefix` is now the device `${topic_prefix}` substitution (required) instead of ESPHome's default `<controller_name>`. Status (`/status`), logs (`/debug`) and all entity state/command topics move under the same prefix as the JSON values from `mqtt_publish_json`. Migration: update anything subscribing to the old `<controller_name>/...` topics, e.g. `mqtt_prefix` of `products/meteohub/pc.yaml`; clear the stale retained `<controller_name>/status` on the broker.
* `components/sensors/bmp3xx_i2c.yaml`: removed the stray `l` from MQTT topics (`pressure_${id}l` -> `pressure_${id}`, `temperature_${id}l` -> `temperature_${id}`). Existing InfluxDB series continue under the new name.
* Removed `packages/sensors.yaml`. It had become an exact copy of `packages/mqtt_publish_json.yaml` after the MCU temperature moved to `components/sensors/internal_temperature.yaml`, and including both failed with `ID mqtt_publish_json redefined`. Migration: in device YAML replace `packages/sensors.yaml` with `packages/mqtt_publish_json.yaml`; add `components/sensors/internal_temperature.yaml` separately if the MCU temperature is wanted.

### Added

* `components/sensors/max17048.yaml`: LiPo fuel gauge (voltage + SOC) on I2C 0x36, using the ESPHome `max17043` platform whose VCELL conversion is numerically identical for the MAX17048; raw values to MQTT plus averaged copies for HA, sharing the naming convention of `battery_stats.yaml`.
* `components/switches/gpio_switch.yaml`: generic GPIO switch with optional `inverted` and `restore_mode` vars (default `ALWAYS_OFF`, safe for switching power).
* `components/buttons/restart_button.yaml`: HA-visible restart button with optional `name` / `btn_id` vars.
* `packages/auto_restart.yaml`: optional scheduled daily restart at a configurable hour/minute, pressing the restart button from an `interval` that checks the wall clock of the existing `packages/time.yaml` time component.
* Initial bilingual `README.md` documentation, Czech first and English second.
* Initial `CHANGELOG.md`.
* Repository documentation for the reusable ESPHome package/device configuration layout.
* Initial public skeleton export: reusable packages only, consumed via ESPHome remote (git) packages; device configs and `secrets.yaml` stay in private per-site repos.
* `examples/basic-device.yaml` showing how a private device YAML pulls these packages remotely.
* Placeholders for `components/displays/`, `external_components/`, `media/`, and `media.local/` (no vendor/personal content published).

### Fixed

* `packages/auto_restart.yaml`: no longer restarts a second time right after booting within the same restart minute (requires uptime > 90 s).
* `components/sensors/battery_stats.yaml`: battery percentage clamped to 0..100 (full charge reported 104.5 %, low voltage negative values).
* `packages/mqtt_publish_json.yaml`: `snprintf` instead of `sprintf`, so an absurd sensor value cannot overflow the buffer.

### Changed

* `packages/base.yaml`: `wifi_power_saver` is now optional, default `light` (ESPHome's own ESP32/RP2040 default; pass `none` explicitly on ESP8266).
* `packages/mqtt_publish_json.yaml`, `components/sensors/paj7620.yaml`: `ts` is now real epoch milliseconds from `gettimeofday()` instead of `timestamp * 1000 + millis() % 1000`, whose millisecond part came from uptime and could make `ts` jump backwards between samples. Payload format unchanged.
* Pinned the Material Design Icons font in meteohub packages to tag `v7.4.47` (the current `master` at pin time) instead of `master`, so builds are reproducible.
* Stopped tracking `.claude/settings.local.json` (local Claude Code permissions) and added it to `.gitignore`.
* Removed the `components/displays/.gitkeep` placeholder; the directory has real display packages now.
* Removed personal names (Wi-Fi SSIDs, household, room and device names, a LAN IP) from comments in `products/meteohub.yaml`, `products/meteohub/{core,segment,foto_online,graf_2,grafy_2}.yaml` and `components/displays/tm1637.yaml`. Comments only, no functional change.
* Removed personal device names from `products/meteohub/pc.yaml`, `components/buttons/pc_button.yaml` and `components/outputs/gpio_output.yaml` examples.
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
* Confirmed all current devices compile in Home Assistant after the recent cleanup.

### Notes

* This is not a tagged public release yet.
* Earlier history was reconstructed from recent repository work, not from a formal release process.
* The repository is currently a working reusable baseline, not a finished public template.
* Display-heavy configs, d1mini legacy configs, secrets/personalization split, and public-template polish remain future work.
