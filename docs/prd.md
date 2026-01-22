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
- Tworzenie dostępne tylko dla zalogowanych (guest nie może tworzyć składu).
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
- RBAC: tylko zalogowany użytkownik może tworzyć skład (guest nie może).

US-003
Tytuł: Wyświetlanie listy składów
Opis: Jako użytkownik aplikacji chcę móc przeglądać listę składów, aby wybrać skład do dołączenia/ przeglądania.
Kryteria akceptacji:
- Widok listy składów z nazwami, widocznością, liczbą graczy i właścicielem.
- Możliwość filtrowania po widoczności i wyszukiwania po nazwie.
- RBAC: visibility określa dostęp do składu. public - read dla wszystkich, private - read dla członków składu.
- Możliwość dołączenia do składu poprzez zaproszenie. (dodanie statusu pending do tabeli users_squads)
- Możliwość przeglądania składu poprzez kliknięcie na skład. (jeżeli użytkownik ma dostęp do składu)

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
Tytuł: Lista meczy
Opis: Jako użytkownik chcę móc przeglądać listę meczy w składzie.
Kryteria akceptacji:
- po kliknięciu na przycisk "Matches" przechodzimy do widoku listy matches
- widok jest pod adresem /squads/:squadId/matches

US-007
Tytuł utwórz mecz
Opis: Jako Admin gdy kliknę na plus w widoku listy meczy chcę przejść do widoku z draftem.
Kryteria akceptacji:
- po kliknięciu na plus przechodzimy do widoku z draftem
- widok jest pod adresem /squads/:squadId/matches/draft
- podgląd propozycji draftu jest pod adresem /squads/:squadId/matches/create
- przycisk plus jest widoczny tylko dla adminó i ownerów.

US-008
Tytuł: Szczegóły meczu
Opis: Jako użytkownik chcę móc przeglądać szczegóły meczu.
Kryteria akceptacji:
- po kliknięciu na mecz przechodzimy do widoku szczegółów meczu
- widok jest pod adresem /squads/:squadId/matches/:matchId
- widok zawiera  datę, wynik, składy drużyn, oraz nawigację .

US-009
Tytuł: Szybka nawigacja do gracza
Jako użytkownik chcę móc szybko przejść do szczegółów gracza.
Kryteria akceptacji:
- po kliknięciu na gracza przechodzimy do widoku szczegółów gracza
- widok jest pod adresem /squads/:squadId/players/:playerId
- widok na razie zmockowany



US-010
Tytuł: Draft zbalansowanych drużyn
Opis: Jako Admin chcę otrzymać deterministyczne propozycje podziału graczy na drużyny.
Kryteria akceptacji:
- Mogę swobodnie dodawać i usuwać graczy do draftu.
- Z wybranej puli graczy losowanych jest do 20 propozycji meczy (zestawów team A i team B).
- Propozycje są posortowane od najlepszej do najgorszej.
- Propozycje są deterministyczne, można je odtworzyć.

US-011
Tytuł: Utworzenie meczu z draftu
Opis: Jako Admin chcę utworzyć mecz na podstawie wybranej propozycji draftu.
Kryteria akceptacji:
- Wybór propozycji tworzy mecz z przypisanymi drużynami.


US-012
Tytuł: Wprowadzenie wyniku meczu
Opis: Jako Admin chcę wprowadzić wynik, aby zaktualizować rankingi graczy.
Kryteria akceptacji:
- Zapis home_score i away_score + score_meta.
- Po zapisie generowana jest delta wpływająca na ranking graczy, którzy zagrali. //to do przy ranking history
- Edycja wyniku aktualizuje właściwą deltę i statystyki. //to do przy ranking history
- Po wpisaniu wyniku nie można edytować składów; wynik można zmienić tylko jeśli nie istnieje nowszy mecz z już wpisanym wynikiem.

US-013
Tytuł: Edycja detali meczu
Opis: Jako Admin chcę edytować nazwę i kolor drużyny oraz składy drużyn.
Kryteria akceptacji:
- Edycja nazwy i koloru drużyny robi udpate do bazy.
- jeśli wynik nie jest wpisany to możemy edytować składy drużyn: można dodawać, usuwać graczy i zamieniać między drużynami. 

US-014
Tytuł: Rematch
Opis: Jako Admin chcę móc utworzyć rematch meczu.
Kryteria akcjeptacji:
- będąc w detalach meczu możemy utworzyć rematch poprzez kliknięcie na przycisk "Rematch".
- tworzy to nowy mecz z tymi samymi drużynami, ale zamienionymi stronami (home ↔ away).

US-015
Tytuł: Redraw
Jako Admin chcę móc przeprowadzić redraw meczu.
Kryteria akceptacji:
- jeśli do meczu dodano / zabrano gracza pojawia się przycisk "Redraw".
- kliknięcie tego przycisku przenosi nas do draftu z nową listą zawodników
- aktualny mecz jest aktualizowany nowymi drużynami (bez usuwania).

US-016
Tytuł: Przegląd statystyk składu i graczy
Opis: Jako Member chcę zobaczyć podstawowe statystyki i trend rankingu.
Kryteria akceptacji:
- Widok liczby meczów, W/L, trendu rankingu.
- Historyczny score widoczny „na dzień meczu”.

US-017
Tytuł: Stworzenie turnieju
Opis: Jako Owner chcę utworzyć turniej, wybierając graczy i liczbę drużyn, a następnie zaakceptować zestaw drużyn.
Kryteria akceptacji:
- Przepływ: wybór graczy → liczba drużyn → draft zestawów → akceptacja.
- Możliwość edycji nazw i kolorów drużyn.

US-018
Tytuł: Dodawanie meczów w turnieju
Opis: Jako Admin chcę dodawać kolejne mecze do turnieju.
Kryteria akceptacji:
- Dodanie meczu między dowolnymi drużynami turnieju.
- Wynik wpływa na rankingi tylko grających w tym meczu.

US-019
Tytuł: Edycja składu drużyn w turnieju
Opis: Jako Admin chcę dokonywać zamian zawodników między drużynami w trakcie turnieju.
Kryteria akceptacji:
- Zmiana składu obowiązuje od kolejnych meczów; historia pozostaje spójna dzięki snapshotom.

US-020
Tytuł: Widok turnieju i klasyfikacja (prosta tabela)
Opis: Jako Member chcę zobaczyć listę meczów turnieju i prostą klasyfikację.
Kryteria akceptacji:
- Lista meczów z wynikami; opcjonalnie prosta tabela W/L, różnica goli.
- Zasady tie‑break (H2H, różnica, gole) mogą być uproszczone lub pominięte w MVP.

US-021
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

US-020
Tytuł: Widok home page po zalogowaniu
Opis: Jako użytkownik, gdy zaloguję sie do aplikację chcę zobaczyć listę swoich składów aby móc szybko przeglądać je i zarządzać nimi.
Kryteria akceptacji:
- zalogowany użytkownik widzi listę swoich składów wraz z nazwą, widocznościąi liczbą przypisanych graczy.
- użytkownik widzi róznice pomiędzy składami do których dopiero aplikował, w których jest adminem/ownerem i w których jest członkiem.
- użytkownik może szybko przejść do szczegółów składu poprzez kliknięcie na skład.

US-021
Tytuł: Dodanie składu dla użytkownika 
Opis: Jako zalogowany użytkownik chce móc dodać skład do swojego konta.
Kryteria akceptacji:
- użytkownik będąc w widoku home page może szybko przejść do listy składów   poprzez kliknięcie na przycisk "Dodaj skład".

US-022
Tytuł: Powiadomienia o zaproszeniach do składów
Opis: Jako użytkownik chce móc otrzymać powiadomienie o zaproszeniu do składu.
Kryteria akceptacji:
- w ekranie home page użytkownik ma widoczną ikonę dzwoneczka z liczbą powiadomień.
- użytkownik może szybko przejść do listy powiadomień poprzez kliknięcie na ikonę dzwoneczka.
- w liście powiadomień użytkownik widzi nazwę składu, nazwę właściciela, datę zaproszenia i status zaproszenia.
- użytkownik może zaakceptować lub odrzucić zaproszenie do składu poprzez kliknięcie na powiadomienie.
- zaakceptowanie zaproszenia do składu dodaje użytkownika do składu i zmienia jego status na członek.
- taki skład pojawia się w liście składów użytkownika wraz z nazwą, widocznością i liczbą graczy.



US-023
Tytuł: Widok detali składu
Opis: Jako użytkownik chcę po kliknięciu w skład do którego mam dostęp chce zoabzcyć stronę z detalami składu.
Kryteria akceptacji:
- mogę otworzyć sklad którego jestem : role admin/owner/member.
- widok składu zawiera nazwę składu, widoczność, liczbę graczy, oraz nawigację do listy graczy, listy meczów, listy turniejów oraz statystyk.

US-024
Tytuł: Nawigacja w składzie
Opis: Jako użytkownik, będąc w squad  chcę mieć łatwą nawigację do listy graczy, listy meczów, listy turniejów oraz statystyk.
Kryteria akceptacji:
- użytkownik ma widoczne duże panele odnoszące siędo subpage.
- na apkach mobilnych jest dodatkowo nawigacja dolna do nawigacji pomiędzy subpage (Home,Players, Matches)
w przeglądarce jest rozwijany sidebar do nawigacji pomiędzy subpage (Home,Players, Matches, Tournaments, Settings)

US-025
Tytuł: Menu szybkich akcji
Jako owner/admin chcę mieć możliwość szybkiego dodania gracza, meczu lub turnieju.
Kryteria akceptacji:
- mając odpowiednią role widzę plusa floating button, po najechaniu na niego pokazuje mi się dodatkowe opcje dodania gracza, meczu lub turnieju.

US-026
Tytuł: Ustawienia składu
Opis: Jako owner chcę mieć możliwość edycji ustawień składu.
Kryteria akceptacji:
- na root shellu widze ikonkę koła zębatego w przyszłości prowadzącej do ustawień składu.

US-027
Tytuł: Lista powiadomień o zaproszeniach do składu
Opis: Jako owner w squad details page chce wyświetlić ikonę powiadomień o ilości oczekujących zaproszeń do składu.
Kryteria akceptacji:
- na ikonce zębatki wyświetlamy liczbę oczekujacych akceptacji zaproszeń do składu.
- po kliknięciu na ikonę przechodzimy do /settings(todo)

US-028
Tytuł: Ustawienia składu
Opis: Jako owner chcę mieć możliwość edycji ustawień składu.
Kryteria akceptacji:
- po kliknięciu ikony zębatki w squad details page przechodzimy do /squads/:squadId/settings
- widok zawiera wszystkie elementy dokładnie opisane w dokumentacji UI


## 6. Metryki sukcesu
- KPI 1: Co najmniej 50% graczy to zalogowani użytkownicy (w MVP liczony jako stosunek liczby rekordów users do players; znane ograniczenie bez mapowania user↔player).
- KPI 2: Co piąty użytkownik tworzy skład (users vs squads).
- Operacyjne (opcjonalne): liczba meczów/tydzień na skład; średni czas do pierwszego meczu po założeniu składu.
