### Score History — plan implementacji (US-012) jako część featuru Players

Ten dokument opisuje plan wdrożenia **score history** (event‑sourcing rankingów),
który jest powiązany z meczami, ale **ląduje w featurze Players** (zgodnie z
`plan.md` 129–155).

Kluczowa motywacja (legacy): możemy edytować wynik starszego meczu, więc musimy umieć
**przeliczyć cały score gracza**, a nie tylko “dodać kolejną deltę”.

---

## Stories / wymagania (źródła)

### US-012: Wprowadzenie wyniku meczu (`prd.md`)
- “Zapis home_score i away_score + score_meta.”
- “Po zapisie generowana jest delta wpływająca na ranking graczy, którzy zagrali.”
- “Edycja wyniku aktualizuje właściwą deltę i statystyki.”

### Notatki architektoniczne (źródło: `plan.md` 129–155)
- Score history jest powiązany z meczami.
- Po każdym meczu aktualizujemy score graczy biorących udział w meczu.
- Początkowy przykład algorytmu (uproszczenie): różnica bramek → delta dla wszystkich
  zawodników.
- Presentation: na razie brak osobnego ekranu; później w Player Details.
- To ma być w featurze Players, ale jako osobny doc.

---

## Kontrakt DB (źródło: `.ai/db_plan.md` 1.12)

Tabela `score_history`:
- `score_history_id` UUID (PK)
- `player_id` UUID (FK → `players`)
- `match_id` UUID NULLABLE (FK → `matches`)
- `delta` NUMERIC(6,3)
- `previous_rating` NUMERIC(6,3)
- `new_rating` NUMERIC(6,3)
- `created_at` TIMESTAMPTZ

Unikalność warunkowa:
- UNIQUE `(player_id, match_id)` **WHERE `match_id` IS NOT NULL**

Konsekwencje dla implementacji:
- dla wpisów powiązanych z meczem robimy **upsert** per `(player_id, match_id)`
- manualne korekty (match_id = NULL) są możliwe

---

## Decyzje i założenia

- Score history implementujemy w **Players** (nie w Matches).
- `players.score` nadal istnieje i jest wykorzystywane w UI, ale aktualizacja
  przebiega przez **recompute** z historii (żeby obsłużyć edycje starych meczów).
- Na MVP nie pokazujemy jeszcze historii w UI (tylko logika + gotowość pod Player Details).
- “match_score tuple [player score : enemy team score]”:
  - nie dodajemy nowej kolumny w `score_history` na MVP,
  - tę informację możemy wyliczać przez join do `matches` + przynależność gracza do teamu,
    lub trzymać w `matches.score_meta` jeśli będzie potrzebna do debugowania.

---

## Model domenowy (Players / Score History)

Encja:
- `ScoreHistoryEntry`
  - `scoreHistoryId`
  - `playerId`
  - `matchId?`
  - `delta` (double)
  - `previousRating` (double)
  - `newRating` (double)
  - `createdAt`

Ważne: `previousRating/newRating` są danymi pochodnymi, więc muszą być spójne z
przyjętym porządkiem “replay” (patrz niżej).

---

## Interfejsy i granice (Clean Architecture)

### Gdzie to żyje?
Propozycja struktury:

`app/lib/features/players/`
- `domain/entities/score_history_entry.dart`
- `domain/repositories/player_repository.dart` (rozszerzony)
- `application/usecases/`
  - `apply_match_score_to_players_use_case.dart`
  - `recompute_player_score_use_case.dart`
  - (opcjonalnie) `get_player_score_history_use_case.dart`
- `infrastructure/repositories/supabase_player_repository.dart` (rozszerzony)

### Zależności między feature’ami
Score history potrzebuje danych o meczu (kto grał, wynik):
- `Players` use case może zależeć od `MatchRepository` (feature Matches) **na poziomie application**,
  lub
- logika może być wywoływana z `UpdateMatchScoreUseCase` (Matches) i przekazywać już
  “listę playerId + delta” do Players.

Rekomendacja MVP:
- `UpdateMatchScoreUseCase` (Matches) po zapisie wyniku woła
  `ApplyMatchScoreToPlayersUseCase` (Players) z parametrami:
  - `matchId`
  - `homeScore`, `awayScore`
  - roster: `homePlayerIds`, `awayPlayerIds`

To minimalizuje cross-feature query w Players.

---

## Repozytorium (PlayerRepository) — zmiany

Zgodnie z `plan.md` dodajemy metodę w `PlayerRepository`:

- `Future<void> updatePlayerMatchScore({required String playerId, required String matchId, required double delta, required int playerTeamScore, required int enemyTeamScore})`

Uwaga: w DB nie trzymamy `playerTeamScore/enemyTeamScore` w `score_history` w MVP.
Te wartości są:
- wejściem do algorytmu (obliczanie `delta`), albo
- pomocniczym kontekstem do ewentualnego zapisu w `matches.score_meta`

Żeby spełnić “recompute całego score”, repo powinno też wspierać:

- `Future<void> recomputeAndPersistPlayerScore({required String playerId})`
  - pobiera `players.base_score`
  - pobiera całą historię `score_history` dla gracza (łącznie z manualnymi korektami)
  - **replay** w deterministycznym porządku, aktualizuje `previous_rating/new_rating`
  - aktualizuje `players.score` na wynik końcowy

Oraz wersję batch (ważne wydajnościowo):
- `Future<void> recomputeAndPersistPlayersScore({required List<String> playerIds})`

---

## Use case’y (Players)

### 1) `ApplyMatchScoreToPlayersUseCase`
Cel: po wprowadzeniu/edycji wyniku meczu zaktualizować `score_history` i score graczy.

Wejście:
- `matchId`
- `homePlayerIds`, `awayPlayerIds`
- `homeScore`, `awayScore`
- (opcjonalnie) `scoreType`, `scoreMeta`

Kroki:
1) oblicz `goalDiff = abs(homeScore - awayScore)`
2) zidentyfikuj zwycięzców/przegranych (albo remis)
3) dla każdego gracza wylicz `delta`:
   - uproszczenie (MVP): winners `+goalDiff`, losers `-goalDiff`, draw `0`
4) dla każdego gracza:
   - `playerRepository.updatePlayerMatchScore(...)` (upsert do `score_history`)
5) na końcu:
   - `playerRepository.recomputeAndPersistPlayersScore(playerIds)` (pełny recompute)

### 2) `RecomputePlayerScoreUseCase`
Cel: manualny recompute (np. gdy zmieniły się zasady liczenia lub korekty historyczne).

Wejście:
- `playerId` albo `squadId` (batch)

Kroki:
- pobiera historię, replay, aktualizuje `score_history` i `players.score`

### 3) (opcjonalnie) `GetPlayerScoreHistoryUseCase`
Na potrzeby przyszłego Player Details:
- pobranie listy `ScoreHistoryEntry` posortowanej rosnąco po “czasie meczu”

---

## Infrastructure (Supabase) — jak to spiąć bez “pół-transakcji”

Problem: aktualizacja `score_history` + recompute `players.score` to kilka operacji.

Rekomendacja: docelowo zrobić to jako **SQL funkcję (RPC)** w Postgres:
- `upsert_score_history_for_match(...)`
- `recompute_player_score(...)`

Na MVP (bez RPC) możemy:
- robić sekwencję operacji w Supabase i zaakceptować brak transakcyjności,
  bo to admin-only flow i mamy możliwość ponownego recompute.

Docelowe RPC ma sens, bo:
- edycja starego meczu wymaga spójnego “replay”
- unikamy stanów pośrednich w `players.score`

---

## Presentation

Na MVP: brak osobnej strony.

Później:
- w Player Details pokazujemy wykres/rozbicie (legacy `PlayerDetailPage` ma już “score history graph”),
  ale to będzie osobna iteracja po wdrożeniu logiki.

---

## Iteracyjny plan implementacji

### Etap A — Minimalna integracja z meczami (US-012 happy path)
- po `UpdateMatchScore` wywołujemy `ApplyMatchScoreToPlayersUseCase`
- generujemy wpisy `score_history` dla graczy w meczu
- przeliczamy `players.score` dla tych graczy

### Etap B — Obsługa edycji wyniku starszego meczu
- update istniejących wpisów `score_history` dla `(player_id, match_id)`
- pełny recompute `previous_rating/new_rating` i `players.score`

### Etap C — Przygotowanie pod Player Details
- `GetPlayerScoreHistoryUseCase` + mapowanie do UI

### Etap D — RPC / spójność (opcjonalnie, ale docelowo)
- migracja z funkcją SQL + ewentualny trigger/constrainty

---

## Otwarte punkty (do doprecyzowania przy implementacji)

- Porządek replay:
  - czy replay opieramy o `matches.created_at` (MVP),
  - czy dodajemy `matches.played_at` i replay po `played_at` (bardziej poprawne długofalowo).
- Jak traktujemy `score_type = cancelled/walkover`:
  - czy generuje wpisy `score_history`, czy pomijamy.
