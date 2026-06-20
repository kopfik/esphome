# ESPHome Packages and Device Configs

**Jazyk / Language:** [🇨🇿 Česky](#česky) · [🇬🇧 English](#english)

---

## Česky

### Co repo obsahuje

Veřejné, znovupoužitelné ESPHome **balíčky** — sdílené, parametrizované stavební
bloky pro stavbu zařízení: jádrové balíčky, definice desek, komponenty (sběrnice,
senzory, světla, výstupy, tlačítka), šablony a příklady.

Repo **neobsahuje** konkrétní zařízení, `secrets.yaml`, reálná media ani vendor
kód displejů. Ty zůstávají u tebe v lokální ESPHome / Home Assistant konfiguraci.

### Jak se používá

V **lokálním** device YAML (ve své ESPHome konfiguraci) si poskládáš funkce přes
ESPHome *remote (git) packages*, které ukazují na tohle repo, a předáš jim
hodnoty přes `vars`. Stejný soubor můžeš uvést víckrát s jinými `vars` → víc
instancí (např. dva senzory ze stejného souboru).

Význam jednotlivých klíčů:

- **`url`** — HTTPS adresa tohoto repozitáře.
- **`ref`** — větev, tag nebo commit, který se natáhne (viz [Vývoj / aktualizace](#vývoj--aktualizace)).
- **`refresh`** — jak často ESPHome kontroluje remote na změny (např. `1d`); u
  pevného tagu/commitu prakticky nehraje roli.
- **`files`** — seznam souborů z repa, které se do zařízení natáhnou.
- **`path`** — cesta k souboru uvnitř repa.
- **`vars`** — hodnoty předané do substitucí daného souboru. Jsou **vnořené pod
  položkou souboru** (vedle `path`), ne přímo pod klíčem balíčku.

### Lokální konfigurace a secrets

U sebe (v ESPHome / HA), **mimo** tohle repo, si držíš:

- **device YAMLy** — tenké, site-specific soubory, které tahají balíčky odsud;
- **`secrets.yaml`** — Wi-Fi, API encryption key, MQTT broker apod.;
- volitelně **`media.local/`** — lokální/privátní média (viz [Média a displeje](#média-a-displeje)).

Secrety se vyhodnocují **v lokálním device YAML / lokální ESPHome konfiguraci**,
nikdy ne uvnitř remote balíčků — ESPHome `!secret` uvnitř natažených souborů
neumí vyhodnotit. Vyřeš je tedy lokálně (typicky v `substitutions:` přes
`!secret …`) a do balíčků je předej jako hodnotu varu / substituce (`${…}`).

### Příklad device YAML

Tohle žije v **tvé** konfiguraci, ne tady. Příklad zařízení s více senzory viz
[`examples/device-with-many-sensors.yaml`](examples/device-with-many-sensors.yaml):

```yaml
substitutions:
  controller_name: "example-device"
  topic_prefix: "esphome/site/example-device"
  # secrety se vyhodnotí lokálně a do balíčků jdou přes vars / ${...}
  encryption_key: !secret api_encryption_key
  wifi_ssid: !secret wifi_ssid
  wifi_password: !secret wifi_password
  i2c_bus_id: i2c_bus

esphome:

logger:
  level: INFO

packages:
  # sdílený remote zdroj (url/ref/refresh) se nadefinuje jednou jako YAML kotva
  # a ostatní balíčky ho přebírají přes `<<: *kopfik_esphome_remote`
  base: &kopfik_esphome_remote
    url: https://github.com/kopfik/esphome
    ref: master            # při testování; pro stabilní buildy pinni tag/commit
    refresh: 1d
    files:
      - packages/base.yaml
  mqtt:
    <<: *kopfik_esphome_remote
    files:
      - path: packages/mqtt.yaml
        vars:
          id: !secret mqtt_id
          broker: !secret mqtt_broker
          port: !secret mqtt_port
  sht45:
    <<: *kopfik_esphome_remote
    files:
      - path: components/sensors/sht4x.yaml
        vars:
          id: sht45
          address: 0x44
          update_interval: 1
          window_size: 60
```

`<<: *kopfik_esphome_remote` jen znovupoužije sdílený `url/ref/refresh` blok
definovaný u prvního balíčku — je to běžný YAML, čistě kvůli čitelnosti.

### Struktura repozitáře

| Cesta | Obsah |
|---|---|
| `packages/` | Jádro: `base`, `time`, `mqtt`, `sensors`, `ble_proxy` |
| `boards/` | Definice desek + power-management (ESP32-S3/C6, …) |
| `components/buses/` | I²C, SPI, UART, 1-Wire sběrnice |
| `components/sensors/` | Senzorové balíčky (SHT4x, SCD4x, BMP, LD24xx, …) |
| `components/lights/` | RGB/LED stripy, segmenty, monochromatická světla |
| `components/outputs/` | GPIO výstupy, LEDC PWM, bzučák |
| `components/buttons/` | Tlačítka (např. PC power button) |
| `components/displays/` | Placeholder — displeje jsou budoucí práce |
| `external_components/` | Placeholder — vendor/cizí kód se sem nepublikuje |
| `templates/` | Sdílené YAML kousky / kotvy |
| `examples/` | Anonymizovaný vzorový device YAML |
| `media/` | Placeholder pro budoucí veřejná / znovupoužitelná média |
| `media.local/` | Konvence pro lokální/privátní média (zde gitignored) |

### Konvence balíčků

- Soubor balíčku obvykle začíná **hlavičkou** s příklady includu, aby bylo hned
  vidět, jak se volá a jaké bere `vars`.
- Volitelné hodnoty se píšou jako `${var | default(...)}` → když je device
  nepředá, spadne to na rozumný default.
- Hardware-specifické věci (ID, I²C adresy, offsety, intervaly, piny, zapojení)
  se předávají jako `vars`, ne natvrdo v balíčku.
- **Žádné secrety ani odkazy na ně v balíčcích** (remote packages je stejně
  neumí vyhodnotit).

### Senzory a hardware poznámky

Senzorové balíčky jsou v `components/sensors/`; pojmenování drží oficiální
ESPHome platformy, kde to dává smysl.

- **BMP58x:** `bmp58x_custom.yaml` = custom/manuální-init implementace;
  `bmp581_i2c.yaml` = nativní ESPHome-style balíček.
- **Radar:** `ld2450.yaml` je kanonický LD2450 balíček.

### Média a displeje

- `media/` je placeholder pro **budoucí veřejná / znovupoužitelná** média.
- `media.local/` je konvence pro **lokální/privátní** média ve tvé ESPHome
  konfiguraci; v tomhle repu je gitignored (obsah se necommituje).
- Displeje jsou zatím **placeholder / budoucí práce**.

### Vývoj / aktualizace

`ref` určuje, co se natáhne:

- **`master`** — nejnovější stav, OK na testování.
- **tag / commit** — lepší pro stabilní, reprodukovatelné buildy (až budou
  vydané), aby ti starý device nezačal tahat aktuální `master`.

Z tohohle repa se neflashuje ani neuploaduje. Po úpravě balíčku zkompiluj/otestuj
zařízení ve své ESPHome konfiguraci a teprve pak commitni / otaguj.

### Licence

Repozitář je licencovaný pod **MIT** (viz [`LICENSE`](LICENSE)).

ESPHome samotné má vlastní licenci. Toto repo obsahuje znovupoužitelné ESPHome
YAML balíčky, dokumentaci a příklady. Případné budoucí externí/custom komponenty
si nesou vlastní licenci a atribuci.

---

## English

### What this repository contains

Public, reusable ESPHome **packages** — shared, parameterized building blocks for
assembling devices: core packages, board definitions, components (buses, sensors,
lights, outputs, buttons), templates, and examples.

The repo does **not** contain concrete devices, `secrets.yaml`, real media, or
vendor display code. Those stay in your own local ESPHome / Home Assistant
configuration.

### How to use it

In your **local** device YAML (in your ESPHome configuration) you assemble
features via ESPHome *remote (git) packages* pointing at this repository, and pass
values through `vars`. The same file can be listed multiple times with different
`vars` to create multiple instances (e.g. two sensors from one file).

What each key means:

- **`url`** — HTTPS address of this repository.
- **`ref`** — branch, tag, or commit to pull (see [Development / updates](#development--updates)).
- **`refresh`** — how often ESPHome re-checks the remote for changes (e.g. `1d`);
  effectively irrelevant when pinned to a tag/commit.
- **`files`** — list of files to pull from the repo into the device.
- **`path`** — path of a file inside the repo.
- **`vars`** — values passed into that file's substitutions. They are **nested
  under the file item** (next to `path`), not directly under the package key.

### Local configuration and secrets

On your side (in ESPHome / HA), **outside** this repo, you keep:

- **device YAMLs** — thin, site-specific files that pull packages from here;
- **`secrets.yaml`** — Wi-Fi, API encryption key, MQTT broker, etc.;
- optionally **`media.local/`** — local/private media (see [Media and displays](#media-and-displays)).

Secrets are resolved **in your local device YAML / local ESPHome config**, never
inside remote packages — ESPHome cannot resolve `!secret` inside the pulled files.
Resolve them locally (typically in `substitutions:` via `!secret …`) and pass them
into packages as a var / substitution value (`${…}`).

### Example device YAML

This lives in **your** configuration, not here. See
[`examples/device-with-many-sensors.yaml`](examples/device-with-many-sensors.yaml)
for an example device with multiple sensors:

```yaml
substitutions:
  controller_name: "example-device"
  topic_prefix: "esphome/site/example-device"
  # secrets resolved locally; passed into packages via vars / ${...}
  encryption_key: !secret api_encryption_key
  wifi_ssid: !secret wifi_ssid
  wifi_password: !secret wifi_password
  i2c_bus_id: i2c_bus

esphome:

logger:
  level: INFO

packages:
  # the shared remote source (url/ref/refresh) is defined once as a YAML anchor
  # and reused by the other packages via `<<: *kopfik_esphome_remote`
  base: &kopfik_esphome_remote
    url: https://github.com/kopfik/esphome
    ref: master            # while testing; pin a tag/commit for stable builds
    refresh: 1d
    files:
      - packages/base.yaml
  mqtt:
    <<: *kopfik_esphome_remote
    files:
      - path: packages/mqtt.yaml
        vars:
          id: !secret mqtt_id
          broker: !secret mqtt_broker
          port: !secret mqtt_port
  sht45:
    <<: *kopfik_esphome_remote
    files:
      - path: components/sensors/sht4x.yaml
        vars:
          id: sht45
          address: 0x44
          update_interval: 1
          window_size: 60
```

`<<: *kopfik_esphome_remote` simply reuses the shared `url/ref/refresh` block
defined on the first package — it is plain YAML, purely for readability.

### Repository layout

| Path | Contents |
|---|---|
| `packages/` | Core: `base`, `time`, `mqtt`, `sensors`, `ble_proxy` |
| `boards/` | Board definitions + power management (ESP32-S3/C6, …) |
| `components/buses/` | I²C, SPI, UART, 1-Wire buses |
| `components/sensors/` | Sensor packages (SHT4x, SCD4x, BMP, LD24xx, …) |
| `components/lights/` | RGB/LED strips, segments, monochromatic lights |
| `components/outputs/` | GPIO outputs, LEDC PWM, buzzer |
| `components/buttons/` | Buttons (e.g. PC power button) |
| `components/displays/` | Placeholder — displays are future work |
| `external_components/` | Placeholder — vendor/3rd-party code is not published here |
| `templates/` | Shared YAML snippets / anchors |
| `examples/` | Anonymized example device YAML |
| `media/` | Placeholder for future public / reusable media |
| `media.local/` | Convention for local/private media (gitignored here) |

### Package conventions

- A package file usually starts with a **header** showing include examples, so it
  is obvious how to call it and which `vars` it takes.
- Optional values use `${var | default(...)}`, so devices that do not pass them
  fall back to a sane default.
- Hardware-specific things (IDs, I²C addresses, offsets, intervals, pins, wiring)
  are passed as `vars`, not hard-coded in the package.
- **No secrets or secret lookups in packages** (remote packages cannot resolve
  them anyway).

### Sensors and hardware notes

Sensor packages live under `components/sensors/`; naming follows official ESPHome
platforms where it makes sense.

- **BMP58x:** `bmp58x_custom.yaml` = custom/manual-init implementation;
  `bmp581_i2c.yaml` = native ESPHome-style package.
- **Radar:** `ld2450.yaml` is the canonical LD2450 package.

### Media and displays

- `media/` is a placeholder for **future public / reusable** media.
- `media.local/` is a convention for **local/private** media in your ESPHome
  config; it is gitignored in this repo (contents are not committed).
- Displays are currently a **placeholder / future work**.

### Development / updates

`ref` controls what gets pulled:

- **`master`** — latest state, fine for testing.
- **tag / commit** — better for stable, reproducible builds (once published), so
  an old device does not start pulling the current `master`.

Nothing is flashed or uploaded from this repo. After editing a package, compile/
test the device in your ESPHome configuration, and only then commit / tag.

### License

This repository is licensed under the **MIT** License (see [`LICENSE`](LICENSE)).

ESPHome itself is licensed separately. This repository contains reusable ESPHome
YAML packages, documentation, and examples. Any future external/custom components
carry their own license and attribution.
