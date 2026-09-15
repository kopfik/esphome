# Meteohub

_Dokumentace je jen česky — produkt, jeho UI i názvy balíčků jsou české._
_Documentation is Czech only — the product UI and package names are Czech._

Meteohub je displej s meteo a vnitřními hodnotami: dashboard s kartičkami,
grafy za 100 minut a 25 hodin, hodiny, svátky, fotky, u dotykových kusů
i menu a ovládání PC. Hodnoty čte z Home Assistantu nebo z lokálních čidel
desky.

Tenhle soubor je **mapa**: co je kde a v jakém pořadí se to skládá. Podrobnosti
(vars, proč je co udělané jak je) jsou v **hlavičce každého souboru** —
ty jsou záměrně podrobné a jsou zdrojem pravdy. Když se tenhle README
a hlavička rozcházejí, platí hlavička.

---

## Historie

První generace byl jeden soubor `products/meteohub.yaml` (~1 200 řádků,
natvrdo 320×480 ST7796, bez dotyku, pevná sada stránek). Skládaná verze v tomhle
adresáři vedle něj rostla paralelně, všechna zařízení se na ni přepnula
a monolit byl **2026-09-15 smazán**. Poslední verze zůstává v git historii:

```
git show d431f27:products/meteohub.yaml
```

---

## Vrstvy

Celé repo se skládá po vrstvách a meteohub je nejvyšší z nich:

```
boards/        deska (ESP32-S3, P4, ...), PSRAM, power management
components/    sběrnice, displej, podsvícení, radar, čidla       <- HW, piny přes vars
products/meteohub/geo_*   rozměry panelu (jen substituce)
products/meteohub/core*   barvy, fonty, rámeček, přepínání stránek, (dotyk)
products/meteohub/...     stránky, kartičky, grafy, podsvícení     <- UI
device YAML    (mimo repo) co kde je zapojené + které stránky chci
```

Device YAML v meteohub části neřeší žádné souřadnice ani barvy — jen vybírá
balíčky a předává jim `vars` (id senzorů z HA, texty, prahy).

---

## Pořadí v `packages:` — na něm záleží

ESPHome slučuje balíčky v pořadí, v jakém jsou v `packages:`, a `!extend`
připojuje na **konec** seznamu. Z toho plynou dvě pravidla:

1. **Co je potřeba dřív, musí být výš.** Substituce z `geo_*.yaml` musí
   existovat, než se rozbalí lambdy v `core.yaml`; `id`, na které se
   `!extend` odkazuje, musí už být definované.
2. **Pořadí stránek = pořadí balíčků.** Přepínání stránek jede podle
   **indexu**, ne podle jména. Nic to nekontroluje — přehozený balíček se
   projeví jen tak, že tlačítka a select skáčou na špatné stránky.

Typické pořadí (shora dolů):

| # | Balíček | Poznámka |
|---|---|---|
| 1 | HW: `components/displays/...`, `components/lights/monochromatic.yaml` (podsvícení), `components/sensors/ld2410.yaml` (radar) | `core.yaml` na ně sahá pevnými `id`, viz níže |
| 2 | `geo_320x480.yaml` / `geo_240x320.yaml` | **první** z meteohub balíčků |
| 3 | `bez_radaru.yaml` | jen kus bez LD2410, **před** core |
| 4 | `core.yaml` nebo `core_touch.yaml` | touch verze core includuje sama |
| 5 | `hodiny.yaml` (+ `hodiny_touch.yaml`) | klidová stránka, pokud je — musí být **první stránka** (po startu se ukazuje první) |
| 6 | `podsviceni_radar.yaml` nebo `podsviceni_dotyk.yaml` | **jeden je povinný**, jinak se displej po startu nerozsvítí |
| 7 | `segment.yaml` | jen kus s TM1637, **za** podsvícením |
| 8 | `dashboard.yaml` (+ `dashboard_touch.yaml` hned za ním) | 1–N dashboardů |
| 9 | stránky: `pc.yaml`, `senzor.yaml`, `grafy*.yaml`, `graf*.yaml`, `svatky.yaml`, `foto*.yaml` | v pořadí, v jakém je chceš listovat |
| 10 | `menu.yaml` | dotykové kusy, okno přes stránku |
| 11 | `rotace.yaml` | volitelná slideshow |

Kartičky bez vlastní stránky (`velicina.yaml`, `karta.yaml`) a `skala.yaml`
žádnou stránku nepřidávají, takže jejich pozice pořadí stránek nerozbije.
Můžou být i **za** dashboardem, který jejich scripty volá — `id(...)`
v lambdách se hledá v celé výsledné konfiguraci, ne jen v tom, co je výš.
(Pořadí je důležité jen pro `!extend` a pro substituce, ne pro `id()`.)

---

## Co musí device definovat sám

`core.yaml` se odkazuje na tyhle `id` **pevně** (nejsou to vars). Když chybí,
ESPHome hlásí `Couldn't find ID ...`:

| id | Odkud typicky |
|---|---|
| `displej35` nebo `${display_id}` | `components/displays/ili9xxx/*.yaml` |
| `sntp_time` nebo `${time_id}` | `packages/time.yaml` |
| `display_backlight` | `components/lights/monochromatic.yaml` |
| `ld2410c_has_target` | `components/sensors/ld2410.yaml`, nebo `bez_radaru.yaml` |

Dotykové kusy navíc `touchscreen:` s `id` předaným jako var `touch_id`.
`pc.yaml` navíc `mqtt:` (`packages/mqtt.yaml`).

---

## Soubory

### Základ

| Soubor | Co dělá |
|---|---|
| `geo_320x480.yaml`, `geo_240x320.yaml` | rozměry panelu jako substituce; jiný displej = nový `geo_*` soubor, kreslicí balíčky se nemění |
| `core.yaml` | barvy a palety, fonty, rámeček se záhlavím, prázdná karta, select stránek a stránky po startu, obnovování displeje. Sám nic nekreslí |
| `core_touch.yaml` | `core.yaml` + ikony v liště (domeček, zpět, menu), obsluha dotyku, historie skoků |
| `bez_radaru.yaml` | záslepka `ld2410c_has_target` pro kus bez radaru |

### Podsvícení a doplňky

| Soubor | Co dělá |
|---|---|
| `podsviceni_radar.yaml` | svítí, když radar vidí člověka, po klidu zhasne (kusy bez dotyku) |
| `podsviceni_dotyk.yaml` | klidový jas na hodinách, pracovní jas jinde (dotykové kusy) |
| `segment.yaml` | připojí TM1637 k radaru a podsvícení |
| `rotace.yaml` | automatické přepínání stránek, perioda nastavitelná z HA |

### Dashboard a kartičky

| Soubor | Co dělá |
|---|---|
| `dashboard.yaml` | jedna stránka, mřížka 2×4 slotů; volá kreslicí scripty kartiček |
| `dashboard_touch.yaml` | klepnutí na kartičku otevře její grafy |
| `velicina.yaml` | senzor z HA + kartička (bez stránky) |
| `karta.yaml` | jen kartička nad **už existujícím** senzorem (lokální čidla desky) |
| `skala.yaml` | prahová barva hodnoty; používají ji kartičky i grafy |
| `svatky.yaml` | kartička svátku + stránka se sedmi dny |

### Grafy

| Soubor | Stránka |
|---|---|
| `senzor.yaml` | `velicina.yaml` + `grafy.yaml` — nejběžnější případ |
| `senzor_graf.yaml` | `velicina.yaml` + `graf.yaml` — pro malý panel |
| `grafy.yaml` | jedna veličina, dva panely (100 min + 25 h) |
| `graf.yaml` | jedna veličina, jeden velký graf |
| `grafy_2.yaml` | dvě veličiny, dva panely |
| `graf_2.yaml` | dvě veličiny, jeden velký graf |
| `graf_multi.yaml` | až čtyři čáry, čtvercový graf s legendou |
| `trasa.yaml` | přidá další čáru do už existujícího grafu |

### Ostatní stránky

| Soubor | Co dělá |
|---|---|
| `hodiny.yaml` | klidová stránka s velkými hodinami |
| `hodiny_touch.yaml` | klepnutí na hodiny → dashboard, 10 min bez doteku → zpět na hodiny |
| `foto.yaml` | obrázek zapečený ve firmware (~300 kB flash na 320×480) |
| `foto_online.yaml` | fotka stahovaná za běhu z HA, galerie se mění bez flashování |
| `pc.yaml` | ovládání PC přes MQTT (power / reset / dlouhý stisk), bez HA |
| `menu.yaml` | okno s až šesti odkazy, otevírá se ikonou v liště |

---

## Časté chyby

| Příznak | Příčina |
|---|---|
| Displej po startu nesvítí | chybí `podsviceni_radar.yaml` / `podsviceni_dotyk.yaml` |
| `Couldn't find ID 'ld2410c_has_target'` | kus bez radaru nemá `bez_radaru.yaml` |
| `ID ... redefined` | dvakrát stejný balíček se stejným `prefix` |
| Tlačítka / select skáčou na špatné stránky | pořadí balíčků v `packages:` neodpovídá pořadí stránek |
| Domeček skáče jinam, než má | `prvni_dashboard` / `pocet_dashboardu` v `core_touch.yaml` nesedí s pozicí dashboardů |
| Ikona se nevykreslí | glyph není ve fontu — přidat přes `font: - id: !extend font_icons` (viz `core.yaml`) |
| Stránka PC „nedostupná“ | `mqtt_prefix` není `topic_prefix` ovladače (od 2026-09 už ne jeho `controller_name`) |

---

## Font ikon

Material Design Icons se stahují z GitHubu, **pinnuté na tag `v7.4.47`**
ve všech souborech (`core.yaml`, `core_touch.yaml`, `menu.yaml`).
Nová verze = změnit tag ve všech naráz, jinak ESPHome stahuje dva různé fonty.
Proč pin: viz komentář u fontu v `core.yaml`.
