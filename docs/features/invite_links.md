# Invite links (plan)

Docelowo: w `app/lib/features/squads/presentation/pages/squad_settings_page.dart`
jest sekcja zaproszen. Dodajemy flow "link do dolaczenia do skladu".

## User stories
- Jako owner moge wygenerowac dzialajacy link z zaproszeniem do skladu.
- Jako uzytkownik po kliknieciu linku zostaje dodany do skladu
  (nowy wpis w tabeli `user_squads` z rola `member`).
- Jako uzytkownik niezalogowany po kliknieciu linku jestem przenoszony
  na auth page; po zalogowaniu/utworzeniu konta automatycznie dolaczam do skladu.

## Zasady biznesowe
- Link jest wielokrotnego uzytku, dziala do czasu wygasniecia.
- Regeneracja linku uniewaznia poprzedni (jeden aktywny na squad).
- Generowac i ogladac link moze tylko owner.

## Proponowany flow
1. Owner generuje nowy `code`.
2. Backend wykonuje upsert (uniewaznia poprzedni).
3. Link ma postac: `https://adres-prod.com/invite?code=XYZ`.
4. Po wejsciu na link kod trafia do `sessionStorage` (z TTL).
5. Jesli user nie jest zalogowany, nastepuje redirect do auth.
6. Po zalogowaniu, jesli kod jest w `sessionStorage`, wywolujemy dolaczenie.
7. Po sukcesie kod jest usuwany z `sessionStorage`.

Obsługa brzegowa:
- Jesli user juz jest w skladzie, wyswietlamy info i nie dodajemy ponownie.
- Brak dostepu -> redirect do login.
- Niepoprawny/wygasly kod -> komunikat "Kod jest niepoprawny lub wygasl".

## Implementacja

### DB (Supabase)
Tabela `invite_links`:
- `code` (text, unique)
- `squad_id` (uuid, unique, FK -> squads.id)
- `created_at` (timestamptz, default now())
- `valid_until` (timestamptz)
- `created_by` (uuid, FK -> auth.users.id)

RLS:
- `select` tylko dla ownera danego squadu.
- `insert/update/delete` tylko dla ownera danego squadu.
- Brak publicznego odczytu przez kod (nie udostepniamy `invite_links` anon).

RPC / function:
- `join_squad_by_invite(code text)` (SECURITY DEFINER)
  - weryfikuje `valid_until` i czy kod istnieje
  - pobiera `squad_id`
  - tworzy wpis w `user_squads` jako `member`
  - operacja idempotentna (jesli juz jest, zwraca sukces)
  - zwraca `squad_id` lub kod bledu

### Domain
Entity: `InviteLink`.

InviteLinksRepository:
- `createInviteLink(squadId, code, validFor)` (server ustawia timestamps)
- `getInviteLink(squadId)` (dla settings page)

SquadRepository:
- `joinSquadByCode(code)` -> wywoluje RPC `join_squad_by_invite`.

### Infrastructure
`SupabaseInviteLinksRepository`:
- standardowy CRUD dla `invite_links` (owner-only).
`SupabaseSquadRepository`:
- wywoluje `rpc('join_squad_by_invite', ...)`.

### Application
- `generateInviteLinkUseCase(linkRepo)`:
  - generuje kod (UUID lub inny bezpieczny generator)
  - `validFor` z app config (np. 1h)
  - zwraca `InviteLink`
- `getSquadInviteLinkUseCase(linkRepo)`:
  - zwraca aktywny link lub `null` jesli wygasl
- `joinSquadFromInviteUseCase(squadRepo, inviteCodeStorage)`:
  - pobiera kod z `sessionStorage`
  - wywoluje `joinSquadByCode`
  - po sukcesie usuwa kod ze storage

### Presentation
- UI juz istnieje; gdy link niewazny, pokazujemy tylko "Generate invite link".
- Nowy route: `/invite?code=XYZ`, ktory zapisuje kod i kieruje do auth/landing.

### Notatki bezpieczenstwa
- Weryfikacja i dolaczenie musza byc po stronie DB (RPC + RLS).
- Klient nie odczytuje `invite_links` po kodzie.
- Kod przechowujemy tylko tymczasowo w `sessionStorage` (nie w auth tokenach).
