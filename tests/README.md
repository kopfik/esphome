# Automatické testy (CI)

_Česky; stručně anglicky na konci._

## Co to je, jednou větou

Po každém pushi si GitHub sám vezme čerstvý kód, zkusí z něj přeložit šest
testovacích zařízení a u commitu ukáže ✅ (jde to) nebo ❌ (něco je rozbité).

## K čemu to je

Tohle repo je **knihovna**: na jednom balíčku visí desítky zařízení. Změna
v balíčku může rozbít zařízení, na které se zrovna nedíváš, a přišel bys na to
až za měsíc, když ho zkusíš zkompilovat v HA. CI to zkusí hned.

Příklad z praxe (2026-09-15): smazaný `packages/sensors.yaml` by rozbil
26 zařízení. Test hlásí přesně:

```
Error including file '../../packages/sensors.yaml': No such file or directory
```

**Co to hlídá:**
- `config` (sekundy) — platnost YAML: chybějící soubor nebo substituce,
  `ID redefined`, `Couldn't find ID`, rozbitý `!extend`, špatný typ hodnoty.
- `compile` (minuty) — jestli jde firmware opravdu přeložit: chyby v C++
  lambdách, nedostupný font, nekompatibilita s platformou (ESP8266 vs ESP32).

**Co to nehlídá:** chování na desce. Jestli svítí displej, chodí MQTT nebo
ovládání PC vidí ovladač, ukáže jen skutečný hardware.

**Nic to neflashuje ani nenasazuje.** Testovací zařízení neexistují, nemají
žádné skutečné hodnoty (klíče, SSID, broker jsou vymyšlené).

## Co mám dělat já

**Normálně nic.** Pushneš do Gitea, ta to hned zrcadlí na GitHub a tam se
test spustí sám. Když projde, nic se neděje.

**Když přijde mail „Run failed“ nebo je u commitu ❌:**

1. Otevři na GitHubu repo → záložka **Actions** → červený běh.
2. Vlevo uvidíš testovací zařízení (`c6-senzory`, `s3-meteohub`, `p4-dotyk`, ...),
   červené je to rozbité. Klikni na něj a rozbal červený krok.
3. Chybová hláška je stejná, jako by ti ukázal ESPHome v HA.
4. Nejrychlejší cesta: zkopíruj hlášku do Clauda / Codexu s tím, co jsi
   naposledy měnil.

**Před tagem** (`v0.1.0` a další): zkontroluj, že poslední commit má ✅. Teprve
pak otaguj a přepínej zařízení na nový tag.

**Pondělní běh:** jednou týdně to běží i bez tvé změny, s nejnovějším ESPHome.
Když spadne v pondělí ráno a ty jsi nic neměnil, rozbila to **nová verze
ESPHome** — dobré vědět dřív, než aktualizuješ ESPHome v HA.

## Spuštění u sebe (bez GitHubu)

Potřebuje docker. Z kořene repa:

```
sh tests/run.sh
```

Kontrola `config` všech zařízení, trvá pár sekund. Plný překlad (minuty):
`sh tests/run.sh compile`. Jedno zařízení: `sh tests/run.sh config d1mini`.

## Testovací zařízení

Každé pokrývá jinou kombinaci. Dohromady obsahují **každý balíček z repa**
kromě prázdného `boards/rpipico1w.yaml` (stav 2026-09-15). `graf.yaml`,
`grafy.yaml` a `skala.yaml` se natahují nepřímo přes jiné balíčky.

| Soubor | Deska | Co pokrývá |
|---|---|---|
| `devices/c6-senzory.yaml` | ESP32-C6, Wi-Fi | senzory na I²C (SHT4x, SCD4x, SGP4x, BMP58x, AHT20, BMP280, BH1750, MAX17048), baterie přes ADC, PWM, spínač, denní restart, skrytá Wi-Fi |
| `devices/s3-meteohub.yaml` | ESP32-S3 + PSRAM, Wi-Fi | meteohub bez dotyku: ST7796, TM1637, radar LD2410, dashboardy, veličiny, grafy, svátky, online fotka, rotace |
| `devices/s3z-maly-meteohub.yaml` | ESP32-S3-Zero, **Arduino** | malý meteohub: ST7789V 240×320, bez radaru, obrázek ve firmware, přidaná čára do grafu (trasa); gesta PAJ7620 (jen Arduino) |
| `devices/p4-dotyk.yaml` | ESP32-P4, ethernet | dotykový meteohub: ILI9488 + FT63x6, hodiny, menu, ovládání PC, kartičky nad lokálními čidly |
| `devices/s3dk-periferie.yaml` | ESP32-S3-DevKitC-1 | „sběrna“ zbytku: BLE proxy, ping, tlačítko PC, bzučák, LED pásek s úseky, LD2450, LD2420, OPT3001, BMP3xx, BMP581, ILI9488 |
| `devices/d1mini.yaml` | ESP8266 | jiná platforma: base, MQTT, TM1637, I²C, 1-Wire (DS18B20) |

Rozdíl proti skutečnému device YAML: balíčky se netahají z gitu
(`url:` + `files:`), ale lokálně přes `!include ../../packages/...`.
Díky tomu test ověřuje přesně ten commit, ve kterém běží.

## Kdy testovací zařízení upravit

- **Přidáš nový balíček** (senzor, stránku, desku) → přidej ho do
  nejpodobnějšího testovacího zařízení. Balíček, který v žádném není, test
  nehlídá.
- **Změníš vars balíčku** (nový povinný var, přejmenování) → uprav i testovací
  zařízení. Když zapomeneš, CI to připomene ❌ — to je v pořádku, přesně
  proto tam je.
- **Úplně nový typ zařízení** (nová platforma, nový produkt) → nový soubor
  v `devices/` a jeho jméno přidat do `matrix.device`
  v `.github/workflows/esphome.yml`. `tests/run.sh` si ho najde sám.

## Jak to vysvětlit kolegovi

> Je to jako Jenkins job, jen na GitHubu zdarma. Po každém pushi se
> v kontejneru s ESPHome zkusí přeložit šest vzorových zařízení, která dohromady
> používají všechny balíčky z repa. Když se něco rozbije, commit dostane
> červený křížek a přijde mail. Nic se nenasazuje, je to čistě kontrola, že
> knihovna jde přeložit.

## Technicky

- Workflow: `.github/workflows/esphome.yml` (GitHub Actions, veřejné repo =
  zdarma).
- Image: `ghcr.io/esphome/esphome:latest` — stejný, jaký se používá lokálně.
- Každé zařízení je samostatný job (matrix), `fail-fast: false`: když spadne
  jedno, ostatní doběhnou.
- Gitea tenhle workflow nespouští, pokud na ní nejsou zapnuté Gitea Actions
  s runnerem. Kdyby se to jednou zapnulo, načte i `.github/workflows/`.

---

## English (short)

Every push (mirrored from Gitea to GitHub) runs GitHub Actions: for each test
device in `tests/devices/` it runs `esphome config` and `esphome compile` in the
official ESPHome container. A weekly scheduled run catches breakage caused by new
ESPHome releases. Nothing is flashed or deployed; all values are fake. Run the
same check locally with `sh tests/run.sh` (add `compile` for a full build).
When adding a package, add it to the closest test device so CI covers it.
