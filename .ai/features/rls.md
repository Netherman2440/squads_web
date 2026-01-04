# RLS - Plan polityk (wersja docelowa)

Ten dokument opisuje docelowe polityki RLS dla Supabase/Postgres, zgodne z
aktualnymi ustaleniami. Ma byc na tyle precyzyjny, zeby AI moglo potem
zaimplementowac je 1:1.

## Zalozenia
- `auth.uid()` identyfikuje zalogowanego uzytkownika. Guest = brak `auth.uid()`.
- Tabela profili to `public.users` (nazwa moze byc `profiles`, ale zasady te same).
- Role w `user_squads.role`: `owner`, `admin`, `member`, `pending`, `invited`,
  `declined`, `removed`, `none`.
- Dostep "member" oznacza role: `owner`, `admin`, `member`.
- Dostep "admin" oznacza role: `owner`, `admin`.
- Publiczny sklad (`squads.visibility = 'public'`) jest widoczny dla wszystkich,
  ale **nigdy nie udostepnia** listy `user_squads`.
- `ranking_history` jest aktualnym nazewnictwem (nie uzywamy `score_history`).
- Tabele `tournaments` pomijamy na razie.

## Definicje pomocnicze (pseudokod)
- `is_owner(squad_id)`:
  - `exists squads where squads.squad_id = squad_id and squads.owner_id = auth.uid()`
- `is_admin(squad_id)`:
  - `exists user_squads where squad_id = squad_id and user_id = auth.uid()
    and role in ('owner', 'admin')`
- `is_member(squad_id)`:
  - `exists user_squads where squad_id = squad_id and user_id = auth.uid()
    and role in ('owner', 'admin', 'member')`
- `is_public(squad_id)`:
  - `exists squads where squads.squad_id = squad_id and visibility = 'public'`

## Tabele i polityki

### `public.users` (profiles)
- SELECT: tylko wlasny rekord (`auth.uid() = user_id`).
- INSERT: tylko wlasny rekord (`auth.uid() = user_id`).
- UPDATE/DELETE: tylko wlasny rekord (`auth.uid() = user_id`).

### `squads`
- SELECT:
  - publiczne sklady: kazdy,
  - prywatne sklady: tylko `is_member(squad_id)` (owner/admin/member).
- INSERT: tylko zalogowany (`auth.uid() = owner_id`).
  - Limit "1 squad per owner" to regula biznesowa (app/constraint), nie RLS.
- UPDATE/DELETE: tylko owner (`is_owner(squad_id)`).

### `user_squads`
- SELECT:
  - owner moze widziec wszystkie wiersze w swoim skladzie,
  - kazdy zalogowany moze widziec **tylko swoj** rekord.
- INSERT:
  - domyslnie tylko przez RPC `join_squad_by_invite` (SECURITY DEFINER),
    bez bezposredniego INSERT z klienta.
  - opcjonalnie: pozwolic na insert ownera przy tworzeniu skladu
    (`auth.uid() = user_id`, `role = 'owner'`, `is_owner(squad_id)`).
- UPDATE/DELETE: tylko owner (zarzadza rolami i usuwaniem czlonkow).
- Dodatkowe ograniczenia:
  - nie pozwalac zmieniac `user_id` rekordu,
  - nie pozwalac na eskalacje roli bez bycia ownerem.

### `invite_links`
- SELECT/INSERT/UPDATE/DELETE: tylko owner danego skladu.
- Brak publicznego SELECT po `code`.
- RPC `join_squad_by_invite(code)`:
  - SECURITY DEFINER,
  - `GRANT EXECUTE` co najmniej dla `authenticated` (anon nie potrzebuje,
    bo flow i tak wymaga logowania),
  - weryfikuje `valid_until` i idempotentnie dodaje do `user_squads`.

### `players`
- SELECT: `is_public(squad_id)` OR `is_member(squad_id)`.
- INSERT/UPDATE/DELETE: tylko `is_admin(squad_id)`.
- WITH CHECK: `squad_id` musi nalezec do skladu, do ktorego user ma uprawnienia.

### `matches`
- SELECT: `is_public(squad_id)` OR `is_member(squad_id)`.
- INSERT/UPDATE/DELETE: tylko `is_admin(squad_id)`.
- WITH CHECK: `squad_id` musi nalezec do skladu, do ktorego user ma uprawnienia.

### `teams`
- Wiersz jest powiazany z `matches.match_id`.
- SELECT: `is_public(matches.squad_id)` OR `is_member(matches.squad_id)`.
- INSERT/UPDATE/DELETE: tylko `is_admin(matches.squad_id)`.
- WITH CHECK:
  - `match_id` musi wskazywac mecz w skladzie, do ktorego user ma uprawnienia.

### `team_players`
- Wiersz zawiera `match_id`, `team_id`, `player_id`.
- SELECT: `is_public(matches.squad_id)` OR `is_member(matches.squad_id)`.
- INSERT/UPDATE/DELETE: tylko `is_admin(matches.squad_id)`.
- WITH CHECK:
  - `match_id` musi wskazywac mecz w skladzie, do ktorego user ma uprawnienia,
  - `player_id` musi nalezec do tego samego skladu co `matches.squad_id`.

### `ranking_history`
- Wiersz ma `player_id` i opcjonalnie `match_id`.
- SELECT:
  - `is_public(players.squad_id)` OR `is_member(players.squad_id)`.
- INSERT/UPDATE/DELETE: tylko `is_admin(players.squad_id)`.
- WITH CHECK:
  - `player_id` musi nalezec do skladu, do ktorego user ma uprawnienia,
  - jesli `match_id` nie jest NULL, to `matches.squad_id` musi byc rowne
    `players.squad_id`.

## Uwagi koncowe
- RLS ma byc wlaczone na wszystkich tabelach powyzej.
- Polityki powinny byc pisane w stylu "USING ... WITH CHECK ..." i oparte o `EXISTS`.
- Publiczne sklady nie odslaniaja danych z `user_squads`.
