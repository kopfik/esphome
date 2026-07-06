# Changelog

## Unreleased

### Added

* Initial bilingual `README.md` documentation, Czech first and English second.
* Initial `CHANGELOG.md`.
* Repository documentation for the reusable ESPHome package/device configuration layout.
* Initial public skeleton export: reusable packages only, consumed via ESPHome remote (git) packages; device configs and `secrets.yaml` stay in private per-site repos.
* `examples/basic-device.yaml` showing how a private device YAML pulls these packages remotely.
* Placeholders for `components/displays/`, `external_components/`, `media/`, and `media.local/` (no vendor/personal content published).

### Changed

* Made the SCD4x forced-calibration target configurable via a new optional `calibration_ppm` var (default 435 ppm), so each device can pass its own value for the calibration button.
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
