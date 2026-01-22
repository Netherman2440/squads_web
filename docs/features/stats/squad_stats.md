SQUAD STATS

DB
Trzeba stworzyć jeszcze migrację do :
get_squad_stats(squad_Id)
ta metoda ma zwracać:

top_player: {Player} 
worst_player: {Player)
top_Rising_star | Wschodząca gwiazda (gracz z największą change od base score) {Player)
liczba meczy: int
total goals: int
total home goals: int
total away goals: int
avg goals per match: double
avg wynik (avg hove : avg away) [double: double]
liczba graczy: int
avg player score: double

---
domain:
Klasa SquadStats która odzwierciedla zwrócone dane

squad_repository: getSquadStats(squadId) => SquadStats

infra:
squads api client wywołuje metodę rpc 

usecases:
getSquadStatsUseCase - wywołuje te metody tylko 

presentation:

WIDGETY (reużywalne)
StatTile:
Zawiera wyrównany do lewej tekst z nazwą statystyki i z wyrównaną doprawej wartością statystyki. Tile przyjmuje tekst ale w zależności od statystyki będziemy go inaczej wyświetlac (inaczej int a inaczej player)

pages
/squads/:squadId/stats

Title,
list<StatTile>


---

PLAYER STATS

utworzone już migracje do db:

get_player_head_to_head_stats(p_player_id uuid)

```
returns table (
  other_player_id uuid,
  other_name text,
  together_matches int,
  together_wins int,
  together_draws int,
  together_losses int,
  together_goals_for int,
  together_goals_against int,
  vs_matches int,
  vs_wins int,
  vs_draws int,
  vs_losses int,
  vs_goals_for int,
  vs_goals_against int
)
```

Brakuje metody
get_player_stats(p_player_id uuid)
powinna zwrócić
```
ase ranking
current ranking
total matches
total wins
total draws 
total  losses
win streak
loss streak
biggest win streak 
biggest loss streak
goals scored
goals conceded
avg goals per match (tego gracza oczywiście w jego meczach)
avg score
```

domain:
PlayerStats klasa mapująca powyższe statystyki

PlayerHeadToHeadStat - klasa której listę chciałbym dostać z get_player_head_to_head_stats

i metody w repo getPlayerStats(playerId) => PlayerStats
getPlayerHeadToHeadStat(playerId) => list<PlayerHeadToHeadStat>

infra:
wywolujemy metody rpc na sqlu

presentation:

widgety: do player stats wykorzystujemy StatTile.. 

PlayerStatTile 

Zawiera player name wyrównane do lewej  oraz do prawej w odstępach wszystkie wartości statystyk z klasy PlayerHeadToHeadStat.




pages:
squads/:squadId/players/:playerId/stats

Title
list<StatTile>
 wyświetlająca PlayerStats

pod spodem znajduje się sekcja "Head to Head"

Mamy Header z tytułami kolumn - nazwa gracza ... itd wszystkei statystyki przynajmniej skrótowo opisane.
Pod spodem jest list<PlayerHeadToHeadStat>

Gdy kliknę na jakiś header danej statystyki to ten header się podświetla i względem tej konkretenej statystyki są  sortowani od góry do dołu.
Gdy kliknę znowu - wtedy sortuje się od dołu do góry, zawsze jest jakieś sortowanie.

Sortowanie powinno też inteligentnie rozstrzygać remisy: np. jeśli mamy dwóch graczy z którymi mamy 100% zwycięstw razem w drużynie to wyżej chce tego z którym mam więcej together_matches, ale gdy szukam "najgorszego przeciwnika " i jest dwóch z którymi mam 80% porażek to wtedy chce patrzeć na warunki remisu względem vs_matches


---
MATCHES STATS

stworzona migracja:
get_match_win_probability(p_match_id uuid)
```
returns table (
  team_id uuid,
  win_probability numeric
)
```
domain:
Match: dodać pole homeWinProbability (double od zera do jeden)
* opcjonalne property z awayWinProbability = 1 - homeWinProbability

matchRepository:
getMatchWinProbability()

infra: wywołujemy metodę z rpc

application:
createMatchUse Case : trzeba pamiętać o wywołaniu getMatchWinProbability i zapisaniu rezulatu w bazie 

updateMatch Teams - przy zmianie składów również trzeba ponownie wywołać getMatchWinProbability i zapisać rezulat w bazie 


presentation:

widgety:
probabilitySlider: przyjmuje 3 parametry: homeColor, awayColor i homeProbability
Slider jest nieinteraktywny pokazuje tylko w dwóch kolorach lewa część to home i prawa to kolor away z odpowiednią częścią wypełnienia.
Nad sliderem wyrównany do lewej - intem np 33% i do prawej strony slidera 67% drużyny away.

Całość moze być w jakiejś ramce z ikonką i - od info  po jej kliknięciu pokazuje się popup closable tłumaczący jak to jest liczone.
---
DRAFT STATS

stworzona migracja:
get_player_pair_win_rates(p_player_ids uuid[])
```
returns table (
  player_id uuid,
  opp_player_id uuid,
  win_rate numeric
)
```
Po wybraniu graczy do draftu przy okazji przejścia do draft resutls page chcemy wywołać dodatkową metodę która zwróci nam taką oto listę, macierz relacji między graczami.

Na jej podstawie dynamicznie po stronie klienta obliczamy szanse na zwycięstwo home teamu dla danego draft result.
Robimy to za każdym razem i po każdej aktualizacji składów (user może przeciągać graczy, więc ten percentage będzie się ciągle zmieniać)

domain:
HeadToHeadWinRate klasa mapująca zwrotkę z db
draftRepostiory: 
get_player_pair_win_rates(p_player_ids uuid[]) => list<HeadToHeadWinRate>
infra:
robi call do rpc metody na backendzie.
application:
przy KAŻDYM zaktualizowaniu drużyn trzeba wywołać usecase biorący nowe wartości winrate .

presentation:
wyświetlamy **probabilitySlider**
Ten widget powinien się regularnie aktualizować - super gdyby to działo się przez animacje rzesunięcia slidera, przejścia z jednego procentu do drugiego
---

PLAYER MATCHES

matchRepository: getMatches(list<matchId>)

getPlayerMatchesUseCase: -> list<matches>
1. getPlayerRankingHistory
2. odfilutrowujemy do rekordów w których match id != null
3. pobieramy listę meczy 

presentation:

używamy matchTile

page squads/:squadId/players/:playerId/matches

wyświetla identycznie widok jak matchespage tylko ładujemy ją innymi danymi meczami

---