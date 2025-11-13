### Aktualna struktura UI (Flutter) – legacy

> Uwaga: Ten dokument opisuje **legacy Flutter UI** z poprzedniej
> implementacji. Nowy frontend Squads Web jest budowany **od zera**
> w oparciu o Clean Architecture (DDD) i feature-first strukturę.
> Poniższy opis służy wyłącznie jako referencja UX oraz mapa
> istniejących przepływów — **nie** jest kodową bazą do dalszej
> rozbudowy.

Poniższy opis podsumowuje to, co było zaimplementowane we frontendzie
(Flutter), z mapą ekranów, przepływów, zarządzania stanem i kluczowych
widżetów. Odnosi się do wymagań z MVP i PRD i wskazuje luki istotne
przy analizie UX na potrzeby nowej architektury UI, map podróży
użytkownika i struktury nawigacji.

---

## Wejście do aplikacji i konfiguracja
- MaterialApp: `home: AuthPage()`; domyślny motyw: `AppTheme.darkTheme`.
- Konfiguracja środowiska: `AppConfig.initialize()` ładuje `.env.prod`; adres API: `API_BASE_URL/api/v1` (z `.env`).
- Brak zdefiniowanych „named routes” – nawigacja imperatywna przez `Navigator.push(...)`/`pushReplacement(...)`.

## Inwentarz ekranów i główne funkcje

1) AuthPage
- Formularz loginu (login/hasło) + „Continue as Guest”.
- Po sukcesie: ustawienie tokenu i (opcjonalnie) danych usera w `userSessionProvider`, przejście do `SquadListPage`.
- Walidacja prostych pustych pól; komunikaty przez `MessageService`.

2) SquadListPage
- Lista składów zalogowanego użytkownika (lub dostępnych publicznie z backendu).
- Akcje: odśwież, wyloguj; FAB do utworzenia nowego składu (tylko gdy `user != null`).
- Karta składu pokazuje nazwę, liczbę graczy, datę utworzenia, znacznik „Owner” jeśli użytkownik jest właścicielem.
- Nawigacja: tap → `SquadPage(squadId)`.

3) SquadPage
- Pobranie szczegółów składu i zasilenie stanu: `squadProvider`, `playersProvider`, `matchesProvider`.
- Sekcje: Informacje o składzie; „kafle” do Players, Matches, Tournaments (ostatni placeholder).
- Statystyki składu: liczba graczy, liczba meczów, gole, średnie (komponent `_SquadDetailedStatsList`).
- Akcje właściciela: placeholder „Edit squad”.
- Nawigacja: Players → `PlayersPage`; Matches → `MatchHistoryPage`.

4) PlayersPage
- Wczytanie graczy (jeśli potrzeba – także szczegóły składu). Zależny od `playersProvider`.
- Widok listy graczy: `PlayersListWidget` (wyszukiwanie, sortowanie: name/score/createdAt, A→Z/Z→A itp.).
- FAB „Dodaj gracza” dla właściciela (dialog `CreatePlayerWidget`).
- Tap gracza → `PlayerDetailPage`.

5) PlayerDetailPage
- Wczytanie szczegółów gracza: statystyki, historia wyniku (wykres `fl_chart`), karuzela statystyk (`StatsCarousel`).
- Możliwość edycji imienia i „score” dla właściciela; usunięcie gracza (aktualizacja listy w `playersProvider`).
- Layout responsywny (węższy/szerszy).

6) MatchHistoryPage
- Lista meczów składu; karty pokazują skrócony identyfikator, datę i wynik (jeśli istnieje).
- FAB (tylko właściciel): przejście do draftu → `DraftPage`.
- Tap meczu → `MatchPage(squadId, matchId)`.

7) DraftPage
- Dwa widoki: wybrani gracze (góra) i dostępni gracze (dół).
- Dodawanie/odejmowanie graczy do draftu (dla właściciela). Stan w `draftProvider`.
- Akcja „Draft”: wywołanie backendu (`MatchService.drawTeams`) i przejście do `CreateMatchPage` z listą draftów.

8) CreateMatchPage
- Przegląd wielu propozycji draftu (przełączanie strzałkami). Edycja nazw drużyn.
- Widok pojedynczej propozycji przez `MatchWidget` (drag&drop graczy między drużynami, aktualizacja „team score”).
- Akcja „Create Match” tworzy mecz w backendzie i przechodzi do `MatchPage`.

9) MatchPage
- Detal meczu: drużyny, listy graczy, pola wyniku; responsywny układ.
- Dla właściciela (jeśli mecz bez wyniku): tryb edycji składów (drag&drop), ustawienie wyniku, zapis; możliwość usunięcia meczu.
- Dla zakończonych meczów – przegląd bez edycji.

## Kluczowe widżety wielokrotnego użycia
- PlayersListWidget: lista graczy z wyszukiwaniem i sortowaniem; callback wyboru.
- PlayerWidget: prezentacja gracza (compact, score itp.).
- MatchWidget: dwie kolumny drużyn, drag&drop graczy, edycja nazw, prezentacja sumarycznego „team score”.
- Statystyczne widżety (np. `stats_carousel.dart`, `player_stat_*`, `player_h2h_widget.dart`): część używana (karuzela w PlayerDetail), część jeszcze niepodłączona w widokach.

## Zarządzanie stanem (Riverpod)
- `userSessionProvider`: `UserSessionState { user?, token? }`; metody: `setToken`, `setUser`, `logout` (synchronizuje `AuthService`).
- `squadProvider`: `SquadState { squad? }`; metody: `setSquad`, `clearSquad`, oraz `isOwner(userId)` (kontrola dostępu UI).
- `playersProvider`: `PlayersState { players: List<Player> }`; set/add/update/remove/clear.
- `matchesProvider`: `MatchesState { matches: List<Match> }`; set/add/update/remove/clear.
- `draftProvider`: `DraftState { allPlayers, selectedPlayers }`; add/remove/toggle/clear; wylicza `availablePlayers`.

## Wzorzec nawigacji
- Imperatywny, przez `Navigator.push(...)`, `pushReplacement(...)`, `pushAndRemoveUntil(...)`.
- Brak centralnej tablicy tras/nazwanych tras, brak deep-linków i ochrony tras (guardów) na poziomie routera.
- Powroty często realizowane przez „replace” całego stosu do ekranu listy (co upraszcza stan, ale utrudnia spójne wzorce nawigacji na wszystkich ścieżkach).

## Zależności od usług (komunikacja z backendem)
- AuthService: login/guest, przechowywanie tokenu.
- SquadService: listowanie i pobranie szczegółów składu; tworzenie składu.
- PlayerService: listowanie graczy, CRUD (nazwa, score, usunięcie), detal gracza.
- MatchService: generowanie draftów, tworzenie meczu, pobieranie/mechanizmy update/delete meczu, listowanie meczów składu.
- MessageService: snackbar/toasty do komunikatów.

## Motyw i język
- Motyw: domyślnie ciemny (`AppTheme.darkTheme`), z własnymi kolorami (`AppColors`).
- Teksty w UI: mieszanka PL/EN („Wyniki draftu”, „Create Match”, „Login successful!”). Brak i18n.

---

## Zgodność z MVP/PRD – co działa, a czego brakuje

- Konta i autoryzacja (MUST)
  - Jest: logowanie i tryb gościa; token w stanie i w AuthService.
  - Braki: UI dla odświeżania sesji, rejestracja, przepływ zaproszeń do składów, audyt operacji.

- Składy (MUST)
  - Jest: lista, szczegóły, utworzenie (limit 1 na Ownera – brak walidacji UI, zależne od backendu), widoczność Ownera.
  - Braki: widoczność public/private w UI, zarządzanie członkami/rolami, zaproszenia, edycja/usunięcie składu.

- Gracze (MUST)
  - Jest: dodawanie (dialog), edycja nazwy/score, usunięcie, wyszukiwanie/sortowanie; detal z rozbudowanymi statystykami.
  - Braki: walidacja anty-duplikatów nazwy w UI (best effort), mapowanie user↔player (poza MVP – zgodnie z PRD).

- Drafting (MUST)
  - Jest: wybór graczy do draftu, generowanie wielu propozycji, prezentacja i ręczna korekta drużyn przed utworzeniem meczu.
  - Braki: twarda walidacja limitu 16 graczy w UI, prezentacja „balance score”/różnicy sił (obecnie tylko „team score” sumaryczny).

- Mecze (MUST)
  - Jest: tworzenie meczu z draftu, zapis wyniku, edycja składu (przed wynikiem), usunięcie meczu, historia meczów.
  - Braki: UI do „score_meta” (karne, walkover, itp.), zatwierdzanie wyniku przez Ownera (workflow), snapshoty widoczne w UI (zależne od backendu).

- Turnieje (MUST)
  - Braki: brak widoków turniejów (kafelek w `SquadPage` to placeholder).

- Statystyki i wyniki (SHOULD)
  - Jest: podstawowe statystyki składu i gracza, historia score gracza, karuzela statów.
  - Braki: historyczny „score na dzień meczu” w UI, dodatkowe przekroje.

- sportType (SHOULD)
  - Obecnie de facto football; brak przełączania w UI (akceptowalne na MVP).

---

## Luki, ryzyka, dług techniczny (UI)
- Nawigacja bez routera/nazwanych tras; brak guardów tras (RBAC na poziomie UI).
- Brak spójnego i18n (PL/EN wymieszane), brak strategii lokalizacji.
- Niespójność wzorców powrotu (czasem `pushAndRemoveUntil`, czasem zwykły `push`).
- Brak komponentów dla: zaproszeń do składów, ról (Owner/Admin/Member) w UI, widoczności public/private, turniejów, „score_meta”, zatwierdzania wyników.
- UI nie egzekwuje kilku ograniczeń (np. limit 16 graczy w draftcie), opiera się na backendzie.
- Brak centralnej „route map” i dokumentacji przepływów.

---

## Szkic aktualnych przepływów użytkownika (wysoki poziom)
- Gość
  - AuthPage → „Continue as Guest” → SquadListPage → (może przeglądać publiczne składy/mecze jeśli backend na to pozwala) → SquadPage → MatchHistoryPage → MatchPage.
- Zalogowany Owner
  - AuthPage → Login → SquadListPage → Create Squad → SquadPage → PlayersPage (CRUD graczy) → DraftPage (wybór graczy) → CreateMatchPage (wybór propozycji, edycja) → MatchPage (ustawienie wyniku) → MatchHistoryPage.

---

## Dane wejściowe per ekran (główne zależności)
- AuthPage: AuthService
- SquadListPage: SquadService, UserSession (rolka Owner rozpoznawana przez porównanie ownerId vs userId)
- SquadPage: SquadService (detail), zależne stany players/matches
- PlayersPage: PlayerService (list), dialog CreatePlayerWidget
- PlayerDetailPage: PlayerService (detail/update/delete)
- MatchHistoryPage: MatchService (list)
- DraftPage: PlayerService (list), MatchService (drawTeams)
- CreateMatchPage: MatchService (create)
- MatchPage: MatchService (detail/update/delete), PlayerService (list)

---

## Wskazówki do kolejnego etapu (planowanie architektury UI, map podróży i nawigacji)
- Zdefiniować docelową strukturę nawigacji:
  - Tablica tras (named routes) + ochrona tras (RBAC) + strategia powrotów.
  - Ewentualny „root shell” z bottom/tab nav dla głównych sekcji składu (Players/Matches/Tournaments) – do rozważenia.
- Ujednolicić język i wprowadzić i18n (EN/PL) lub jeden język w MVP.
- Zaprojektować brakujące ekrany/workflow: zaproszenia i role w składach, widoczność public/private, turnieje, score_meta, zatwierdzanie wyniku.
- Egzekwować kluczowe ograniczenia w UI (np. draft ≤ 16 graczy) i dodać prezentację „balance score”.
- Przygotować „user journey maps” dla ról: Gość, Member, Admin, Owner – w oparciu o PRD.
- Opracować konsystentne stany pustki, błędów i ładowania.

---

Ten dokument odzwierciedla aktualny stan implementacji UI i ma służyć jako kontekst wejściowy do zaplanowania docelowej architektury interfejsu, map podróży użytkownika i struktury nawigacji.
