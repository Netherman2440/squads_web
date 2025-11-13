# Dokument wymagań produktu (PRD) - Squads
## 1. Przegląd produktu
Squads to aplikacja umożliwiająca szybkie tworzenie zbalansowanych drużyn do amatorskich rozgrywek sportowych oraz prowadzenie meczów i prostych turniejów. System generuje deterministyczne, posortowane propozycje podziału graczy na drużyny na podstawie ich rankingów, a następnie aktualizuje rankingi po każdym meczu wykorzystując podejście event‑sourcing (delty). MVP obejmuje konta użytkowników z rolami i zaproszeniami do prywatnych składów, zarządzanie składami i graczami, rejestr wyników meczów, draft z limitem 16 graczy, podstawowe statystyki oraz obsługę turniejów. W kontekście frontendu przyjmujemy, że docelowa aplikacja webowa jest budowana **od zera** (greenfield) w Flutterze z użyciem Clean Architecture i feature-first struktury; istniejący Flutter frontend traktowany jest jako **legacy UI** i służy jedynie jako inspiracja UX (przepływy, layout, copy).

## 2. Problem użytkownika
W amatorskich meczach wybór składów bywa chaotyczny i konfliktogenny. Ręczny dobór graczy jest czasochłonny, często postrzegany jako niesprawiedliwy, a wyniki nie są systematycznie zapisywane, przez co trudno poprawiać sprawiedliwość w przyszłości. Squads rozwiązuje ten problem przez:
- deterministyczny draft wielu propozycji wyrównanych drużyn,
- rejestrowanie wyników i automatyczną aktualizację rankingów,
- prosty mechanizm ról i widoczności składów, aby bezpiecznie współdzielić dane w zespole.

## 3. Wymagania funkcjonalne
3.1 Konta i autoryzacja (MUST)
- Rejestracja i logowanie (również tryb gościa do przeglądania publicznych składów).
- Role w składach: Owner, Admin, Member; zaproszenia do składów prywatnych.
- Tokeny dostępu i odświeżania; sesje wyłącznie online; RBAC na endpointach API.
- Audyt operacji wrażliwych (tworzenie składu, zaproszenia, edycja wyniku).

3.2 Składy (Squads) (MUST)
- Tworzenie, edycja, usuwanie; limit 1 skład na Ownera.
- Widoczność: public (read dla wszystkich), private (dostęp tylko dla członków składu).
- Zarządzanie członkami i rolami; zaproszenia do składów prywatnych.
- Limit do 100 graczy w jednym składzie.

3.3 Gracze (Players) (MUST)
- CRUD graczy; brak mapowania user↔player w MVP.
- Ranking per‑skład; wizualizacja trendu i podstawowych statystyk.

3.4 Drafting (MUST)
- Deterministyczne generowanie wielu propozycji (docelowo 20) posortowanych od najlepszej do najgorszej.
- Limit 16 graczy w wejściu do draftu; powyżej limitu komunikat o niższej jakości/odmowa.
- Prezentacja „balance score”/różnicy siły drużyn w UI

3.5 Mecze (Matches) (MUST)
- Tworzenie meczu z wybranego draftu lub w ramach turnieju.
- Zapis wyniku: home_score, away_score + score_meta (np. karne, walkover, cancelled, sety).
- Aktualizacja rankingów poprzez delty; korekta wyniku aktualizuje odpowiednią deltę.

3.6 Turnieje (Tournaments) (MUST)
- Przepływ: wybór graczy → liczba drużyn → draft kilku zestawów → akceptacja → widok turnieju (historia meczów).
- Dodawanie kolejnych meczów, edycja drużyn (zamiany zawodników, nazwa, kolor) w trakcie turnieju.
- Wyniki turniejowe wpływają tylko na grających zawodników w danym meczu.

3.7 Statystyki i wyniki (SHOULD)
- Podstawowe statystyki składów i graczy: liczba meczów, bilans W/L, średnie oceny, trend.
- Wykres historii zmian rankingu (na bazie delt); widok historycznego score „na dzień meczu”.

3.8 sportType (SHOULD)
- W MVP tylko football; przygotowanie modelu do rozszerzeń w przyszłości.

3.9 Analityka i anty‑duplikacja (NICE TO HAVE)
- Prosta analityka operacyjna (eksport/raporty) bez dedykowanych narzędzi.
- Podpowiedzi podobnych imion przy tworzeniu gracza; import graczy (CSV/Excel).

## 4. Granice produktu
4.1 Poza zakresem MVP
- Płatne subskrypcje i ograniczenia dostępu.
- Zaawansowane reguły draftu (custom parowanie graczy).
- Offline: brak logowania i CRUD bez sieci.
- Mapowanie user↔player (przeniesione po‑MVP; rozważany „claim player”).
- Pełna analityka i anty‑duplikacja (po‑MVP).

4.2 Ograniczenia i założenia
- Limit 1 skład na Ownera; do 100 graczy na skład.
- Draft: deterministyczny, do 20 propozycji; twardy limit 16 graczy wejścia.
- Wynik meczu: home_score/away_score + score_meta; wpływ score_meta na ranking dookreślany.
- Widoczność: public read dla wszystkich, private tylko dla członków.
- Ranking per‑skład, liczenie z delt.
- Brak SEO/public index: polityka linków dla publicznych składów do ustalenia.

## 5. Historyjki użytkowników
US-001
Tytuł: Rejestracja i logowanie użytkownika
Opis: Jako nowy użytkownik chcę się zarejestrować i zalogować, aby korzystać z funkcji prywatnych składów i zarządzania.
Kryteria akceptacji:
- Możliwość rejestracji konta email+hasło oraz logowania.
- Wydawanie tokenów access i refresh; odświeżenie sesji działa.
- Błąd i komunikat przy nieprawidłowych danych.
- Dostęp do zasobów prywatnych możliwy wyłącznie po zalogowaniu.

US-002
Tytuł: Tryb gościa (podgląd publicznych składów)
Opis: Jako gość chcę przeglądać publiczne składy i historię meczów, aby poznać aplikację bez konta.
Kryteria akceptacji:
- Wejście bez logowania umożliwia listowanie/przegląd publicznych składów.
- Dostęp do prywatnych składów blokowany komunikatem o braku uprawnień.

US-003
Tytuł: Utworzenie składu
Opis: Jako Owner chcę utworzyć skład z nazwą, widocznością i limitem graczy, aby zarządzać rozgrywkami.
Kryteria akceptacji:
- Utworzenie składu z polami: nazwa, visibility (public/private).
- Weryfikacja limitu: 1 skład na Ownera; do 100 graczy w składzie.
- RBAC: tylko zalogowany Owner może tworzyć skład.

US-004
Tytuł: Zarządzanie członkami i zaproszeniami
Opis: Jako Owner/Admin chcę zapraszać użytkowników do prywatnego składu i nadawać role.
Kryteria akceptacji:
- Wysłanie zaproszenia i jego akceptacja/odrzucenie.
- Nadanie roli: Admin/Member; odebranie roli.
- Dostęp do prywatnego składu po akceptacji.

US-005
Tytuł: CRUD graczy w składzie
Opis: Jako Admin chcę dodawać, edytować i usuwać graczy w składzie.
Kryteria akceptacji:
- Dodanie/edycja/usunięcie gracza ograniczone do Admin/Owner.
- Walidacja duplikatów nazwy w obrębie składu (best effort).

US-006
Tytuł: Draft zbalansowanych drużyn
Opis: Jako Admin chcę otrzymać deterministyczne propozycje podziału graczy na drużyny z oceną balansu.
Kryteria akceptacji:
- Dla do 16 graczy generowanych jest do 20 propozycji, posortowanych od najlepszej.
- Prezentowany balance score/różnica sił; komunikat o limicie >16.
- Metadane draftu pozwalają odtworzyć wyniki (seed/timestamp/lista graczy).

US-007
Tytuł: Utworzenie meczu z draftu
Opis: Jako Admin chcę utworzyć mecz na podstawie wybranej propozycji draftu.
Kryteria akceptacji:
- Wybór propozycji tworzy mecz z przypisanymi drużynami.
- Snapshot uczestników zapisany przy meczu.

US-008
Tytuł: Wprowadzenie wyniku meczu
Opis: Jako Admin chcę wprowadzić wynik, aby zaktualizować rankingi graczy.
Kryteria akceptacji:
- Zapis home_score i away_score + score_meta.
- Po zapisie generowana jest delta wpływająca na ranking graczy, którzy zagrali.
- Edycja wyniku aktualizuje właściwą deltę i statystyki.

US-009
Tytuł: Przegląd statystyk składu i graczy
Opis: Jako Member chcę zobaczyć podstawowe statystyki i trend rankingu.
Kryteria akceptacji:
- Widok liczby meczów, W/L, trendu rankingu.
- Historyczny score widoczny „na dzień meczu”.

US-010
Tytuł: Stworzenie turnieju
Opis: Jako Owner chcę utworzyć turniej, wybierając graczy i liczbę drużyn, a następnie zaakceptować zestaw drużyn.
Kryteria akceptacji:
- Przepływ: wybór graczy → liczba drużyn → draft zestawów → akceptacja.
- Możliwość edycji nazw i kolorów drużyn.

US-011
Tytuł: Dodawanie meczów w turnieju
Opis: Jako Admin chcę dodawać kolejne mecze do turnieju.
Kryteria akceptacji:
- Dodanie meczu między dowolnymi drużynami turnieju.
- Wynik wpływa na rankingi tylko grających w tym meczu.

US-012
Tytuł: Edycja składu drużyn w turnieju
Opis: Jako Admin chcę dokonywać zamian zawodników między drużynami w trakcie turnieju.
Kryteria akceptacji:
- Zmiana składu obowiązuje od kolejnych meczów; historia pozostaje spójna dzięki snapshotom.

US-013
Tytuł: Widok turnieju i klasyfikacja (prosta tabela)
Opis: Jako Member chcę zobaczyć listę meczów turnieju i prostą klasyfikację.
Kryteria akceptacji:
- Lista meczów z wynikami; opcjonalnie prosta tabela W/L, różnica goli.
- Zasady tie‑break (H2H, różnica, gole) mogą być uproszczone lub pominięte w MVP.

US-014
Tytuł: Bezpieczny dostęp i autoryzacja
Opis: Jako system chcę egzekwować RBAC i widoczność zasobów, aby chronić dane użytkowników.
Kryteria akceptacji:
- Endpointy wymagają odpowiednich ról (Owner/Admin/Member) zgodnie z operacją.
- Publiczne składy dostępne dla wszystkich w trybie read; prywatne wyłącznie dla członków.
- Audyt zapisywany dla operacji wrażliwych.

US-015
Tytuł: Edycja wyniku i obsługa score_meta
Opis: Jako Admin/Owner chcę poprawić wynik i zaktualizować score_meta (np. karne, walkover).
Kryteria akceptacji:
- Edycja wyniku aktualizuje deltę i statystyki.
- Zasady wpływu score_meta na ranking są spójne i udokumentowane.

US-016
Tytuł: Web build i dostępność
Opis: Jako użytkownik chcę korzystać z wersji web aplikacji.
Kryteria akceptacji:
- Build web dostępny; podstawowe działanie kluczowych przepływów (logowanie, draft, mecz, turniej).

US-017
Tytuł: Ograniczenia anty‑spam
Opis: Jako system chcę ograniczyć nadużycia poprzez limity.
Kryteria akceptacji:
- Limit 1 skład na Ownera egzekwowany.
- Komunikaty błędu przy przekroczeniu limitów.

US-018
Tytuł: Widoczność prywatnych składów
Opis: Jako Member chcę uzyskać dostęp do prywatnego składu po zaproszeniu.
Kryteria akceptacji:
- Po akceptacji zaproszenia widzę skład i jego historię.
- Goście nie mają dostępu do prywatnych składów.

US-019
Tytuł: Eksport prostych metryk operacyjnych
Opis: Jako Owner chcę móc uzyskać podstawowe metryki (np. liczba meczów/tydzień).
Kryteria akceptacji:
- Możliwy prosty eksport/raport przez zapytania bez dedykowanej analityki.

## 6. Metryki sukcesu
- KPI 1: Co najmniej 50% graczy to zalogowani użytkownicy (w MVP liczony jako stosunek liczby rekordów users do players; znane ograniczenie bez mapowania user↔player).
- KPI 2: Co piąty użytkownik tworzy skład (users vs squads).
- Operacyjne (opcjonalne): liczba meczów/tydzień na skład; średni czas do pierwszego meczu po założeniu składu.
