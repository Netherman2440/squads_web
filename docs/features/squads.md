# squads - dokumentacja feature (stan aktualny)
Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `squads` odpowiada za:
- liste skladow i wejscie do konkretnego skladu,
- tworzenie skladu przez zalogowanego uzytkownika,
- zarzadzanie relacja user-squad (owner/admin/member/pending itd.),
- dolaczanie do skladu przez zaproszenie i przez request do skladu prywatnego,
- widok szczegolow skladu (`SquadShell` + `SquadHome`),
- ustawienia skladu (owner-only),
- ustawienia rankingu skladu (owner-only),
- statystyki skladu.

Zakres obejmuje warstwy `domain`, `application`, `infrastructure` i `presentation` w `app/lib/features/squads` oraz powiazane migracje Supabase.

## 2. Co jest zaimplementowane

### 2.1 Lista skladow i akcje na liscie
Ekran: `SquadsPage` (`/squads`)
- automatyczne ladowanie listy (`loadSquads`) po otwarciu widoku,
- wyszukiwanie po nazwie (`searchQuery`) i reczne odswiezanie,
- tworzenie skladu (`Create squad`) z wyborem `public/private`,
- flow wejscia zalezne od roli:
  - `owner/admin/member` -> przejscie do `SquadShell`,
  - `pending` -> komunikat "Request already sent",
  - `none + private` -> dialog "Apply to Squad" + RPC `request_squad_access`,
  - `none + public` -> wejscie do `SquadShell`,
  - `declined/removed` -> komunikat o braku dostepu.

### 2.2 Squad shell i home
Ekrany: `SquadShellPage`, `SquadHomePage` (`/squads/:squadId`)
- pobieranie skladu przez `squadDetailProvider` (`GetSquadUseCase`),
- rozroznienie bledow `not found` vs `unauthorized` vs inne,
- header z nazwa i widocznoscia skladu,
- ikona ustawien tylko dla ownera; przy pending requestach pokazuje marker `!`,
- kafelki nawigacyjne:
  - `Players` -> `/squads/:squadId/players`,
  - `Matches` -> `/squads/:squadId/matches`,
  - `Stats` -> `/squads/:squadId/stats`,
  - `Tournaments` -> placeholder "coming soon".
- quick actions FAB dla `owner/admin`:
  - dodanie zawodnika (dialog z feature `players`),
  - dodanie meczu (`/squads/:squadId/matches/create`),
  - dodanie turnieju (placeholder).

### 2.3 Ustawienia skladu (owner-only)
Ekran: `SquadSettingsPage` (`/squads/:squadId/settings`)
- dostep tylko dla `owner` (dla innych roli ekran "No access"),
- sekcja members:
  - ladowanie przez `GetSquadSettingsMembersUseCase`,
  - sortowanie: `pending` -> `owner` -> `admin` -> `member`,
  - akcje: accept/decline request, promote/demote, remove.
- sekcja invite link:
  - odczyt aktywnego linku,
  - generowanie/regeneracja linku,
  - kopiowanie URL do schowka.
- `Danger Zone`:
  - zmiana widocznosci,
  - zmiana nazwy,
  - przejscie do ustawien rankingu,
  - transfer ownership: placeholder (`TODO` snackbar),
  - usuniecie skladu z potwierdzeniem.

### 2.4 Ustawienia rankingu skladu (owner-only)
Ekran: `SquadRankingSettingsPage` (`/squads/:squadId/settings/ranking`)
- dostep tylko dla ownera,
- zmiana:
  - `ranking_update` (wlacz/wylacz aktualizacje rankingu po meczu),
  - `use_experience_factor`,
  - `ranking_multiplier` (slider 1..10),
- zapis przez `UpdateSquadRankingSettingsUseCase`,
- podglad "test match preview" pokazujacy przyblizona zmiane rankingu.

### 2.5 Linki zaproszeniowe i dolaczanie
Ekran: `InvitePage` (`/invite?code=...`)
- kod zaproszenia jest zapisywany tymczasowo przez `InviteCodeStorage`,
- dla niezalogowanego uzytkownika: przekierowanie na `/auth`,
- po zalogowaniu: `JoinSquadFromInviteUseCase` -> RPC `join_squad_by_invite`,
- po sukcesie: przekierowanie na `/squads/:squadId`,
- przy bledzie: czyszczenie storage + komunikat.

Dodatkowo `AuthPage` po udanym logowaniu probuje wykonac pending join z invite code i przekierowac do odpowiedniego skladu.

### 2.6 Statystyki skladu
Ekran: `SquadStatsPage` (`/squads/:squadId/stats`)
- pobieranie przez `GetSquadStatsUseCase`,
- backend RPC `get_squad_stats`,
- szczegoly metryk i kontraktu stats sa utrzymywane w [stats.md](./stats.md).

## 3. Routing
Definicje tras sa w `app/lib/core/app_router.dart`:
- `/squads` -> `SquadsPage`
- `/squads/:squadId` -> `SquadShellPage`
- `/squads/:squadId/settings` -> `SquadSettingsPage`
- `/squads/:squadId/settings/ranking` -> `SquadRankingSettingsPage`
- `/squads/:squadId/stats` -> `SquadStatsPage`
- `/invite?code=...` -> `InvitePage`

Najwazniejsze wejscia do feature:
- `RootShell` (sidebar): link `Squads` i podsekcja biezacego skladu (Home/Players/Matches/Stats),
- `UserPage` (`/me`): przycisk "Add squad"/"Add more" prowadzi do `/squads`,
- `AuthPage` i `InvitePage`: wejscie/continuation flow zaproszeniowego.

## 4. DB i RLS (zbiorczo)

### 4.1 Tabele i kluczowe pola
- `public.squads`:
  - `squad_id` (PK), `owner_id`, `name`, `visibility`, `sport_type`,
  - `ranking_update`, `ranking_multiplier`, `use_experience_factor`, `created_at`.
- `public.user_squads`:
  - PK `(user_id, squad_id)`,
  - `role` (`user_squad_role`), `created_at`.
- `public.invite_links`:
  - `code` (PK),
  - `squad_id` (UNIQUE, FK -> `squads`),
  - `valid_until`, `created_by`, `created_at`.

### 4.2 Constraints / indeksy istotne dla feature
- `squads_ranking_multiplier_1_10` (`ranking_multiplier between 1 and 10`),
- indeks `squads_owner_idx`,
- indeksy `user_squads_user_idx`, `user_squads_squad_idx`,
- `invite_links_squad_unique` (jeden aktywny rekord invite na squad).

### 4.3 RPC / funkcje SQL uzywane przez feature
- `request_squad_access(target_squad_id uuid)`:
  - tworzy/aktualizuje wpis `user_squads` na role `pending`,
  - dopuszcza ponowne zgloszenie dla `declined/removed/pending`.
- `join_squad_by_invite(invite_code text)`:
  - waliduje kod i TTL,
  - dodaje usera do `user_squads` jako `member` (idempotentnie),
  - zwraca `squad_id`.
- `get_squad_stats(p_squad_id uuid)`:
  - endpoint statystyk skladu; szczegoly kontraktu sa utrzymywane w [stats.md](./stats.md).

### 4.4 Polityki RLS (kto czyta, kto modyfikuje)
- `squads`:
  - `select`: obecnie "Anyone can read squads" (publiczny listing),
  - `insert/update/delete`: tylko owner (`owner_id = auth.uid()`).
- `user_squads`:
  - `select`: user czyta swoje membershipy lub owner czyta membershipy swojego skladu,
  - `insert/update/delete`: owner skladu (plus specjalny przypadek owner membership insert).
- `invite_links`:
  - `select/insert/update/delete`: tylko owner skladu.

Dodatkowy kontekst pod `get_squad_stats`:
- funkcja czyta `players` i `matches`; te tabele maja `select` dla publicznych skladow lub czlonkow skladu.

## 5. Architektura

### 5.1 Domain
- encje:
  - `squad.dart`,
  - `membership.dart`,
  - `user_squad_role.dart`,
  - `squad_member.dart`,
  - `invite_link.dart`.
- repozytoria:
  - `squad_repository.dart`,
  - `membership_repository.dart`,
  - `invite_links_repository.dart`,
  - `invite_code_storage.dart`.

### 5.2 Application
Glowne use case:
- lista i detale:
  - `get_squads_use_case.dart`,
  - `get_squad_use_case.dart`.
- tworzenie/dostep:
  - `create_squad_use_case.dart`,
  - `apply_to_squad_use_case.dart`,
  - `accept_invite_use_case.dart`,
  - `join_squad_from_invite_use_case.dart`.
- settings:
  - `get_squad_settings_members_use_case.dart`,
  - `modify_member_role_use_case.dart`,
  - `remove_member_use_case.dart`,
  - `change_squad_name_use_case.dart`,
  - `change_squad_visibility_use_case.dart`,
  - `delete_squad_use_case.dart`,
  - `update_squad_ranking_settings_use_case.dart`.
- invite links:
  - `generate_invite_link_use_case.dart`,
  - `get_squad_invite_link_use_case.dart`.
- stats:
  - implementacja ekranu i use case stats dla squadu jest opisana centralnie w [stats.md](./stats.md).

### 5.3 Infrastructure
- `SupabaseSquadRepository`:
  - CRUD `squads`,
  - czlonkostwo ownera przy tworzeniu skladu (`user_squads` upsert),
  - RPC: `request_squad_access`, `join_squad_by_invite`, `get_squad_stats`,
  - odczyt members (`user_squads`).
- `SupabaseMembershipRepository`:
  - odczyt membershipow usera i skladu,
  - update roli, delete membership.
- `SupabaseInviteLinksRepository`:
  - owner-only read/upsert `invite_links`.
- `InviteCodeStorage`:
  - web: `SharedPreferences` + TTL,
  - stub: in-memory storage.

### 5.4 Presentation
- state/providers:
  - `squads_notifier.dart`,
  - `squad_detail_notifier.dart`,
  - `squad_settings_notifier.dart`,
  - `squad_invite_link_provider.dart`.
- pages:
  - `squads_page.dart`,
  - `squad_shell_page.dart`,
  - `squad_home_page.dart`,
  - `squad_settings_page.dart`,
  - `squad_ranking_settings_page.dart`,
  - `invite_page.dart`.
- widgets:
  - `squad_list_item.dart`,
  - `member_tile.dart`,
  - `danger_zone_section.dart`.
- stats UI (`squad_stats_page.dart`, `squad_stats_provider.dart`, `stat_tile.dart`) opisujemy w [stats.md](./stats.md).

## 6. Integracje / punkty styku
- `auth`:
  - `AuthPage` finalizuje pending join z invite code po logowaniu,
  - `InvitePage` przekierowuje niezalogowanego usera na `/auth`.
- `users`:
  - `GetCurrentUserUseCase` laczy `MembershipRepository` + `SquadRepository.getSquadsByIds`,
  - `UserPage` pokazuje "My squads" przez `squadsNotifierProvider`.
  - Profil usera i agregacja "My squads" sa opisane po stronie [users.md](./users.md).
- `players`:
  - `PlayersPage` i `PlayerDetailsPage` uzywaja `squadDetailProvider` do kontroli uprawnien owner/admin.
- `matches`:
  - `SquadMatchesPage` i `MatchDetailsPage` uzywaja `squadDetailProvider` do kontroli akcji administracyjnych,
  - `UpdateMatchScoreUseCase` pobiera ustawienia rankingu skladu przez `GetSquadUseCase`.
- `stats`:
  - `SquadStatsPage` zyje w module `squads`, ale definicje metryk stats sa utrzymywane centralnie w [stats.md](./stats.md).
- `core`:
  - `RootShell` uzywa `squadDetailProvider` do nazwy skladu i menu sekcji squad.

## 7. Szybka mapa plikow
- glowny katalog feature: `app/lib/features/squads/`
- router:
  - `app/lib/core/app_router.dart`
  - `app/lib/core/root_shell.dart`
- najwazniejsze migracje:
  - `supabase/migrations/20251201080000_create_extensions_and_types.sql`
  - `supabase/migrations/20251201090200_create_squads_table.sql`
  - `supabase/migrations/20251201090300_create_user_squads_table.sql`
  - `supabase/migrations/20251201091000_create_invite_links_table.sql`
  - `supabase/migrations/20251202100000_allow_select_on_squads.sql`
  - `supabase/migrations/20251202101500_request_squad_access.sql`
- testy feature:
  - `app/test/squads/application/join_squad_from_invite_use_case_test.dart`
- testy i migracje stats sa opisane centralnie w [stats.md](./stats.md).

## 8. Ograniczenia i status (opcjonalnie, ale zalecane)
- `Transfer ownership` w `DangerZoneSection` jest placeholderem (`TODO` snackbar).
- Kafelek `Tournaments` w `SquadHomePage` i quick action "Add tournament" sa placeholderami.
- `ModifyMemberRoleUseCase` i `RemoveMemberUseCase` maja komentarze `TODO` dot. dodatkowych walidacji po stronie aplikacji; obecnie polegaja glownie na RLS.
- `RemoveMemberUseCase` oznacza uzytkownika rola `removed`; nie usuwa fizycznie rekordu membership.
- Limit "1 squad per owner" jest egzekwowany w `CreateSquadUseCase` (aplikacyjnie), bez dedykowanego constraintu DB.
- `SquadsPage` nie ma osobnej obslugi roli `invited`; taka rola w liscie wpada do galezi domyslnej i konczy sie wyjatkiem.
- Testy `squads` pokrywaja obecnie glownie flow invite join; brak szerszych testow UI/settings/listing.
- Ograniczenia i zaleglosci dla stats sa opisane centralnie w [stats.md](./stats.md).
