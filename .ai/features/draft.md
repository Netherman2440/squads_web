
### Draft — plan implementacji (US-010…US-011)

Ten dokument opisuje **plan wdrożenia featuru Draft** (generowanie propozycji drużyn
oraz utworzenie meczu z wybranej propozycji), zgodnie z ustaleniami w
`.ai/features/matches.md`:

- Draft ma osobną trasę: `/squads/:squadId/matches/draft` (oddzielnie od `/create`).
- W draftach używamy **`Player`** (bez encji `MatchPlayer`).
- Drafty **nie są zapisywane w DB** (to obiekt tymczasowy/obliczeniowy).
- Draft jest **deterministyczny** (bez seed/losowości).
- Stan w UI: **Riverpod + AsyncValue + AsyncValue.guard** (jak w `PlayersNotifier`).

---

## Stories (źródło: `prd.md` US-010, US-011)

### US-010: Draft zbalansowanych drużyn
- “Mogę swobodnie dodawać i usuwać graczy do draftu.”
- “Z wybranej puli graczy losowanych jest do 20 propozycji…”
- “Propozycje są posortowane od najlepszej do najgorszej.”
- “Propozycje są deterministyczne, można je odtworzyć.”

### US-011: Utworzenie meczu z draftu
- “Wybór propozycji tworzy mecz z przypisanymi drużynami.”

Referencja UI (legacy):
- `DraftPage` generuje drafty i przechodzi do `CreateMatchPage`.
- `CreateMatchPage` pokazuje jedną propozycję naraz, ma strzałki lewo/prawo,
  reset zmian przy przełączeniu, edycję składów i przycisk “Create Match”.

---

## Routing i integracja z Matches

Docelowe trasy (ustalone):
- `/squads/:squadId/matches/create`
  - wybór graczy (available/selected) + akcja przejścia do draftu
- `/squads/:squadId/matches/draft`
  - ekran propozycji draftu + możliwość edycji rosterów + “Create Match”

Kontrakt nawigacji między trasami:
- `matches/create` przekazuje do `matches/draft`:
  - `squadId`
  - `selectedPlayerIds` (albo pełne obiekty `Player`, ale rekomendujemy IDs +
    pobranie/odczyt z providerów Players dla spójności)
- `matches/draft` po “Create Match”:
  - wywołuje `CreateMatchUseCase` (z featuru Matches) z **aktualnym stanem** obu list
    (po ewentualnych zmianach użytkownika)
  - nawigacja do `/squads/:squadId/matches/:matchId`

---

## Model domenowy (Draft)

Draft to czysta logika generowania propozycji.

### Encje
- `Draft`
  - `homePlayers: List<Player>`
  - `awayPlayers: List<Player>`
  - `homeTotalScore: double` (suma `player.score`)
  - `awayTotalScore: double`


---

## `DraftRepository` (Domain) i implementacja (Infrastructure)

### Interfejs domenowy
- `Future<List<Draft>> createDraft({required List<Player> players, int limit = 20})`

### Infrastructure: brak DB
Nie tworzymy tabel i migracji. Implementacja to lokalny “engine”:
- `DeterministicDraftEngine` / `LocalDraftRepository`
  - wejście: lista `Player` (z aktualnymi `score`)
  - wyjście: lista `Draft`

### Deterministyczny algorytm (MVP/target)

Wymaganie: brak losowości, powtarzalność wyników.

1) **Normalizacja wejścia**
- sortujemy wejściowych graczy deterministycznie (np. po `playerId`)

2) **Limit wejścia**
- dla N > 16: zwracamy błąd/Failure i UI pokazuje komunikat o limicie
  (zachowanie jak w story o limicie; szczegóły UX w Presentation)

3) **Generowanie podziałów**
- przy N parzystym: rozmiary drużyn \(k = N/2\)
- przy N nieparzystym: dopuszczamy nierówne rozmiary drużyn i zmieniamy sposób
  liczenia “mocy” drużyny do oceny balansu (szczegóły niżej)

Technicznie:
- enumerujemy kombinacje wyboru \(k\) graczy do home team,
  away team to “reszta”
- aby uniknąć duplikatów (home/away swap):
  - kanonizacja: np. wymagamy, by “najmniejszy playerId” zawsze należał do home

4) **Scoring propozycji**
- `homeTotalScore` i `awayTotalScore` trzymamy w obiekcie `Draft`.
- Do sortowania liczymy “effective total” (wartość tymczasowa):
  - **N parzyste**: `effective = sum(player.score)`
  - **N nieparzyste**: `effective = sum(player.score) - min(player.score)`
    (nie bierzemy pod uwagę najsłabszego zawodnika w drużynie)
- “Balance” liczymy jako wartość tymczasową do rankingu:
  - `balance = abs(effectiveHome - effectiveAway)`

5) **Sortowanie i tie-break**
- sort: `balance ASC` (liczone tylko na potrzeby rankingu, nie przechowujemy pola diff)
- tie-break deterministyczny:
  - np. lista ID w home jako string (zawsze posortowana) `ASC`

6) **Top-N**
- zwracamy do `limit` (domyślnie 20)

Złożoność:
- dla 16 graczy: \(C(16,8)=12870\) propozycji — OK na client-side.

### MVP fallback (jeśli chcemy szybko UI)
Na start możemy zwrócić 1–3 propozycje:
- split na pół po sortowaniu (lub prosty “zig-zag” po score),
żeby szybciej spiąć UX. Docelowo jednak trzymamy algorytm powyżej.

---

## Use case’y (Application)

- `CreateDraftUseCase`
  - `execute({required List<Player> players}) -> List<Draft>`
  - wywołuje `DraftRepository.createDraft(...)`

> `CreateMatchUseCase` należy do featuru Matches; Draft tylko go używa w UI.

---

## Presentation (UI) — `/matches/draft`

Inspiracja: legacy `CreateMatchPage`:
- strzałki lewo/prawo zmieniają propozycję
- przy zmianie propozycji resetujemy edycje do “oryginału”
- dwa scrollowalne składy obok siebie
- “Create Match” bierze **aktualny stan** kolumn

### Struktura ekranu
- AppBar:
  - tytuł: “Draft”
  - akcja: “Create Match”
- Góra:
  - nawigacja propozycji: `← [Draft i z N] →`
- Nad rosterami:
  - summary: `Home total` i `Away total`
- Body:
  - dwa panele (wide: obok siebie; narrow: jeden pod drugim)
  - roster A i roster B (scroll)
  - drag & drop playerów między listami

### Stan (Riverpod)
Rekomendacja: jeden Notifier dla całej sesji draftu:
- `DraftSessionNotifier extends Notifier<AsyncValue<DraftSessionState>>`
  - `DraftSessionState`:
    - `proposals: List<Draft>`
    - `selectedIndex: int`
    - `home: List<Player>` (editable)
    - `away: List<Player>` (editable)
    - nie edytujemy nazw drużyn w MVP Draft (domyślne: “FC Biali”, “Czarni United”)
  - `load({required squadId, required selectedPlayerIds})`:
    - pobiera `Player` z providerów Players (lub z cache)
    - `state = AsyncValue.guard(() => createDraftUseCase.execute(players: ...))`
    - inicjalizuje `home/away` z proposal[0]
  - `selectProposal(index)`:
    - resetuje `home/away` do oryginalnej propozycji `index`
  - `movePlayer(playerId, toSide)` / `swapPlayer(...)`:
    - przenosi gracza między listami

### Obsługa błędów i empty state
- `AsyncValue.error`: pokazujemy `SelectableText.rich` (czerwony tekst)
- `proposals.isEmpty`: “Brak propozycji — wybierz graczy w /matches/create”
- limit >16: błąd z czytelnym komunikatem

### Uprawnienia
- Draft dostępny tylko dla owner/admin (spójnie z Matches).

---

## Integracja z “dodawaniem/odejmowaniem graczy do draftu” (US-010)

Ta część jest realizowana głównie w `/matches/create`:
- tam użytkownik dobiera pulę graczy (selected/available)
- `/matches/draft` jest już “wynikiem” dla wybranej puli

Opcjonalnie (nie MVP):
- na `/matches/draft` dodać akcję “Back to selection”,
  zamiast edycji puli na tym ekranie.

---

## Iteracyjny plan implementacji

### Etap A — Draft route + skeleton UI (bez DnD)
- routing `/matches/draft`
- `DraftSessionNotifier` + ładowanie proposals
- nawigacja strzałkami i reset zmian
- “Create Match” stub (bez wywołania repo)

### Etap B — Deterministyczny engine + top 20
- implementacja enumeracji kombinacji + sort/tie-break
- limit >16 + komunikat

### Etap C — Edycja składów (drag & drop)
- przenoszenie zawodników między listami
- walidacja: gracz nie może być w obu drużynach

### Etap D — Integracja “Create Match”
- wywołanie `CreateMatchUseCase` z aktualnymi rosterami
- nawigacja do match details

---

## Ustalenia (po review)

- Dopuszczamy **nieparzystą** liczbę graczy.
  - Ranking draftów liczymy na “effective total”, gdzie z sumy drużyny
    odejmujemy wynik najsłabszego zawodnika (żeby wyrównać wpływ dodatkowego gracza).
- W MVP **nie edytujemy** `teamAName/teamBName` na draft screenie.
  - Domyślne nazwy: “FC Biali” i “Czarni United”.
  - Edycja nazw/kolorów dopiero później w match view (US-013).


