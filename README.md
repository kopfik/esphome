# ESPHome Packages and Device Configs

**Jazyk / Language:** [🇨🇿 Česky](#česky) · [🇬🇧 English](#english)

---

## Česky

### Co repo obsahuje

Veřejné, znovupoužitelné ESPHome **balíčky** — sdílené, parametrizované stavební
bloky pro stavbu zařízení: jádrové balíčky, definice desek, komponenty (sběrnice,
senzory, displeje, světla, výstupy, tlačítka, spínače), hotové **produkty**
(meteohub), šablony a příklady.

Repo **neobsahuje** konkrétní zařízení, `secrets.yaml`, reálná media ani vendor
kód displejů. Ty zůstávají u tebe v lokální ESPHome / Home Assistant konfiguraci.

### Vrstvy

Zařízení se skládá odspodu nahoru. Každá vrstva řeší jednu věc a vyšší vrstva
se spoléhá na nižší:

```
boards/                deska: čip, framework, PSRAM, power management
components/buses/      fyzické sběrnice: I²C, SPI, UART, 1-Wire
components/...         jednotlivé kusy HW: senzor, displej, světlo, výstup   <- piny přes vars
products/              hotové funkční celky nad komponentami (meteohub)
device YAML            (mimo repo) "jsem tahle deska, tady mám tyhle kusy"
packages/              průřezové věci pro všechny: síť, API, čas, MQTT
```

Device YAML by ideálně neměl obsahovat žádnou logiku — jen vybrat balíčky
a předat jim piny, adresy, id a texty.

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
- volitelně **`media.local/`** — lokální/privátní média (viz [Displeje a média](#displeje-a-média)).

Secrety se vyhodnocují **v lokálním device YAML / lokální ESPHome konfiguraci**,
nikdy ne uvnitř remote balíčků — ESPHome `!secret` uvnitř natažených souborů
neumí vyhodnotit. Vyřeš je tedy lokálně (typicky v `substitutions:` přes
`!secret …`) a do balíčků je předej jako hodnotu varu / substituce (`${…}`).

### Příklad device YAML

Tohle žije v **tvé** konfiguraci, ne tady. Zkrácená ukázka; celé zařízení
s deskou, sběrnicí a víc senzory viz
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
  time:
    <<: *kopfik_esphome_remote
    files:
      - packages/time.yaml
  mqtt:
    <<: *kopfik_esphome_remote
    files:
      - path: packages/mqtt.yaml
        vars:
          id: !secret mqtt_id
          broker: !secret mqtt_broker
          port: !secret mqtt_port
  # script, přes který všechny senzory posílají hodnoty do MQTT
  mqtt_publish_json:
    <<: *kopfik_esphome_remote
    files:
      - packages/mqtt_publish_json.yaml
  # ... deska (boards/) a I²C sběrnice (components/buses/i2c.yaml) viz examples/
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
| `packages/` | Průřezové jádro: `base` (Wi-Fi + API + OTA), `base_eth` (totéž po ethernetu), `time`, `mqtt`, `mqtt_publish_json`, `auto_restart`, `ble_proxy` |
| `boards/` | Desky (ESP32-S3 SuperMini / DevKitC-1 / Zero, ESP32-C6 SuperMini, ESP32-P4-ETH, D1 mini), `esp32-s3_psram` (PSRAM, i pro P4), `esp32_powersave`. `rpipico1w.yaml` je zatím prázdný |
| `components/buses/` | I²C (seznam → víc sběrnic), SPI, UART, 1-Wire |
| `components/sensors/` | SHT4x, AHT20, SCD4x, SGP4x, BMP280 / BMP3xx / BMP581 / BMP58x, BH1750, OPT3001, DS18B20, LD2410 / LD2420 / LD2450, PAJ7620, MAX17048, baterie přes ADC, teplota čipu, ping |
| `components/displays/` | ST7796, ST7789V, ILI9488 (standardní + kalibrace „yellow board“), TM1637 |
| `components/lights/` | RGB LED na desce, WS2812 pásek, segmenty pásku, monochromatické světlo (podsvícení) |
| `components/outputs/` | GPIO výstup, LEDC PWM, bzučák (RTTTL) |
| `components/buttons/` | Tlačítko restartu, tlačítko PC (power/reset) |
| `components/switches/` | GPIO spínač |
| `products/` | Hotové celky — [`meteohub`](products/meteohub/README.md) |
| `external_components/` | Placeholder — vendor/cizí kód se sem nepublikuje |
| `templates/` | Sdílené YAML kotvy (`light.yaml`) |
| `examples/` | Anonymizovaný vzorový device YAML |
| `media/` | Placeholder pro budoucí veřejná / znovupoužitelná média |
| `media.local/` | Konvence pro lokální/privátní média (zde gitignored) |

### Konvence balíčků

- Soubor balíčku začíná **hlavičkou** s příklady includu (Inline / Block), aby
  bylo hned vidět, jak se volá a jaké bere `vars`. Pod ní bývá vysvětlení
  **proč** je něco udělané tak, jak je (quirky ESPHome, HW, naměřené hodnoty).
  Ty komentáře jsou záměrně podrobné a jsou hlavní dokumentací balíčku.
- Volitelné hodnoty se píšou jako `${var | default(...)}` → když je device
  nepředá, spadne to na rozumný default.
- Hardware-specifické věci (ID, I²C adresy, offsety, intervaly, piny, zapojení)
  se předávají jako `vars`, ne natvrdo v balíčku.
- Některé balíčky na sebe odkazují **pevnými `id`** (např. `sntp_time`,
  `mqtt_publish_json`, `restart_button`). Hlavička to uvádí jako
  „Requires“ / „Vyžaduje“; když chybí, ESPHome hlásí `Couldn't find ID`.
- **Žádné secrety ani odkazy na ně v balíčcích** (remote packages je stejně
  neumí vyhodnotit).

### MQTT a telemetrie

Senzory mají dvě cesty ven — jednu pro sběr dat, druhou pro Home Assistant:

```
čidlo ──> RAW senzor (internal: true)
            │  on_value
            ├──> script mqtt_publish_json ──> MQTT ${topic_prefix}/<sub_topic>
            │                                  {"value":23.45,"ts":1757937600123}
            └──> copy + klouzavý průměr ─────> Home Assistant (přes API)
```

- **Raw hodnota** jde hned do MQTT jako JSON s časem měření: `ts` jsou
  milisekundy od epochy (UTC). Určeno pro InfluxDB / analýzu. Neposílá se,
  dokud SNTP nemá platný čas, a `NaN` se zahazuje. Neretainuje se.
- **Kopie pro HA** (`platform: copy`) je zprůměrovaná přes `window_size`
  vzorků a posílá se jednou za okno — hezká hodnota pro UI a menší historie
  v HA.
- `sub_topic` je obvykle `<veličina>_<id>` (`temperature_sht45`); baterie
  (`battery_stats`, `max17048`) používají `<id>_voltage` / `<id>_capacity`.
- **Všechno MQTT jednoho zařízení je pod jedním prefixem** — substituce
  `topic_prefix`. `packages/mqtt.yaml` ji používá i pro vlastní topicy ESPHome:
  `${topic_prefix}/status` (online/offline), `/debug` (logy),
  `/<typ>/<object_id>/state` a `/command`. Na ty se dá odkazovat z jiného
  zařízení (např. ovládání PC v meteohubu). `discovery` je vypnuté — do HA
  jdou entity přes API.

Povinné substituce device YAML: `controller_name`, `encryption_key`,
`wifi_ssid`, `wifi_password` (u `base.yaml`), `topic_prefix` (u MQTT).

### Senzory a hardware poznámky

Senzorové balíčky jsou v `components/sensors/`; pojmenování drží oficiální
ESPHome platformy, kde to dává smysl.

- **BMP58x:** `bmp58x_custom.yaml` = custom/manuální-init implementace;
  `bmp581_i2c.yaml` = nativní ESPHome-style balíček.
- **Radar:** `ld2450.yaml` je kanonický LD2450 balíček.
- **MAX17048:** používá ESPHome platformu `max17043` (převod napětí sedí
  numericky); pozor na propojku VS — s VS na Bat a bez připojeného
  článku čip po I²C neodpovídá. Detaily v hlavičce souboru.
- **Teplota čipu** (`internal_temperature.yaml`) je samostatný balíček — jen
  ESP32, na ESP8266 ji nepřidávat.
- **ESP8266 (D1 mini):** předávej `wifi_power_saver: none` a
  `api_max_connections: 4` — defaulty balíčků jsou nastavené pro ESP32.

### Displeje a média

- `components/displays/` obsahují **jen HW definici** displeje (model, piny,
  rozměry, u ILI9488 i zrcadlení). Co se kreslí, přidává device nebo produkt přes
  `display: - id: !extend <id>`.
- `ili9488_yellow_board.yaml` je ILI9488 s kalibrační init sekvencí pro
  konkrétní špatnou sérii panelů (mléčné barvy); běžný panel = `ili9488.yaml`.
- `media/` je placeholder pro **budoucí veřejná / znovupoužitelná** média.
- `media.local/` je konvence pro **lokální/privátní** média ve tvé ESPHome
  konfiguraci; v tomhle repu je gitignored (obsah se necommituje).

### Produkty

- **[Meteohub](products/meteohub/README.md)** — displej s dashboardem, grafy,
  hodinami, svátky a fotkami; dotyková varianta s menu a ovládáním PC.
  Skládá se z desítek malých balíčků v `products/meteohub/`; README tam
  popisuje jejich pořadí a závislosti.

### Vývoj / aktualizace

`ref` určuje, co se natáhne:

- **`master`** — nejnovější stav, OK na testování.
- **tag** — pro stabilní, reprodukovatelné buildy, aby ti starý device nezačal
  tahat aktuální `master`. Zatím žádný není, první bude `v0.1.0`.
- Změny, které vyžadují úpravu device YAML, jsou v [`CHANGELOG.md`](CHANGELOG.md)
  v sekci **Breaking** i s postupem migrace. Před přepnutím zařízení na nový
  tag si ji projdi.

Z tohohle repa se neflashuje ani neuploaduje. Po úpravě balíčku zkompiluj/otestuj
zařízení ve své ESPHome konfiguraci a teprve pak commitni / otaguj.

### Transparentnost / AI

Značná část tohoto repozitáře (balíčky i dokumentace) vznikla s pomocí AI
asistentů a poté byla ručně zkontrolována a otestována na reálných zařízeních.
Kód je záměrně malý a čitelný, aby šel snadno číst.

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
displays, lights, outputs, buttons, switches), ready-made **products**
(meteohub), templates, and examples.

The repo does **not** contain concrete devices, `secrets.yaml`, real media, or
vendor display code. Those stay in your own local ESPHome / Home Assistant
configuration.

### Layers

A device is assembled bottom-up. Each layer handles one thing and relies on the
layers below it:

```
boards/                the board: chip, framework, PSRAM, power management
components/buses/      physical buses: I²C, SPI, UART, 1-Wire
components/...         individual hardware: sensor, display, light, output   <- pins via vars
products/              complete features built on components (meteohub)
device YAML            (outside this repo) "I am this board, I have these parts"
packages/              cross-cutting pieces for everything: network, API, time, MQTT
```

Ideally a device YAML contains no logic at all — it only picks packages and
passes them pins, addresses, ids and labels.

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
- optionally **`media.local/`** — local/private media (see [Displays and media](#displays-and-media)).

Secrets are resolved **in your local device YAML / local ESPHome config**, never
inside remote packages — ESPHome cannot resolve `!secret` inside the pulled files.
Resolve them locally (typically in `substitutions:` via `!secret …`) and pass them
into packages as a var / substitution value (`${…}`).

### Example device YAML

This lives in **your** configuration, not here. A shortened sample; for a full
device with board, bus and more sensors see
[`examples/device-with-many-sensors.yaml`](examples/device-with-many-sensors.yaml):

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
  time:
    <<: *kopfik_esphome_remote
    files:
      - packages/time.yaml
  mqtt:
    <<: *kopfik_esphome_remote
    files:
      - path: packages/mqtt.yaml
        vars:
          id: !secret mqtt_id
          broker: !secret mqtt_broker
          port: !secret mqtt_port
  # the script every sensor uses to publish its values to MQTT
  mqtt_publish_json:
    <<: *kopfik_esphome_remote
    files:
      - packages/mqtt_publish_json.yaml
  # ... board (boards/) and I²C bus (components/buses/i2c.yaml), see examples/
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
| `packages/` | Cross-cutting core: `base` (Wi-Fi + API + OTA), `base_eth` (same over ethernet), `time`, `mqtt`, `mqtt_publish_json`, `auto_restart`, `ble_proxy` |
| `boards/` | Boards (ESP32-S3 SuperMini / DevKitC-1 / Zero, ESP32-C6 SuperMini, ESP32-P4-ETH, D1 mini), `esp32-s3_psram` (PSRAM, also used for P4), `esp32_powersave`. `rpipico1w.yaml` is still empty |
| `components/buses/` | I²C (a list → multiple buses), SPI, UART, 1-Wire |
| `components/sensors/` | SHT4x, AHT20, SCD4x, SGP4x, BMP280 / BMP3xx / BMP581 / BMP58x, BH1750, OPT3001, DS18B20, LD2410 / LD2420 / LD2450, PAJ7620, MAX17048, ADC battery, chip temperature, ping |
| `components/displays/` | ST7796, ST7789V, ILI9488 (stock + "yellow board" calibration), TM1637 |
| `components/lights/` | Onboard RGB LED, WS2812 strip, strip partitions, monochromatic light (backlight) |
| `components/outputs/` | GPIO output, LEDC PWM, buzzer (RTTTL) |
| `components/buttons/` | Restart button, PC button (power/reset) |
| `components/switches/` | GPIO switch |
| `products/` | Complete features — [`meteohub`](products/meteohub/README.md) (Czech docs) |
| `external_components/` | Placeholder — vendor/3rd-party code is not published here |
| `templates/` | Shared YAML anchors (`light.yaml`) |
| `examples/` | Anonymized example device YAML |
| `media/` | Placeholder for future public / reusable media |
| `media.local/` | Convention for local/private media (gitignored here) |

### Package conventions

- A package file starts with a **header** showing include examples (Inline /
  Block), so it is obvious how to call it and which `vars` it takes. Below it
  there is usually an explanation of **why** things are done the way they are
  (ESPHome and hardware quirks, measured values). These comments are
  intentionally detailed and are the package's main documentation (partly in
  Czech).
- Optional values use `${var | default(...)}`, so devices that do not pass them
  fall back to a sane default.
- Hardware-specific things (IDs, I²C addresses, offsets, intervals, pins, wiring)
  are passed as `vars`, not hard-coded in the package.
- Some packages reference each other through **fixed `id`s** (e.g. `sntp_time`,
  `mqtt_publish_json`, `restart_button`). The header lists them under
  "Requires" / "Vyžaduje"; if one is missing, ESPHome reports `Couldn't find ID`.
- **No secrets or secret lookups in packages** (remote packages cannot resolve
  them anyway).

### MQTT and telemetry

Sensors have two ways out — one for data collection, one for Home Assistant:

```
sensor ──> RAW sensor (internal: true)
             │  on_value
             ├──> script mqtt_publish_json ──> MQTT ${topic_prefix}/<sub_topic>
             │                                  {"value":23.45,"ts":1757937600123}
             └──> copy + moving average ──────> Home Assistant (via API)
```

- The **raw value** goes straight to MQTT as JSON with its measurement time:
  `ts` is milliseconds since the epoch (UTC). Meant for InfluxDB / analysis.
  Nothing is sent until SNTP has a valid time, and `NaN` is dropped. Not
  retained.
- The **HA copy** (`platform: copy`) is averaged over `window_size` samples and
  sent once per window — a clean value for the UI and less history in HA.
- `sub_topic` is usually `<quantity>_<id>` (`temperature_sht45`); batteries
  (`battery_stats`, `max17048`) use `<id>_voltage` / `<id>_capacity`.
- **All MQTT of one device lives under one prefix** — the `topic_prefix`
  substitution. `packages/mqtt.yaml` uses it for ESPHome's own topics too:
  `${topic_prefix}/status` (online/offline), `/debug` (logs),
  `/<type>/<object_id>/state` and `/command`. Other devices can use those
  (e.g. PC control in meteohub). `discovery` is off — entities reach HA via
  the API.

Required device substitutions: `controller_name`, `encryption_key`,
`wifi_ssid`, `wifi_password` (for `base.yaml`), `topic_prefix` (for MQTT).

### Sensors and hardware notes

Sensor packages live under `components/sensors/`; naming follows official ESPHome
platforms where it makes sense.

- **BMP58x:** `bmp58x_custom.yaml` = custom/manual-init implementation;
  `bmp581_i2c.yaml` = native ESPHome-style package.
- **Radar:** `ld2450.yaml` is the canonical LD2450 package.
- **MAX17048:** uses the ESPHome `max17043` platform (voltage conversion is
  numerically identical); mind the VS jumper — with VS on Bat and no cell attached
  the chip does not answer on I²C. Details in the file header.
- **Chip temperature** (`internal_temperature.yaml`) is a separate package —
  ESP32 only, do not add it on ESP8266.
- **ESP8266 (D1 mini):** pass `wifi_power_saver: none` and
  `api_max_connections: 4` — package defaults are tuned for ESP32.

### Displays and media

- `components/displays/` hold **only the hardware definition** of a display
  (model, pins, dimensions, mirroring on ILI9488). What gets drawn is added by the device or
  a product via `display: - id: !extend <id>`.
- `ili9488_yellow_board.yaml` is an ILI9488 with a calibration init sequence for
  one specific bad panel batch (milky colors); a normal panel = `ili9488.yaml`.
- `media/` is a placeholder for **future public / reusable** media.
- `media.local/` is a convention for **local/private** media in your ESPHome
  config; it is gitignored in this repo (contents are not committed).

### Products

- **[Meteohub](products/meteohub/README.md)** — a display with a dashboard,
  graphs, clock, name days and photos; a touch variant adds a menu and PC
  control. It is assembled from dozens of small packages in
  `products/meteohub/`; the README there (Czech) describes their order and
  dependencies.

### Development / updates

`ref` controls what gets pulled:

- **`master`** — latest state, fine for testing.
- **tag** — for stable, reproducible builds, so an old device does not start
  pulling the current `master`. None yet; the first one will be `v0.1.0`.
- Changes that require editing device YAML are listed in
  [`CHANGELOG.md`](CHANGELOG.md) under **Breaking**, with migration steps.
  Read it before switching devices to a new tag.

Nothing is flashed or uploaded from this repo. After editing a package, compile/
test the device in your ESPHome configuration, and only then commit / tag.

### Transparency / AI

A substantial part of this repository (packages and documentation) was produced
with the help of AI coding assistants, then reviewed and tested on real devices
by the maintainer. The code is kept intentionally small and readable so it can be
inspected directly.

### License

This repository is licensed under the **MIT** License (see [`LICENSE`](LICENSE)).

ESPHome itself is licensed separately. This repository contains reusable ESPHome
YAML packages, documentation, and examples. Any future external/custom components
carry their own license and attribution.
