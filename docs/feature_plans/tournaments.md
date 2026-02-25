## Stories (zrodlo: `docs/prd.md`, `docs/ui_plan.md`, brief produktu)

Jako użytkownik chce móc podzielić graczy na więcej niż dwie drużyny

Jako użytkownik chce móc rozegrać wiele meczy pomiędzy tymi drużynami 

W trakcie trwania turnieju chce móc edytować składy drużyn. To nie wpływa na poprzednie mecze 

-
###  Lista turniejow skladu
- Wejscie z kafla "Tournaments" na stronie squadu.
- Routing: `/squads/:squadId/tournaments`.
- Lista pokazuje nazwe oraz date utworzenia.
- Dostep read-only zgodnie z visibility squadu; tylko owner/admin widzi akcje tworzenia/edycji.

###  Utworzenie turnieju z draftu
- Start z listy turniejow lub CTA "Create Tournament".
- Uzytkownik wybiera graczy oraz liczbe druzyn.
- Draft generuje kilka propozycji podzialu na wybrana liczbe druzyn.
- Wybor propozycji tworzy turniej i przenosi do `/squads/:squadId/tournaments/:tournamentId`.
- Walidacja: kazdy gracz moze byc przypisany tylko do jednej druzyny w ramach turnieju.
- na szerokich ekranach wyświetlamy naraz wszystkie drużyny obok siebie, na wąskich - wszystkie drużyny pod sobą i nawigacja między propozycjami na górze 
###  Widok turnieju
- Routing: `/squads/:squadId/tournaments/:tournamentId`.
- Widok zawiera: skrótową liste druzyn (aktualne sklady - np. nazwa drużyny i kolor), historie meczow i prosta tabele wynikow. 
- Dane sa tylko do odczytu dla member/guest; edycje tylko dla owner/admin.
- dla admina jest opcja przejścia do podglądu propozycji - można dzięki temu przejrzeć (tak samo jak w match details) inne drafty

### Widok drużyn
`/squads/:squadId/tournaments/:tournamentId/teams`
tutaj pokazujemy szczeegółowo drużyny - sam układ drużyn powinien być taki sam jak przy tworzeniu draftu

###  Edycja druzyn turniejowych
- W widoku turnieju owner/admin moze edytowac nazwe, kolor i sklad druzyn (dodawanie/usuwanie/zamiana zawodnikow).
- Edycja druzyn jest dozwolona takze po wpisaniu wynikow meczow.
- Zmiany skladu druzyn turniejowych nie zmieniaja historycznych skladów w juz rozegranych meczach; nowe mecze uzywaja aktualnych skladów.
- można też tournament details przejść do przeglądania propozcyji draftu - pokaże nam to inne opcje z tournament draft payloads dla tego meczu 
### Dodawanie meczu turniejowego i wynik
- W widoku turnieju owner/admin moze dodac mecz, wybierajac dwie druzyny z turnieju.
- Uzytkownik wpisuje wynik meczu (home/away + opcjonalne metadane).
- Mecz pojawia sie w historii turnieju, a tabela wynikow aktualizuje sie po zapisie.
- Wynik turniejowy wplywa tylko na zawodnikow bioracych udzial w danym meczu.

---

DB:
### 1.6. `tournaments`

Turnieje i ich akceptowany zestaw draftu.

| Kolumna                | Typ         | Ograniczenia                                        |
| ---------------------- | ----------- | --------------------------------------------------- |
| `tournament_id`        | UUID        | PK                                                  |
| `squad_id`             | UUID        | NOT NULL; FK → `squads(squad_id)` ON DELETE CASCADE |
| `name`                 | TEXT        | NULLABLE                                            |
[usunąćy kolumnę expectedteamscount]
| `created_at`           | TIMESTAMPTZ | NOT NULL DEFAULT now()                              |

### 1.7. `tournament_teams`

Tożsamości drużyn turniejowych (edytowalne nazwy/kolory).

| Kolumna              | Typ         | Ograniczenia                                                  |
| -------------------- | ----------- | ------------------------------------------------------------- |
| `tournament_team_id` | UUID        | PK          |
| `tournament_id`      | UUID        | NOT NULL; FK → `tournaments(tournament_id)` ON DELETE CASCADE |
| `name`               | TEXT        | NULLABLE                                                      |
| `color`              | TEXT        | NULLABLE                                                      |
| `created_at`         | TIMESTAMPTZ | NOT NULL DEFAULT now()                                        |


### 1.8. `tournament_team_players`

Składy drużyn turniejowych.

| Kolumna              | Typ  | Ograniczenia                                                                                                                               |
| -------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `tournament_team_id` | UUID | NOT NULL; FK → `tournament_teams(tournament_team_id)` ON DELETE CASCADE                                                                    |
| `tournament_id`      | UUID | NOT NULL;  FK → `tournaments(tournament_id)` ON DELETE CASCADE |
| `player_id`          | UUID | NOT NULL; FK → `players(player_id)` ON DELETE CASCADE        


tournament_drafts (tak samo jak drafts tylko tournament di zamiast match id )

tournament draft payloads (tak samo db jak draft payloads tylko komunikujemy się po tournamentid )




# Domain:
## draftRepository:
createDraft( minimum dwie max 4
Przystosowanie greedy  i combinatory algorytmu do wielu drużyn. (zrobione)
zachowujemy identyczne flow jak przy meczu - wybieramy graczy potem opcjonalnie relacje przy czym możemy też przy wyborze graczy wybieramy liczbę drużyn

class tournament
id
squad_id
created_at
list<Team>? tournamentTeams  (używamy zwyczajnego team, ale parsujemy dane z tablicy tournament_teams i tournament_team_players )
list<Match>? tournamentMatches 

tournamentsRepository:
getTournaments(squadId) 

createTournament(CreateTournament data)
updateTournament(name)
deleteTournament(tournamentId)
updateTournamentTeams(list<Team> teams) 

playerRepository
getTournamentPlayers()
matchRepository
getTournamentMatches()
Infra:
supabase calls, ważne żeby zadbać o filtrowanie meczy, drużyn i team_players po tournament id to dużo urpości 


Application
createTournament Use Case
tworzymy turniej (bez teams)
mając tournamentId tworzymy draft i payload - identucznie jak przy create match


get tournaments use case 

zwraca listę<tournament> w /squads/id/tournaments bez matches i teams

gettournament
tu już dostajemy poszerzony tournament o teams matches - na początku teams  i matches są puste. 

gettournamentDraft
zwraca tournament draft albo go zaczyna - awaitable, ale nie trzeba zostać w tym ekranie żeby całość się wykonała - tak samo jak przy meczu

i inne use casy jeśli czegoś brakuje to mi to zgłoś zaproponuj i dopisz