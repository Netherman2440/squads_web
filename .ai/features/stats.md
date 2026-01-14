 
›Dodajmy stronę squads/squadId/stats. Chciałbym tam w formie przejrzystej listy wyświetlić statystyki. Każda statystyka to oddzielny tile, każdy tile
  ma do lewej ułożony tekst a po prawej stronie ma wartość statystyki. Wartość to po prostu tekst bo różnie to będzie więc trzeba sparsować. Wszystkie
  dane jakie będziemy wyświetlać są do pobrania za pomocą wzięcia listy graczy i listy meczów - na tej podstawie będziemy hardcodować tile:
Zhardocodowana lista statystyk: (moze też jako oddzileny enum żeby to łatwo ustawiać)
enum wyraz | opis statystyki | jak to obliczyć | jak to wyświetlić ( tile niech przyjmuje string a my tutaj decydujmy)
top_player: najlepszy gracz | biggest ranking | nazwa gracza i ranking
worst_player: najgorszy gracz | smallest ranking | nazwa gracza i ranking
top_Rising_start | Wschodząca gwiazda (gracz z największą change od base score) | nazwa gracza i ta change
liczba meczy
total goals | Liczba strzelonych bramek | suma matches.home score + away score wszystkich meczy | int
total home goals | wiadomo co 
total away goals
avg goals per match
avg wynik 
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

-----
MATCH STATS: TODO

