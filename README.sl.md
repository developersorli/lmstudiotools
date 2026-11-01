# LM Studio Tools

[English](README.md)

## Problem

Datoteke AI modelov so ogromne. Ena sama `.gguf` datoteka pogosto zavzame 4-8 GB,
velik kakovosten model lahko preseže 40 GB, uporabna zbirka modelov pa se hitro
sešteje na stotine gigabajtov ali več.

LM Studio upravlja knjižnico iz **enega samega modelskega imenika**, zato mora cela
zbirka stati na enem samem disku — običajno majhnem in dragem NVMe SSD — čeprav
večina modelov ne potrebuje takšne hitrosti.

## Rešitev

Skripte modele uvozijo v LM Studio prek **simboličnih povezav**, zato se knjižnica
fizično razteza hkrati čez več diskov (nič se ne kopira ali podvaja). Vsak model
lahko postavite tja, kjer ima smisel:

- **manjši, redkeje uporabljeni modeli** → počasnejše oziroma cenejše diske
  (SATA SSD, HDD, zunanji USB disk);
- **veliki, pogosto uporabljani modeli** → najhitrejšo in največjo disk (NVMe SSD).

LM Studio vse prikaže v eni združeni listi modelov, vsak model pa se naloži
z diske, na kateri dejansko leži. Poznejše preurejanje je poceni: odstranite
povezave, premaknite datoteke med diski in modele ponovno uvozite.

V tej namestitvi knjižnica obsega dva imenika:

- `/mnt/ssd/lmstudio` (imenik A)
- `/mnt/s2n/lmstudio` (imenik B, hkrati tudi modelski imenik LM Studio)

## Orodja

Vsaka skripta pokriva eno operacijo; skupaj omogočajo upravljanje z knjižnico,
razporejeno čez več diskov:

| Skripta | Namen |
|---|---|
| `import_models.sh` | Uvoz vseh `.gguf` modelov iz obeh imenikov v LM Studio prek simbolnih povezav |
| `duplicates.sh` | Poišče `.gguf` datoteke z enakim imenom v obeh imenikih (z polnimi potmi in velikostmi) |
| `remove_links.sh` | Odstrani simbolične povezave iz modelskega imenika; izvorne datoteke ostanejo netaknjene |
| `remove_empty_dirs.sh` | Odstrani prazne podimenike v modelskem imeniku; neprazni ostanejo |

## Tipični delovni tok

1. **Preveri podvojene modele:**
   ```sh
   ./duplicates.sh
   ```
   Odloči, kateri disk bo vir za vsak model (npr. pogosteje uporabljane na SSD).

2. **(Opcionalno) Suhi pregled uvoza — brez kakršnegakoli učinka:**
   ```sh
   ./import_models.sh --dry-run
   ```

3. **Zgradi združeno knjižnico** (simbolične povezave v LM Studio):
   ```sh
   ./import_models.sh
   ```
   Izpiše povzetek `Skupaj / uspešno / napak`; če kak uvoz odpove, je izhodna koda `2`.

4. **Ponastavitev** (odstrani povezave in počiščene mape):
   ```sh
   ./remove_links.sh -y
   ./remove_empty_dirs.sh -y
   ```

## Uporaba po skriptah

### import_models.sh

```sh
./import_models.sh [--dry-run] [-h|--help]
```

| Opcija | Pomen |
|---|---|
| `--dry-run`, `-n` | Izpiše, kaj bi bilo uvoženo, brez dejanskega uvoza (ne zahteva ukaza `lms`) |
| `-h`, `--help` | Prikaz pomoči in izhod |

Imenike prilagodite v seznamu `DIRS` na začetku skripte.

**Pravila imenovanja user-repo:**
- Izdajatelj = prvi podimenik relativne poti (`Qwen/Qwen-7B.gguf` → `Qwen/Qwen-7B`).
- Datoteka neposredno v korenu imenika → izdajatelj `local`.
- Ponovljene user-repo vrednosti (isto ime datoteke, ki bi dalo isti user-repo) so opozorjene; drugi uvoz lahko prekine ali prepiše prvega.

**Izhodne kode:** `0` uspeh · `1` napaka zagona / manjkajoč `lms` / neznana opcija · `2` vsaj en uvoz ni uspel.

### duplicates.sh

```sh
./duplicates.sh
```

Primerja **baze imen** (brez poti) vseh `.gguf` datotek iz obojima imenikoma in za
vsak skupni zadetek izpiše polne poti ter velikosti. Ker se primerja samo ime, so na
seznamu tudi datoteke z istim imenom v različnih podimenikih (npr. `Qwen/x.gguf` in
`Meta/x.gguf`) — pri vsakem zadetku preverite polne poti.

**Izhodne kode:** `0` uspešno (tudi če podvojenih ni) · `1` manjkajoč imenik.

### remove_links.sh

```sh
./remove_links.sh [-y|--yes]
```

Najprej izpiše vse najdene povezave z njihovimi cilji (suhi pregled), nato po
potrditvi izbriše samo same povezave — njihovi cilji ostanejo netaknjeni.

| Opcija | Pomen |
|---|---|
| `-y`, `--yes` | Ne vprašaj za potrditev; izbriši takoj |

**Izhodne kode:** `0` uspeh/preklic · `1` napaka (imenik ne obstaja / neznana opcija).

### remove_empty_dirs.sh

```sh
./remove_empty_dirs.sh [-y|--yes]
```

Najprej izpiše vse prazne podimenike (suhi pregled), nato po potrditvi jih izbriše.
Imeniki se zberejo enkrat in brišejo s tega seznama, zato so prikazani in izbrisani
natanko isti. Neprazni imeniki ostanejo netaknjeni.

| Opcija | Pomen |
|---|---|
| `-y`, `--yes` | Ne vprašaj za potrditev; izbriši takoj |

**Izhodne kode:** `0` uspeh/preklic · `1` napaka (imenik ne obstaja / neznana opcija).

## Zgodovina / opombe

- Skripte so sprva imele pripono `_fixed`, ker so nastale iz originalov s Windows
  prelomi vrstic; kasneje so bile preimenovane v trenutna imena brez priponke:
  ```sh
  tr -d '\r' < import_models.sh > import_models_fixed.sh
  chmod +x import_models_fixed.sh
  ```
- Vse skripte zdaj uporabljajo LF prelome in imajo dokumentacijske hederje znotraj datoteke.
