# ESPHome Packages and Device Configs

**Jazyk / Language:** [🇨🇿 Česky](#česky) · [🇬🇧 English](#english)

---

## Česky

### Co to je

Veřejné, znovupoužitelné úložiště ESPHome **balíčků** (packages / komponent /
desek / šablon). Obsahuje **jen sdílené, parametrizované stavební bloky** — žádné
konkrétní zařízení, žádné secrety.

- **Tvoje zařízení a `secrets.yaml` sem nepatří.** Žijí v tvém privátním
  HA / site repu. Tenké device YAMLy odsud jen **tahají balíčky přes ESPHome
  remote (git) packages** (`url:` + `ref:` + `files:` + `vars:`).
- Parametrizace jde přes substituce ve stylu `${var | default(...)}`.
- Secrety se nikdy nedávají do balíčků — vyhodnotí se na straně device a předají
  se jako hodnota varu / substituce.
- Ukázku najdeš v [`examples/basic-device.yaml`](examples/basic-device.yaml).

### Struktura

| Cesta | Obsah |
|---|---|
| `packages/` | Jádro: `base`, `time`, `mqtt`, `sensors`, `ble_proxy` |
| `boards/` | Definice desek + power-management (ESP32-S3/C6, …) |
| `components/buses/` | I²C, SPI, UART, 1-Wire sběrnice |
| `components/sensors/` | Senzorové balíčky (SHT4x, SCD4x, BMP, LD24xx, …) |
| `components/lights/` | RGB/LED stripy, segmenty, monochromatická světla |
| `components/outputs/` | GPIO výstupy, LEDC PWM, bzučák |
| `components/buttons/` | Tlačítka (např. PC power button) |
| `components/displays/` | Placeholder (`.gitkeep`) — displeje jsou budoucí práce |
| `external_components/` | Placeholder (`.gitkeep`) — vendor/cizí kód se sem nepublikuje |
| `templates/` | Sdílené YAML kousky / kotvy |
| `media/` | Placeholder pro budoucí veřejná / znovupoužitelná média |
| `media.local/` | Lokální/privátní média per-site (gitignored, jen `.gitkeep`) |
| `examples/` | Anonymizovaný vzorový device YAML |

### Jak se to používá

Privátní device YAML (v HA) skládá funkce přes remote packages a předává jim
hodnoty přes `vars`. Stejný soubor jde uvést víckrát s jinými `vars` → víc
instancí (např. dva senzory ze stejného souboru). Kompletní příklad viz
[`examples/basic-device.yaml`](examples/basic-device.yaml):

```yaml
packages:
  shared:
    url: https://github.com/<your-user>/<your-public-repo>
    ref: main
    refresh: 1d
    files:
      - path: packages/base.yaml
      - path: components/sensors/sht4x.yaml
        vars: { id: sht40, address: "0x44", update_interval: "1", window_size: "60" }
```

### Konvence balíčků

- Soubor balíčku obvykle začíná **hlavičkou** s příklady includu (`Inline:` i
  `Block:`), aby bylo hned vidět, jak se volá a jaké bere vary.
- Volitelné hodnoty: `${var | default(...)}` → když je device nepředá, spadne to
  na rozumný default.
- Hardware-specifické věci (ID, I²C adresy, offsety, intervaly, piny, zapojení)
  se předávají jako `vars`, ne natvrdo v balíčku.
- **Žádné secrety ani odkazy na ně v balíčcích** (remote packages je stejně
  neumí vyhodnotit).

### Senzory

Senzorové balíčky jsou v `components/sensors/`, pojmenování drží oficiální
ESPHome platformy, kde to dává smysl.

- **BMP58x split:** `bmp58x_custom.yaml` = custom/manual-init implementace
  (nativní init byl nespolehlivý); `bmp581_i2c.yaml` = nativní ESPHome-style
  balíček pro budoucí použití.
- **Radar:** `ld2450.yaml` je kanonický LD2450 balíček.

### Vývojový workflow

1. Uprav balíček v tomhle repu.
2. Zkontroluj `git diff`.
3. **Zkompiluj/otestuj v Home Assistant** (device si balíky vezme z gitu dle
   `ref`).
4. Commitni / otaguj teprve, až build/test projde.

Žádné OTA / upload / flash z tohohle repa. Pinuj `ref` na tag/commit kvůli
reprodukovatelným buildům.

### Aktuální stav

- Struktura balíčků a úklid senzorových balíčků **úspěšně zkompilovány v HA**.
- Displeje, legacy d1mini a polish do veřejné šablony jsou budoucí práce.

---

## English

### What this repo is

A public, reusable repository of ESPHome **packages** (packages / components /
boards / templates). It contains **only shared, parameterized building blocks** —
no concrete devices, no secrets.

- **Your devices and `secrets.yaml` do not belong here.** They live in your
  private HA / site repo. Thin device YAMLs there just **pull packages via
  ESPHome remote (git) packages** (`url:` + `ref:` + `files:` + `vars:`).
- Parameterization uses substitutions in the `${var | default(...)}` style.
- Secrets are never placed in packages — they are resolved on the device side and
  passed in as a var / substitution value.
- See [`examples/basic-device.yaml`](examples/basic-device.yaml) for a worked
  example.

### Layout

| Path | Contents |
|---|---|
| `packages/` | Core: `base`, `time`, `mqtt`, `sensors`, `ble_proxy` |
| `boards/` | Board definitions + power management (ESP32-S3/C6, …) |
| `components/buses/` | I²C, SPI, UART, 1-Wire buses |
| `components/sensors/` | Sensor packages (SHT4x, SCD4x, BMP, LD24xx, …) |
| `components/lights/` | RGB/LED strips, segments, monochromatic lights |
| `components/outputs/` | GPIO outputs, LEDC PWM, buzzer |
| `components/buttons/` | Buttons (e.g. PC power button) |
| `components/displays/` | Placeholder (`.gitkeep`) — displays are future work |
| `external_components/` | Placeholder (`.gitkeep`) — vendor/3rd-party code is not published here |
| `templates/` | Shared YAML snippets / anchors |
| `media/` | Placeholder for future public / reusable media |
| `media.local/` | Local/private per-site media (gitignored, `.gitkeep` only) |
| `examples/` | Anonymized example device YAML |

### Usage pattern

A private device YAML (in HA) assembles features via remote packages and passes
values through `vars`. The same file can be listed multiple times with different
`vars` to create multiple instances (e.g. two sensors from one file). See
[`examples/basic-device.yaml`](examples/basic-device.yaml) for the full example:

```yaml
packages:
  shared:
    url: https://github.com/<your-user>/<your-public-repo>
    ref: main
    refresh: 1d
    files:
      - path: packages/base.yaml
      - path: components/sensors/sht4x.yaml
        vars: { id: sht40, address: "0x44", update_interval: "1", window_size: "60" }
```

### Package conventions

- A package file usually starts with a **header** showing both `Inline:` and
  `Block:` include examples, so it is obvious how to call it and which vars it
  takes.
- Optional values use `${var | default(...)}`, so devices that do not pass them
  fall back to a sane default.
- Hardware-specific things (IDs, I²C addresses, offsets, intervals, pins, wiring)
  are passed as `vars`, not hard-coded in the package.
- **No secrets or secret lookups in packages** (remote packages cannot resolve
  them anyway).

### Sensors

Sensor packages live under `components/sensors/`; naming follows official ESPHome
platforms where it makes sense.

- **BMP58x split:** `bmp58x_custom.yaml` = custom/manual-init implementation
  (native init was unreliable); `bmp581_i2c.yaml` = native ESPHome-style package
  for future use.
- **Radar:** `ld2450.yaml` is the canonical LD2450 package.

### Development workflow

1. Edit a package in this repo.
2. Review the `git diff`.
3. **Compile/test in Home Assistant** (devices pull packages from git per `ref`).
4. Commit / tag only after the compile/test passes.

No OTA / upload / flash from this repo. Pin `ref` to a tag/commit for
reproducible builds.

### Current status

- Package layout and sensor package cleanup **compiled successfully in HA**.
- Displays, legacy d1mini, and public-template polish are future work.
