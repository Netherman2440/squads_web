 

DB:

Utworzone migracje z metodami:

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

get_match_win_probability(p_match_id uuid)
```
returns table (
  team_id uuid,
  win_probability numeric
)
```

get_player_pair_win_rates(p_player_ids uuid[])
```
returns table (
  player_id uuid,
  opp_player_id uuid,
  win_rate numeric
)
```

Trzeba stworzyć jeszcze migrację do :
get_squad_stats(squad_Id)

ta metoda ma zwracać:
top_player: najlepszy gracz | biggest ranking | nazwa gracza i ranking
worst_player: najgorszy gracz | smallest ranking | nazwa gracza i ranking
top_Rising_star | Wschodząca gwiazda (gracz z największą change od base score) | nazwa gracza i ta change
liczba meczy
total goals | Liczba strzelonych bramek | suma matches.home score + away score wszystkich meczy | int
total home goals | wiadomo co 
total away goals
avg goals per match
avg wynik (avg hove : avg away)
liczba graczy
avg player score

---



Squad Stats:
DOMAIN:
Klasa Squad Stats (odwzorowuje listę Statystyk)

squad_repository: getSquadStats() -> wywołuje sql.get_squad_stats()

--
* match - dodać pole class Probability(ctor with homeinProbability ) {
  homeinProbability, (0 <= 1)
  awayWinProbability = 1 - homeinProbability
}

* match repository - dodać calculate_match_win_probability 
 
--

Dodajmy stronę squads/squadId/stats. Chciałbym tam w formie przejrzystej listy wyświetlić statystyki. Każda statystyka to oddzielny tile, każdy tile
  ma do lewej ułożony tekst a po prawej stronie ma wartość statystyki. Wartość to po prostu tekst bo różnie to będzie więc trzeba sparsować. Wszystkie
  dane jakie będziemy wyświetlać są do pobrania za pomocą wzięcia listy graczy i listy meczów - na tej podstawie będziemy hardcodować tile:
Zhardocodowana lista statystyk: (moze też jako oddzileny enum żeby to łatwo ustawiać)
enum wyraz | opis statystyki | jak to obliczyć | jak to wyświetlić ( tile niech przyjmuje string a my tutaj decydujmy)
top_player: najlepszy gracz | biggest ranking | nazwa gracza i ranking
worst_player: najgorszy gracz | smallest ranking | nazwa gracza i ranking
top_Rising_star | Wschodząca gwiazda (gracz z największą change od base score) | nazwa gracza i ta change
liczba meczy
total goals | Liczba strzelonych bramek | suma matches.home score + away score wszystkich meczy | int
total home goals | wiadomo co 
total away goals
avg goals per match
avg wynik (avg hove : avg away)
liczba graczy
avg player score

----

strona do app routera pod składem oczywiście i podpinamy też do squad shella 


------

w player details też dodajemy subpage players/playerId/stats

W środku potrzebujemy: 

player, 

list ranking history

na tej podstawie możemy też mieć list<matches> gdzie brał udział gracz
najlepiej żeby ta lista meczy była od razu wzbogacona o teams, tak na prawdę na tej podstawie możemy zdobyć bardzo dużo i wyświetlić najpierw identyczne stat tile:

Base ranking
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


-----
PORÓWNYWARKA PLAYER VS PLAYER
Chciałbym stworzyć wewnątrz statystyk gracza Relację do wszystkich innych graczy z którymi zdarzyło mu się grać.
Mamy swoje player Id, mamy listę naszych rozegranych meczy. Te mecze zawierają wynik i drużyne
Dla każdego gracza chciałbym policzyć statystyki jakie nas dwóch łączą:
liczba meczy gdy jesteśmy razem w drużynie 
liczba zwycięstw, liczba porażek, liczba remisów (gdy jesteśmy razem)
liczba goli strzelonych, liczba goli straconych (gdy jesteśmy razem)
--
liczba meczy gdy jesteśmy przeciwko sobie
liczba MOICH zwycięstw, liczba porażek, liczba remisów (gdy jesteśmy przeciwko)
liczba MOICH goli strzelonych, liczba goli straconych (gdy jesteśmy przeciwko)

Decyzja: liczymy statystyki po stronie bazy przez funkcję
public.get_player_head_to_head_stats(p_player_id) i bierzemy tylko mecze z
kompletnym wynikiem (home_score i away_score). DTO: PlayerHeadToHeadStat.
-----
MATCH STATS: TODO

---
PLAYER.MATCHES

Na podstawie ranking history gracza bierzemy wszystki matchIds

Potem matchesClient robi:
```
 final matches = await supabase
    .from('matches')
    .select('*')
    .in_('match_id', matchIds);
```
Do tego potrzebujemy oddzielnej metody getMatches(list<matchIds>) w matchesRepository

