# Convenzioni dei dati (data/*.json)

Tutte le tabelle del regolamento di Five Parsecs from Home (3a ed.) trascritte in JSON, tradotte in italiano.
Ogni file ha una chiave `"_nota"` con la pagina del regolamento da cui viene.

## Tabelle a dadi
Una tabella è un array di righe con l'intervallo del tiro:
```json
{"da": 1, "a": 12, "nome": "Nome italiano", "en": "Nome inglese originale", "testo": "Effetto in italiano", "effetti": {...}}
```
- `da`/`a`: intervallo inclusivo (d100, d6, 2d6... il tipo di dado è indicato nella chiave `"_dado"` accanto alla tabella, es. `"_dado": "d100"`).
- Quando una tabella ha un dado proprio, si scrive come oggetto: `{"_dado": "d100", "righe": [ ... ]}`.
- `en`: il nome originale inglese, per controllare sul regolamento.
- `testo`: la regola completa in italiano (riassunta fedelmente, senza perdere nessuna condizione).
- `effetti`: la parte che il motore applica da solo (vedi sotto). Se un effetto non è esprimibile, va solo nel `testo` e si aggiunge `"manuale": true`.

## Effetti automatici (chiavi di `effetti`)
| chiave | valore | significato |
|---|---|---|
| `stat` | `{"reazioni":1, "velocita":1, "combattimento":1, "robustezza":1, "acume":1, "fortuna":1}` | modifica le statistiche del personaggio |
| `crediti` | `"1d6"`, `"2d6"`, `"-3"`, `5` | crediti guadagnati (negativo = persi) |
| `punti_storia` | intero | punti Storia |
| `patrono` / `rivale` | intero | aggiunge Patroni / Rivali |
| `dicerie` | intero | Dicerie di missione (Quest Rumors) |
| `xp` | intero | esperienza al personaggio interessato |
| `xp_casuale` | intero | esperienza a un membro a caso |
| `oggetti` | `["arma_bassa","arma_militare","arma_alta","equip","gadget", "bottino", "<id oggetto>"]` | tiri su tabelle o oggetti precisi |
| `scafo` | `"-1d6"` | danni (o riparazioni) allo scafo |
| `debito` | `"+2"` | debito della nave |
| `ferito_casuale` | intero | turni di recupero a un membro a caso |
| `recupero` | intero | un ferito recupera N turni |
| `perde_oggetto` | 1 | un oggetto a caso va perso |
| `prova` | `{"stat":"acume","soglia":5,"dado":"1d6","successo":{...},"fallimento":{...}}` | tiro 1d6+statistica contro soglia |
| `scelte` | `[{"testo":"...", "effetti":{...}}, ...]` | il giocatore sceglie tra opzioni |
| `manuale` | true | effetto non automatizzato: il gioco mostra il testo |

Altre chiavi specifiche di una tabella vanno documentate nella `_nota` del file.

## Statistiche (nomi usati ovunque)
`reazioni` (Reactions), `velocita` (Speed, pollici = caselle), `combattimento` (Combat Skill), `robustezza` (Toughness),
`acume` (Savvy), `fortuna` (Luck), `xp`.

## Griglia
Appendice II: 1 casella = 1 pollice, diagonale = 1. Quindi gittate e velocità in pollici valgono come caselle.
