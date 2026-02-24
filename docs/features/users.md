# users - dokumentacja feature (stan aktualny)

Stan na: **24 lutego 2026**

## 1. Cel i zakres
Feature `users` odpowiada za profil biezacego uzytkownika (`/me`) i publiczny model danych uzytkownika wykorzystywany w innych feature.

Zakres techniczny:
- pobranie aktualnie zalogowanego uzytkownika (`id`, `email`, `fullName`),
- zlozenie podsumowania profilu z lista przynaleznosci do squad-ow,
- zapis/uzupelnianie rekordu w `public.users`,
- udostepnienie API `getUsers(...)` do wzbogacania danych czlonkow w `squads`.

## 2. Co jest zaimplementowane
- Ekran profilu: `UserPage` (`/me`) z sekcja profilu i sekcja "My squads".
- Widok profilu (`UserProfileCard`) z obsluga stanow:
  - loading,
  - blad,
  - brak sesji ("You are not logged in."),
  - dane uzytkownika (preferowany `fullName`, fallback do `email`).
- Ladowanie danych przy starcie ekranu:
  - `userNotifierProvider.notifier.loadUser()`,
  - `squadsNotifierProvider.notifier.loadSquads()`.
- Odswiezanie pull-to-refresh laduje ponownie profil i liste squad-ow.
- Nasluch zmian auth w `UserPage`:
  - przy przejsciu `niezalogowany -> zalogowany` odswiezany jest profil i squads.
- Sekcja "My squads":
  - bazuje na `UserProfileSummary.memberships`,
  - renderuje `SquadListItem`,
  - przejscie do `/squads/:squadId`.
- CTA dodawania squadu zawsze jest dostepne i prowadzi do `/squads` (label zalezy od tego, czy user ma jakakolwiek role rozna od `none`).

## 3. Routing
- Trasa feature:
  - `/me` -> `UserPage` (`AppRoute.profile`) w `ShellRoute`.
- Wejscie do feature:
  - menu profilowe w `RootShell` (`context.go('/me')`),
  - pozycja "Profil" w sidebarze (`/me`),
  - po udanym logowaniu email/haslo w `AuthPage` (dla nie-guest, jesli brak pending invite) -> `context.go('/me')`.
- Wyjscia/nawigacja z feature:
  - "Add more"/"Add your first squad" -> `context.pushNamed(AppRoute.squads.name)`,
  - klik na squad -> `context.pushNamed(AppRoute.squadDetails.name, pathParameters: {'squadId': ...})`.

## 4. DB i RLS (zbiorczo)
- Tabele uzywane bezposrednio lub posrednio przez feature:
  - `public.users`:
    - `user_id` (PK, FK -> `auth.users(id)`, `on delete cascade`),
    - `email` (`not null`, unique),
    - `full_name` (nullable),
    - `created_at` (default `now()`).
  - `public.user_squads` (dla "My squads"):
    - klucz glowny `(user_id, squad_id)`,
    - `role` (`public.user_squad_role`),
    - indeksy: `user_squads_user_idx`, `user_squads_squad_idx`.
  - `public.squads` (dla nazw squad-ow w podsumowaniu):
    - `squad_id`, `name`, `visibility`, `owner_id`, pola rankingowe.
- Funkcje/trigger SQL:
  - `public.sync_public_user()` (security definer, `row_security = off`) synchronizuje `public.users` z `auth.users`,
  - trigger `on_auth_user_sync` na `auth.users` (`after insert or update of email, raw_user_meta_data`).
- RPC:
  - feature `users` nie wywoluje dedykowanych RPC.
- RLS:
  - `public.users`:
    - user moze czytac/insert/update/delete wlasny profil (`auth.uid() = user_id`),
    - owner squadu moze czytac profile uzytkownikow nalezacych do jego squadu ("Owners can read profiles of squad members").
  - `public.user_squads`:
    - user moze czytac swoje membershipy; owner moze czytac membershipy swojego squadu.
  - `public.squads`:
    - aktywna polityka select: "Anyone can read squads" (`using (true)`).

## 5. Architektura
### 5.1 Domain
- Encja:
  - `app/lib/features/users/domain/entities/user.dart` (`id`, `email`, `fullName`).
- Repozytorium:
  - `UserRepository`:
    - `getCurrentUser()`,
    - `updateUser(User user)`,
    - `getUsers(List<String> userIds)`,
    - `upsertUser(User user)`.

### 5.2 Application
- `GetCurrentUserUseCase`:
  - pobiera `User` z `UserRepository`,
  - pobiera membershipy usera z `MembershipRepository`,
  - pobiera odpowiadajace squady z `SquadRepository.getSquadsByIds(...)`,
  - sklada `UserProfileSummary` (`user` + `List<UserMembershipItem>`).
- DTO/summary:
  - `UserMembershipItem` (`squadId`, `squadName`, `role`),
  - `UserProfileSummary` (`user`, `memberships`).
- Provider use case:
  - `getCurrentUserUseCaseProvider` sklada zaleznosci z users+squads.

### 5.3 Infrastructure
- `SupabaseUserRepository`:
  - `getCurrentUser()`:
    - czyta `supabase.auth.currentUser`,
    - probuje odczytac rekord z `public.users`,
    - fallback dla `fullName` z `userMetadata` (`full_name`/`name`/`display_name`),
    - jesli `fullName` jest tylko w metadata, wykonuje `upsertUser(...)`.
  - `getUsers(...)`:
    - select z `public.users` przez `inFilter('user_id', userIds)`.
  - `upsertUser(...)`:
    - upsert po `user_id`,
    - zapisuje `full_name` tylko gdy po trim nie jest pusty.
  - `updateUser(...)` deleguje do `upsertUser(...)`.
- Provider infrastruktury:
  - `userRepositoryProvider` -> `SupabaseUserRepository`.

### 5.4 Presentation
- Stan:
  - `UserState` (`isLoading`, `profile`, `error`).
- Notifier:
  - `UserNotifier.loadUser()` wywoluje `GetCurrentUserUseCase.execute()` i mapuje wynik do stanu.
- UI:
  - `UserPage` koordynuje ladowanie profilu i squads, odswiezanie, oraz nawigacje.
  - `UserProfileCard` renderuje szczegoly usera lub stany fallback.

## 6. Integracje / punkty styku
- `squads`:
  - `GetCurrentUserUseCase` korzysta z:
    - `MembershipRepository.getMembershipsForUser(...)`,
    - `SquadRepository.getSquadsByIds(...)`.
  - `UserPage` korzysta ze stanu `squadsNotifierProvider` i widgetu `SquadListItem`.
- `auth`:
  - `AuthPage` po udanym logowaniu kieruje na `/me` (dla usera nieanonimowego).
  - `CompleteOAuthSignInUseCase` wywoluje `UserRepository.getCurrentUser()`, co przy okazji moze uzupelnic `public.users`.
- `squads settings`:
  - `GetSquadSettingsMembersUseCase` korzysta z `UserRepository.getUsers(...)` do wzbogacania `SquadMember` o `email/fullName`.

## 7. Szybka mapa plikow
- Najwazniejsze pliki w feature:
  - `app/lib/features/users/domain/entities/user.dart`
  - `app/lib/features/users/domain/repositories/user_repository.dart`
  - `app/lib/features/users/application/get_current_user_use_case.dart`
  - `app/lib/features/users/application/user_profile_summary.dart`
  - `app/lib/features/users/infrastructure/repositories/supabase_user_repository.dart`
  - `app/lib/features/users/presentation/state/user_state.dart`
  - `app/lib/features/users/presentation/state/user_notifier.dart`
  - `app/lib/features/users/presentation/pages/user_page.dart`
  - `app/lib/features/users/presentation/widgets/user_profile_card.dart`
- Najwazniejsze pliki poza feature:
  - `app/lib/core/app_router.dart` (`/me`)
  - `app/lib/core/root_shell.dart` (wejscie do profilu z UI shella)
  - `app/lib/features/auth/presentation/pages/auth_page.dart` (nawigacja po loginie)
  - `app/lib/features/auth/application/complete_oauth_sign_in_use_case.dart`
  - `app/lib/features/squads/infrastructure/repositories/supabase_membership_repository.dart`
  - `app/lib/features/squads/infrastructure/repositories/supabase_squad_repository.dart`
  - `supabase/migrations/20251201090100_create_users_table.sql`
  - `supabase/migrations/20251201092000_sync_public_users_from_auth.sql`
  - `supabase/migrations/20251202090000_add_full_name_to_public_users.sql`
  - `supabase/migrations/20251201090300_create_user_squads_table.sql`
  - `supabase/migrations/20251201090200_create_squads_table.sql`
  - `supabase/migrations/20251202100000_allow_select_on_squads.sql`
  - `supabase/tests/users_sync_trigger_test.sql`
  - `supabase/tests/users_full_name_column_test.sql`

## 8. Ograniczenia i status
- Brak dedykowanego ekranu edycji profilu; `updateUser(...)` istnieje tylko jako warstwa repozytorium/upsert.
- W `UserPage` lista "My squads" bazuje na membershipach z `GetCurrentUserUseCase`; `SquadsNotifier` jest uzyty glownie do odswiezania i fallbacku danych tile.
- Brak testow Dart (`app/test`) dedykowanych feature `users` (stan na 24.02.2026).
