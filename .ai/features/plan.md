Stwórzmy plan implementacji featuru draft + matches +score history
References:

DB:
 @.ai/db_plan.md:147-228 
UI:
@.legacy/frontend/lib/pages/draft_page.dart @.legacy/frontend/lib/pages/match_history_page.dart @.legacy/frontend/lib/pages/player_detail_page.dart 
--
Stories:
 @prd.md (119-197) 


Jest to kluczowy zestaw featuruów dla tej aplikacji. Na pewno nie będę chciał żebyś wszystkiego tego implementował na raz. Zamiast tego utworzymy trzy plany implementacji stories.

Rezultat zapiszemy w 3 plikach:
@.ai/features/matches.md @.ai/features/score_history.md  i @.ai/features/draft.md 
W utworzonym planie nie zaponij o załączeniu kontekstu do wyzej wspomnianych potrzebnych akurat dokumentów.

Do spełnienia powyższych stories potrzebujemy konrketnych komponentów, spróbuję podytkować ci to jak widzę każdy z tych dokumentó. W oparciu o załączony kontekst zredaguj odpowiednio moje notatki i zapisz w tych plikach.

Do wszystkich featurów też staramy się warstwę prezentacji i usecasów robić w podobny sposób:
strony raczej są bez stanowe a zawratość kontent przekazujemy im przez riverpoda. Zazwyczaj będą to async wartości więc wszędzie staramy się używać Async Value z Async Guardem.
przykład:

@app/lib/features/players/presentation/controllers/players_notifier.dart 
Notifiery mają dostęp do use casów a use casy dopiero wywołują repozytoria. 

Matches:

domena:
class match:
matchid
squad id
tournament id
score type enum ('regular','penalties','walkover','cancelled')
home score away score
score meta (dict)
home_team: Team
away_team: Team

team:
team_id
match_id
side (
name
color
list<MatchPlayer>

matchplayer:
match_id
team_id
player_id
score
name

match repostiory z metodami :
createMatch ( home team, away team) => match
deleteMatch(id) => void
updateMatch(tuple[teams]? score?) => match
get_matches(squad_id) => list<match>
get_match(matchid) => match

infra w oparciu o supabase, na razie ignroujemy rlsy. 

presentation:
Chciałym w miarę możliwości odtworzyć legacy UI.
/matches
chce mieć reużywalne widgety match tile
taki tile zawiera datę meczu i wynik 
plus widoczny tylko dla uprawnionych
/matches/create

wykorzystujemy a)legacy draft page b) stworzony playertile widget
mamy dwie listy 
available players i selected players. do available players mamy też wyszukiwarkę. Co ważne - trzeba tu rozróżnić wyświetlanie - na wąskich ekranach dajemy te listy pod sobą - na górze selected ana dole available (obie skrolowalne) a na szerokich z lewej mamy available a z prawej selected

na pasku mamy nawigację 'Draft' która akceptuje wybranych graczy

Usecasy wołane z naszych pagy:
GetSquadMatches
CreateMatch
DeleteMatch
UpdateMatchScore
UpdateMatchTeams
UpdateTeamColor
Redraw
Rematch


---
Draft

zacznę od tego naczym skończym poprzedni dok:
presentation

/matches/draft
w oparciu o legacy draft page or create match page
- wyświetla na raz jedną propozycje meczu - dwie skrolowalne listy obok siebie ze składamiobu drużyn. nad nim wyświetlany jest zsumowany score wszystkich graczy z kolumny. Nad całą tą sekcją mamy prostą nawigacje ze strzałkami lewo prawo do przechodzenia do kolejnej propozycji. Przejście resetuje zmiany użytkownika do tego co mamy zaproponowane w drafcie.

Użytkownik może swobodnie na tych drużynach operować - może przeciągać graczy z jednej kolumny do drugiej. Może przechodzić do kolejnych propozcyji

Na pasku ma przycisk 'Create Match' który wywoła metodę z poprzednio utworzonego repozytorium match repository - ta metoda oczywiście bierze w create stan aktualny obu kolumn a nie wynik samego draftu który mógł ulec zmianie przez użytkownika.

domena:
Draft
list<MatchPlayer> home_team
list<MatchPlayer> away_team

draft_repository:
get_draft(list<player>) => list<draft>

infra:
Uwaga - NIE TWORZYMY DB draftów. Jest to tymczasowy obiekt na przechowywanie najlepszych obliczonych kombinacji. 

PONAD TO: 
NA RAZIE REZYGNUJEMY Z LOSOWYCH DRUŻYN. nie używamy wgl czegoś takiego jak seed. Oczekiwana implementacja będzie działała w taki sposób:
Dla podanej liczby graczy
tworzymy wszystkie możliwe kombinacje tychże graczy.
Wybieramy najlepsze zestawy (to znaczy dwie drużyny najbardziej do siebie zbliżone sumarycznym score)
zwracamy top 20 draftów.

ta infra może być na razie zmockowana, możemy podzielić po prostu zawodników na 2 drużyny i zwrócić mniej draftów. Bardziej chodzi o to żebyś złapał koncept.

usecasy do stworzenia:
CreateDraft(list players)

---

score history:
jest to poniekąd powiązany feature z meczami.

Chodzi o to by po każdym meczu aktualizować score graczy którzy brali udział w meczu.

Dla przykładu drużyna A wygrała 2 bramkami więc score wszystkich zawodników z drużyny A skacze o 2 a zawodników z drużyny B spada o 2. Tak to działa w uproszczeniu. Żeby zachować w odizolowaniu historię meczy jednego zawodnika dodajemy specjalną tablicę score history.

presentation:
-- na razie nic, w przyszłości będziemy wyświetlać to przy okazji player details.--

domena:
class scorehistory:
score_history_id
player_id
match_id
delta
previous_rating
new_rating
match_score: tuple [ player score : enemy team score ] 


teraz mi się wydaje że to powinno polecieć do featuru players... 
tak zróbmy to do feature players, ale jako oddzielny doc.

W player repository dodajmy dodatową metodę update player match score (match id, delta, player team score, enemy team score) => void - to aktualizuje score gracza w score history. 

ALE UWAGA WŁAŚNEI BO  przecież w legacy juz wiem co robiliśmy - przechowywaliśmy faktycznie player.score, ale przy dodawaniu elementu do player score history aktualizowaliśmy faktycznie całe player score. WYnika to z tego że mogliśmy zaktualizować wynik meczu starszego. Dlatego potrzebujemy od początku policzyć cały score gracza.