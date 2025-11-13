# Architektura UI dla Squads

## 1. Przegląd struktury UI

### Uwaga: nowy frontend vs. stary frontend

- Ten dokument opisuje **docelową architekturę nowego frontendu
  Flutter**, budowanego od zera w oparciu o Clean Architecture (DDD)
  i feature-first organizację.
- Istniejący frontend (opisany w `current_ui_structure.md` oraz w
  plikach `frontend/lib/...` poprzedniego repozytorium) traktujemy
  jako **legacy UI** i inspirację UX.
- Wzmianki typu „Δ względem bieżącego UI” są wyłącznie komentarzem
  porównawczym do legacy i **nie oznaczają**, że nowy kod będzie
  rozwijany na bazie starego.

Squads to aplikacja do tworzenia zbalansowanych drużyn, prowadzenia meczów i prostych turniejów w ramach składów (squads) z kontrolą widoczności i ról. Architektura UI opiera się na:
- GoRouter z nazwanymi trasami, strażnikami (RBAC) oraz „shellami” dla głównych obszarów składu.
- Warstwie stanu (Riverpod) z providerami per zasób i SWR‑podobną rewalidacją.
- Spójnym wzorcu list/detali z paginacją, sortowaniem i stanami ładowania/błędów.
- Globalnym interceptorze HTTP do odświeżania tokenu (access/refresh) i obsługi 401.
- Trzech breakpointach responsywnych (≤600, 600–1024, >1024) oraz podstawowych zasadach a11y.
- Ujednoliconym UI dla braku uprawnień (403) i niewidocznych zasobów (404) w trybie „No access”.

Zakres UI obejmuje: autoryzację (login/guest, rejestracja), listy i detale składów, zarządzanie członkami i widocznością, CRUD graczy, draft i tworzenie meczu, listę/ szczegóły meczów z edycją wyniku i score_meta, szkic turniejów (lista, detal, tworzenie/trasy, tabela – MVP/placeholder tam gdzie wymagane), podstawowe statystyki.

## 2. Lista widoków

1) Nazwa widoku: AuthPage
- Ścieżka widoku: /auth
- Główny cel: Logowanie użytkownika, wejście jako gość, dostęp do rejestracji.
- Kluczowe informacje do wyświetlenia: Formularz (email/hasło), przycisk „Continue as Guest”, link do rejestracji, stany błędów.
- Kluczowe komponenty widoku: AuthForm, GuestButton, SubmitButton, ErrorBanner.
- UX, dostępność i względy bezpieczeństwa: Maskowanie haseł, walidacja pól i błędów 401/422, focus management, brak auto‑fill na wrażliwych polach na web; po sukcesie przekierowanie wg ról. Δ względem bieżącego UI: dodać rejestrację i uporządkować błędy.

2) Nazwa widoku: RegisterPage (opcjonalnie jako część AuthPage)
- Ścieżka widoku: /auth/register
- Główny cel: Założenie konta (email+hasło, opcjonalny username).
- Kluczowe informacje do wyświetlenia: Formularz rejestracji, polityka haseł, informacja o duplikacie email (409).
- Kluczowe komponenty widoku: RegisterForm, PasswordStrengthHint, TermsLink.
- UX, dostępność i względy bezpieczeństwa: Komunikaty 409/422, silna walidacja hasła, link powrotu do logowania.

3) Nazwa widoku: UserPage
- Ścieżka widoku: /me
- Główny cel: Przegląd profilu zalogowanego użytkownika i powiązanych składów.
- Kluczowe informacje do wyświetlenia: Dane usera, listy owned_squads i memberships (połączone), CTA „Przejdź do składów”/„Utwórz skład”.
- Kluczowe komponenty widoku: UserSummaryCard, SquadQuickList, PrimaryCTA.
- UX, dostępność i względy bezpieczeństwa: Tylko dla zalogowanych; stany pustki (brak składu → CTA „Utwórz”), czytelny podział własnych i członkostw.

4) Nazwa widoku: SquadListPage
- Ścieżka widoku: /squads
- Główny cel: Lista dostępnych składów (własne, członkostwa; gość – publiczne).
- Kluczowe informacje do wyświetlenia: Karty składu (nazwa, visibility, players_count, owner tag), paginacja/sort.
- Kluczowe komponenty widoku: SquadCard, PaginationBar, SortMenu, CreateSquadFAB.
- UX, dostępność i względy bezpieczeństwa: Filtry (visibility), wyszukiwanie; ukrycie prywatnych składów dla gości; Δ: dodać visibility/sportType i paginację zgodnie z API.

5) Nazwa widoku: CreateSquadDialog/Page
- Ścieżka widoku: /squads/create (lub modal z SquadListPage)
- Główny cel: Utworzenie składu z nazwą i widocznością.
- Kluczowe informacje do wyświetlenia: Pola name, visibility, sport_type (domyślnie football), ograniczenie 1 skład na Ownera.
- Kluczowe komponenty widoku: SquadForm, VisibilityToggle, SubmitButton.
- UX, dostępność i względy bezpieczeństwa: Komunikat 409 gdy limit Ownera, walidacja 1–100 znaków.

6) Nazwa widoku: SquadShell (kontener)
- Ścieżka widoku: /squads/:squadId
- Główny cel: Wspólny układ i nawigacja kontekstowa dla sekcji składu.
- Kluczowe informacje do wyświetlenia: Nagłówek składu (nazwa, visibility), zakładki/side‑nav: Players, Matches, Members & Settings, Tournaments.
- Kluczowe komponenty widoku: SquadHeader, TabNav/SideNav, ContextActions.
- UX, dostępność i względy bezpieczeństwa: RBAC guard (owner/admin/member/guest), spójne breadcrumb i back; unified „No access” dla 403/404.

7) Nazwa widoku: PlayersPage
- Ścieżka widoku: /squads/:squadId/players
- Główny cel: Przegląd graczy w składzie; CRUD dla uprawnionych.
- Kluczowe informacje do wyświetlenia: Lista graczy z filtrem/sortem, count, pozycja, score, base_score.
- Kluczowe komponenty widoku: PlayersListWidget, SearchBar, SortMenu, CreatePlayerDialog.
- UX, dostępność i względy bezpieczeństwa: Walidacja duplikatów nazw (UI hint, backend 409), role‑based akcje (Add/Edit/Delete tylko admin/owner), responsywne karty/tabela.

8) Nazwa widoku: PlayerDetailPage
- Ścieżka widoku: /squads/:squadId/players/:playerId
- Główny cel: Szczegóły gracza i edycja uprawnień (score, nazwa jeśli dozwolone).
- Kluczowe informacje do wyświetlenia: Statystyki, historia score (opcjonalnie on-demand), podstawowe meta.
- Kluczowe komponenty widoku: StatsCarousel, ScoreHistoryChart, PlayerForm (read‑only/mutowalna część).
- UX, dostępność i względy bezpieczeństwa: Edytowalny score; nazwa zgodnie z decyzją MVP; komunikat kolizji 409; potwierdzenie usunięcia gdy dopuszczalne.

9) Nazwa widoku: DraftPage
- Ścieżka widoku: /squads/:squadId/draft
- Główny cel: Wybór do 16 graczy i żądanie propozycji draftu.
- Kluczowe informacje do wyświetlenia: Wybrani vs dostępni gracze, licznik (max 16), ostrzeżenie >16, wynik zapytania.
- Kluczowe komponenty widoku: DualListSelector, SelectedCounter, DraftButton, DraftWarnings.
- UX, dostępność i względy bezpieczeństwa: Twarde/miękkie limity (UI + 422), komunikaty o jakości; dostęp tylko admin/owner.

10) Nazwa widoku: CreateMatchPage
- Ścieżka widoku: /squads/:squadId/matches/create
- Główny cel: Przegląd i korekta propozycji draftu, nadanie nazw/kolorów, utworzenie meczu.
- Kluczowe informacje do wyświetlenia: Lista propozycji, balans (derived), edytowalne nazwy/kolory, walidacja duplikatów graczy.
- Kluczowe komponenty widoku: MatchWidget (drag&drop), ProposalNavigator, TeamMetaForm, CreateMatchCTA.
- UX, dostępność i względy bezpieczeństwa: Wskazanie konfliktów (ten sam gracz w obu drużynach → 422), dostęp roles: admin/owner.

11) Nazwa widoku: MatchHistoryPage
- Ścieżka widoku: /squads/:squadId/matches
- Główny cel: Lista meczów składu z wynikami i sortowaniem po created_at.
- Kluczowe informacje do wyświetlenia: Karty/wiersze z datą, wynikiem lub statusem (pending), filtr po dacie/typie.
- Kluczowe komponenty widoku: MatchList, Filters, PaginationBar.
- UX, dostępność i względy bezpieczeństwa: Sort domyślnie -created_at; różne widoki dla gościa vs członek; Δ: usunąć score na poziomie teamu – wynik na poziomie meczu.

12) Nazwa widoku: MatchPage
- Ścieżka widoku: /squads/:squadId/matches/:matchId
- Główny cel: Szczegóły meczu, edycja składu (przed wynikiem), zapis wyniku i score_meta.
- Kluczowe informacje do wyświetlenia: Snapshot teamów (home/away), roster, wynik [home, away], result_type, score_meta, played_at, status.
- Kluczowe komponenty widoku: TeamSnapshot, LineupEditor (locked po wyniku), ScoreInput, ScoreMetaForm, SaveButtons.
- UX, dostępność i względy bezpieczeństwa: Lineup lock po ustawieniu wyniku (bez approval flow w MVP), role: admin/owner; spójne 409 dla zablokowanej edycji; Δ: wynik tylko na poziomie meczu.

13) Nazwa widoku: Members & Settings Page
- Ścieżka widoku: /squads/:squadId/settings
- Główny cel: Zarządzanie członkami, rolami i widocznością składu.
- Kluczowe informacje do wyświetlenia: Lista członków z rolami, zaproszenia/stan, formularz zmiany visibility/sport_type.
- Kluczowe komponenty widoku: MembersList, InviteUserDialog, RoleChanger, PrivacyToggle, DangerZone (delete squad).
- UX, dostępność i względy bezpieczeństwa: RBAC (owner/admin zarządzają rolami), akcje potwierdzane (modale), czytelne statusy „invited/pending/member”.

14) Nazwa widoku: TournamentsListPage (MVP: placeholder)
- Ścieżka widoku: /squads/:squadId/tournaments
- Główny cel: Lista turniejów składu.
- Kluczowe informacje do wyświetlenia: Nazwa, status, created_at.
- Kluczowe komponenty widoku: TournamentCard, PaginationBar.
- UX, dostępność i względy bezpieczeństwa: Dostęp read dla członków/public wg visibility; owner/admin tworzą i edytują.

15) Nazwa widoku: TournamentDetailPage (MVP: podstawy)
- Ścieżka widoku: /squads/:squadId/tournaments/:tournamentId
- Główny cel: Podgląd drużyn turnieju, meczów i prostej tabeli.
- Kluczowe informacje do wyświetlenia: Teams, matches, simple table.
- Kluczowe komponenty widoku: TournamentTeams, TournamentMatches, TournamentTable.
- UX, dostępność i względy bezpieczeństwa: RBAC; snapshoty meczów zgodnie z API; edycje tylko dla admin/owner.

16) Nazwa widoku: TournamentCreateFromDraftPage (MVP: szkic)
- Ścieżka widoku: /squads/:squadId/tournaments/draw
- Główny cel: Utworzenie turnieju z draftu lub ręcznie zdefiniowanych drużyn.
- Kluczowe informacje do wyświetlenia: Formularz nazwy, liczby drużyn/rosterów lub import z draftu.
- Kluczowe komponenty widoku: TournamentForm, DraftImport, CreateTournamentCTA.
- UX, dostępność i względy bezpieczeństwa: Walidacje unikalności przypisania gracza w turnieju.

17) Nazwa widoku: NoAccessPage
- Ścieżka widoku: /no-access (lub renderowane inline)
- Główny cel: Ujednolicone komunikaty 403/404 oraz CTA powrotu.
- Kluczowe informacje do wyświetlenia: Powód, sugestie (zaloguj się, poproś o dostęp, przejdź do listy publicznych składów).
- Kluczowe komponenty widoku: Illustration, Message, CTAGroup.
- UX, dostępność i względy bezpieczeństwa: Nie ujawnia szczegółów o istnieniu zasobu; neutralny komunikat.

18) Nazwa widoku: Health/Version Minimal (opcjonalnie UI diagnostyczne)
- Ścieżka widoku: /about (opcjonalnie)
- Główny cel: Informacja o wersji aplikacji.
- Kluczowe informacje do wyświetlenia: version/commit z API.
- Kluczowe komponenty widoku: AboutCard.
- UX, dostępność i względy bezpieczeństwa: Brak danych wrażliwych; pomoc w debug.

## 3. Mapa podróży użytkownika

- Gość (US‑002)
  - Wejście: /auth → Continue as Guest → /squads (lista publicznych) → /squads/:id (NoAccess, jeśli prywatny) → /squads/:id/matches (tylko publiczne) → /squads/:id/matches/:matchId (read‑only).
- Rejestracja i logowanie (US‑001)
  - /auth/register → sukces → /auth (auto‑login) → /me → /squads.
  - /auth (login) → tokeny access+refresh → /me.
- Utworzenie składu (US‑003)
  - /squads → Create → formularz (name, visibility, sport_type) → POST /squads → /squads/:id (shell) → Players.
- Zarządzanie członkami i zaproszeniami (US‑004, US‑019)
  - /squads/:id/settings → lista członków → zaproś/zmień rolę/usuń → akceptacja po stronie zapraszanego (PATCH members).
- CRUD graczy (US‑005)
  - /squads/:id/players → dodaj/edytuj/usuń (role: admin/owner) → walidacja 409 nazwy.
- Draft zbalansowanych drużyn (US‑006)
  - /squads/:id/draft → wybór <=16 → POST /matches/draw → /squads/:id/matches/create (przegląd propozycji) → korekta → POST /matches (utworzenie meczu).
- Utworzenie meczu z draftu (US‑007)
  - Kontynuacja powyżej → redirect do /squads/:id/matches/:matchId.
- Wprowadzenie/edycja wyniku (US‑008, US‑016)
  - /squads/:id/matches/:matchId → wprowadź score [h,a], result_type, score_meta → POST /matches/{id}/score → lineup lock.
- Zatwierdzenie wyniku (US‑009) – jeśli wdrożone
  - Owner: /squads/:id/matches/:matchId → Approve (opcjonalnie) → status approved.
- Przegląd statystyk (US‑010)
  - /squads/:id (shell) + PlayerDetail: wykres trendu, podstawowe metryki; opcjonalnie /squads/:id/stats (agregaty).
- Turnieje (US‑011–US‑014)
  - /squads/:id/tournaments → utwórz z draftu/ręcznie (status draft/active) → dodawanie meczów turniejowych → tabela wyników.
- Bezpieczeństwo i autoryzacja (US‑015, US‑018)
  - Guardy tras i ujednolicone NoAccess; komunikaty o limitach i błędach; brak akcji mutujących dla gościa.
- Web build i dostępność (US‑017)
  - Responsywność i działający główny przepływ (login → draft → mecz → wynik → lista meczów).
- Eksport prostych metryk (US‑020)
  - Opcjonalne linki do raportów/CSV z widoków statystyk lub settings.

## 4. Układ i struktura nawigacji

- Router i strażniki
  - GoRouter z nazwanymi trasami; RouteGuards: isAuthenticated, isOwnerOrAdminOfSquad, isMemberOfSquad, isGuest.
  - Shell: `SquadShell` z nested routes: players, matches, settings, tournaments.
  - Ujednolicone przekierowania 401 → /auth; 403/404 → NoAccessPage.
- Tablica tras (wzorzec)
  - /auth, /auth/register, /me, /squads, /squads/create
  - /squads/:squadId (shell)
    - /squads/:squadId/players
    - /squads/:squadId/players/:playerId
    - /squads/:squadId/draft
    - /squads/:squadId/matches
    - /squads/:squadId/matches/create
    - /squads/:squadId/matches/:matchId
    - /squads/:squadId/settings
    - /squads/:squadId/tournaments
    - /squads/:squadId/tournaments/:tournamentId
    - /squads/:squadId/tournaments/draw
- Nawigacja i powroty
  - Lądowanie: zalogowany → /me, gość → /auth lub publiczne deeplinki do list/spotów.
  - Back stack spójny dzięki named routes; w shellu switch zakładek nie resetuje stanu detali.
- Responsywność i layout
  - ≤600: układ kart i bottom actions; 600–1024: 2‑kolumnowe układy; >1024: 3‑kolumnowe/side‑nav.
  - Fokus i czytelność: widoczne stany aktywne, duże hit‑targets.
- Sieć i bezpieczeństwo
  - Interceptor: 401 → refresh → retry; failure → logout i /auth.
  - Przechowywanie tokenów: secure storage (mobile), localStorage (web); brak tokenu w adresach URL.

## 5. Kluczowe komponenty

- AppScaffold: wspólne AppBar, Drawer/SideNav, SnackbarProvider, ErrorBoundary.
- RouteGuards: strażnicy tras z obsługą 401/403/404 i przekierowań; NoAccessRenderer.
- AuthInterceptor: odświeżanie tokenu, retry, obsługa rate limit/komunikatów.
- DataList: komponent list z paginacją, sortowaniem, filtrami i stanami pustki/błędu.
- PlayersListWidget: lista graczy z wyszukiwaniem i sortem; akcje kontekstowe per rola.
- PlayerForm/Editor: edycja nazwy/score/pozycji (zgodnie z MVP); komunikaty 409.
- MatchWidget: edycja lineupów (drag&drop), prezentacja sumarycznego „team score/balance”.
- ScoreInput & ScoreMetaForm: wejście wyniku [home, away], typ wyniku (regular/penalties/walkover/cancelled) i metadane (np. karne).
- TeamSnapshot: widok drużyny i listy graczy (read‑only po wyniku).
- MembersList & InviteDialog & RoleChanger: zarządzanie członkami, rolami i zaproszeniami.
- PrivacyToggle & SquadForm: edycja nazwy i visibility; sport_type read‑only w MVP.
- Tournament* (Card, Teams, Matches, Table): podstawowe komponenty listy/detalu turniejów.
- Error/Empty Views: spójne ekrany błędów (NoAccess, NotFound, NetworkError) i pustki z CTA.


