## Squad Details / SquadShell – Implementation Plan

### 1. Scope & Goals

- **Goal**: Provide a squad‑details flow (SquadShell + SquadHome) that:
  - shows squad header (name, visibility, member count, role‑aware actions),
  - exposes navigation entry‑points to Players, Matches, Tournaments, Stats,
  - enforces RBAC based on `Membership`/`SquadRole` (owner/admin/member vs guest/none),
  - fits into existing `squads` feature as a router/orchestrator, not a separate domain.
- **Out of scope (MVP for this slice)**:
  - actual Players/Matches/Tournaments/Stats subpages (only navigation tiles/CTAs),
  - squad settings/editing and invitations management (badge/CTA placeholders only),
  - global error page (kept as [Poza MVP] idea; errors handled locally in shell for now).

---

### 2. Domain Layer

- **No new entities** – reuse existing:
  - `Squad` (`features/squads/domain/entities/squad.dart`) – already contains:
    - identity fields (`squadId`, `ownerId`, `name`, `visibility`, `sportType`,
      `createdAt`, `memberCount`),
    - projection field `role: SquadRole` (current user’s role, default `none`).
  - `Membership` (`features/squads/domain/entities/membership.dart`) – models
    `user_squads` (`userId`, `squadId`, `role`, `createdAt`).

- **Repository interfaces**
  - `SquadRepository` (`features/squads/domain/repositories/squad_repository.dart`):
    - extend with:
      - `Future<Squad?> getSquad(String squadId);`
    - semantics:
      - returns base `Squad` data built from `squads` table (and existing joins for
        `memberCount`), but **ignores role** (no `user_squads` join, no RBAC).
      - never throws for 404 – returns `null` when squad does not exist.
  - `MembershipRepository` (`features/squads/domain/repositories/membership_repository.dart`):
    - optionally extend with a convenience method:
      - `[Poza MVP?] Future<Membership?> getMembershipForUserInSquad(String userId, String squadId);`
    - for MVP można zbudować `getMembershipForUserInSquad` na kliencie z
      `getMembershipsForUser(userId)` bez zmiany interfejsu, jeśli nie chcemy
      powiększać kontraktu.

---

### 3. Application Layer

#### 3.1. GetSquadUseCase

- **File**: `features/squads/application/get_squad_use_case.dart`
- **Dependencies**:
  - `SquadRepository`
  - `MembershipRepository`
  - (pośrednio) `GetCurrentUserUseCase` albo `UserRepository` – do pobrania
    aktualnego użytkownika; jeśli brak użytkownika → guest.
- **Input**:
  - `String squadId`
- **Output**:
  - `Future<Result<Squad, SquadFailure>>` (albo równoważny typ, np.
    `Either<SquadFailure, Squad>`; na poziomie Riverpoda będzie to potem
    opakowane w `AsyncValue`).
- **Failure model (`SquadFailure`)**:
  - `notFound` – squad nie istnieje.
  - `forbidden` – squad istnieje, ale użytkownik nie ma dostępu (np. prywatny
    skład i rola `none`/guest).
  - `[Poza MVP] unexpected` – np. błąd sieci/Supabase jeśli chcemy mieć
    osobny wariant (opcjonalne; w MVP może być jeden wariant `unknown`).

- **Algorithm (happy path)**:
  1. **Fetch squad**:
     - `final squad = await squadRepository.getSquad(squadId);`
     - if `squad == null` → return `Result.error(SquadFailure.notFound)`.
  2. **Determine current user context**:
     - pobierz current user (np. `GetCurrentUserUseCase`),
     - jeśli `user == null`:
       - set `role = SquadRole.none`,
       - jeśli `squad.visibility == private` → `forbidden`,
       - jeśli `public` → allow, zwróć `squad.copyWith(role: SquadRole.none)`.
  3. **Fetch membership for current user**:
     - pobierz membership dla `(userId, squadId)`:
       - albo bezpośrednio przez `MembershipRepository.getMembershipForUserInSquad`,
       - albo przez `getMembershipsForUser(userId)` i filtr po `squadId`.
     - jeśli membership znaleziony:
       - `final role = membership.role;`
       - zwróć `squad.copyWith(role: role);`
     - jeśli membership **nie znaleziony**:
       - `role = SquadRole.none`;
       - jeśli `squad.visibility == private` → `forbidden`,
       - dla `public` → zwróć `squad.copyWith(role: SquadRole.none)`.

- **Error propagation**:
  - błędy z repo (Supabase/network) mapujemy na `SquadFailure.unexpected`
    albo zostawiamy jako exception obsługiwany przez warstwę notifiers; ważne,
    aby presentation warstwa potrafiła rozróżnić:
    - `notFound`,
    - `forbidden`,
    - „inne” (network/unknown).

---

### 4. Infrastructure Layer

#### 4.1. SupabaseSquadRepository

- **File**: `features/squads/infrastructure/repositories/supabase_squad_repository.dart`
- **Extend interface implementation**:
  - implement `Future<Squad?> getSquad(String squadId)`:
    - zapytanie do tabeli `squads`:
      - po `squad_id = :squadId`,
      - z aktualnie stosowanym do list joinem/obliczeniem `member_count`
        (np. aggr z `user_squads`) – tak, aby `memberCount` w detail był
        spójny z listą.
    - mapowanie → `Squad.fromMap`, ale **bez** kolumny roli (brak joinu
      z `user_squads` – `role` pozostaje na poziomie use case).
    - jeśli zapytanie nie zwróci wiersza → `null`.

#### 4.2. SupabaseMembershipRepository

- **File**: `features/squads/infrastructure/repositories/supabase_membership_repository.dart`
- Ewentualne dodanie metody:
  - `[Poza MVP?] getMembershipForUserInSquad(userId, squadId)` z zapytaniem:
    - `select * from user_squads where user_id = :userId and squad_id = :squadId limit 1;`
  - w MVP dopuszczalne:
    - `getMembershipsForUser(userId)` + filtr na kliencie; wydajnościowo OK,
      bo użytkownik nie będzie w setkach składów.

---

### 5. Presentation Layer

#### 5.1. Routing & Shell

- **New route**:
  - `path: /squads/:squadId`
  - nazwa widoku: `SquadShell` (kontener), zgodnie z `.ai/ui_plan.md`.
- **Role**:
  - wspólny layout i RBAC dla wszystkich podstron składu,
  - na MVP: SquadsShell + „SquadHome” content w jednym widoku (brak realnych
    child routes; children routes zostaną dodane później).
- **Component structure**:
  - `features/squads/presentation/pages/squad_shell_page.dart`:
    - `class SquadShellPage extends ConsumerWidget`
    - pobiera `squadId` z `GoRouter` (`GoRoute` params),
    - `ref.watch(squadDetailProvider(squadId))` – provider opisany poniżej,
    - renderuje:
      - **loading** – spinner / skeleton,
      - **error**:
        - `forbidden` → „No access” layout (spójny z `.ai/ui_plan.md`),
        - `notFound` → „Squad not found” layout,
        - inne → ogólny błąd („Something went wrong”) w `SelectableText.rich`,
      - **success**:
        - header (`SquadHeader`),
        - główny content `SquadHome` z dużymi panelami Players/Matches/Tournaments/Stats,
        - placeholder na ikonę settings z badge zaproszeń (bez realnej nawigacji).

#### 5.2. State & Notifier (Riverpod)

- **State**:
  - `SquadDetailState`:
    - `Squad? squad;`
    - `SquadFailure? failure;` (lub przechowywane w `AsyncValue` zamiast stanu),
    - `[Poza MVP] bool isRefreshing;`
  - Zgodnie z globalnymi zasadami preferujemy `AsyncNotifier` + `AsyncValue`
    zamiast ręcznego booleana, ale failure‑typ jest tu istotny.

- **Provider**:
  - `@riverpod class SquadDetailNotifier extends AsyncNotifier<Squad>`:
    - `Future<Squad> build(String squadId)`:
      - woła `GetSquadUseCase` i mapuje wynik na:
        - `AsyncValue.data(squad)` albo
        - `AsyncValue.error(SquadFailure, stackTrace)`.
    - `Future<void> refresh()`:
      - ponownie woła `build(squadId)` (lub `getSquadUseCase.execute`),
      - używane np. przez `RefreshIndicator`.

- **Error handling pattern**:
  - Page/notifier **decyduje** co renderować:
    - w `build()` strony:
      - `final state = ref.watch(squadDetailNotifierProvider(squadId));`
      - `state.when(...)`: loading / error / data.
    - w gałęzi `error`:
      - sprawdź typ błędu (np. przez `if (error is SquadFailure)`),
      - pokaż odpowiedni „error page” _wewnątrz_ shellu (nie nawiguj automatycznie).
  - To jest zgodne z Twoją intuicją: use case tylko zwraca wynik, notifier/page
    interpretują go i wybierają konkretny layout.

#### 5.3. SquadShell UI (MVP)

- **Header (SquadHeader)**:
  - Wyświetla:
    - nazwa składu,
    - badge visibility (Public/Private),
    - member count (`X members`),
    - opcjonalne CTA zależne od roli:
      - owner/admin/member: widoczna ikona settings (z badge oczekujących
        zaproszeń – placeholder),
      - guest/none: brak settings; ewentualny CTA „Apply to join” [Poza MVP].

- **Main content (SquadHome)**:
  - Siatka/kafelki (adaptowane z legacy `SquadPage`):
    - „Players” – otwiera na razie placeholder dialog/snackbar/`SelectableText`
      („Players page coming soon”),
    - „Matches” – jw.,
    - „Tournaments” – jw.,
    - „Stats” – jw. (docelowo osobna podstrona).
  - Layout zgodny z `.ai/ui_plan.md`: duże panele, responsywny układ.

---

### 6. Error & Access UX

- **NotFound (404)**:
  - Lokalny layout w SquadShell:
    - ikona błędu,
    - komunikat „Squad not found”,
    - CTA „Back to squads list”.

- **Forbidden (403)**:
  - Lokalny layout:
    - ikona „lock”,
    - komunikat „You do not have access to this squad”,
    - CTA „Back to squads list”,
    - dla zalogowanego użytkownika można [Poza MVP] dodać informację o roli.

- **Global Error Page [Poza MVP]**:
  - Możliwe wprowadzenie globalnego error‑route i mechanizmu nawigacji przy
    „twardych” błędach (np. edge cases, których nie chcemy obsługiwać lokalnie).
  - Na razie wszystkie przypadki obsługujemy w SquadShell zgodnie z aktualnym
    MVP zakresem.

---

### 7. Implementation Steps Checklist

1. **Domain / Repositories**
   - [ ] Dodać `getSquad(String squadId)` do `SquadRepository`.
   - [ ] (Opcjonalnie) rozszerzyć `MembershipRepository` o
         `getMembershipForUserInSquad`.
2. **Infrastructure**
   - [ ] Zaimplementować `getSquad` w `SupabaseSquadRepository`.
   - [ ] (Opcjonalnie) dodać `getMembershipForUserInSquad` w
         `SupabaseMembershipRepository`.
3. **Application**
   - [ ] Utworzyć `GetSquadUseCase` z logiką overlay roli + RBAC (notFound/forbidden).
4. **Presentation – State**
   - [ ] Dodać `SquadDetailNotifier` (AsyncNotifier) + provider parametryczny
         po `squadId`.
5. **Presentation – UI**
   - [ ] Dodać `SquadShellPage` z obsługą `AsyncValue` (loading/error/data).
   - [ ] Stworzyć `SquadHeader` i `SquadHome` (kafelki Players/Matches/Tournaments/Stats).
   - [ ] Wpiąć route `/squads/:squadId` do GoRouter.
6. **UX & Testing**
   - [ ] Przetestować ścieżki: guest + public, guest + private, logged‑in bez
         membership, member/admin/owner, squad nieistniejący.
   - [ ] Dostosować error layouts (`SelectableText.rich`) do globalnych wytycznych.


