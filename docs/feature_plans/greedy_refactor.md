Zgodnie z combinatory algoritm chcemy zmienić również greedy algorytm.

Założenia są podobne:

1. Użytkownik chce dzielić daną pulę graczy na więcej równych drużyn niż tylko dwie .

2. Użytkownik chce aby przy wyborze były brane pod uwagę pozycje zawodników.

3. Użytkownik chce móc zdecydować że jacyś zawodnicy muszą być razem w składzie a inni muszą być przeciwko sobie

---

ostateczna wersja do której doszlimy jest taka że używamy rankingów z wagami, szczegóły w @draft.md i w @app/lib/features/draft/infrastructure/repositories/combinatory_draft_repository.dart

Problem z tym rozwiązaniem jest taki że bardzo szybko przebijamy racjonalną liczbę sprawdzanych rozwiązań. (przy 22 graczach z podziałem na dwie drużyny to 300k opcji do sprawdzania, przy 15 graczach na 3 drużyny to już 700k operacji - to trochę za dużo)

Dlatego pomysłem rozwiązującym ten problem jest podejście greedy które zżera stałą liczbę operacji, oto algorytm do którego doszedłem

1. Random seed (jeden na cały proces, można go zapisać w draft payload potem)

2. Każdy zawodnik ma swój ranking i wagę (waga może się zmieniać w danej puli względem drużyny do której idziemy)
Bazowo (z combinatory)
 waga powtarzającej się pozycji = 100
 waga niespełnionej reguły = 100
 waga normalnego gracza = 1

do danej drużyny nie może trafić więcej LICZBY zawodników niż ustalona liczba (waga może przewyższać, ale jeśli mamy 15 zawodników i dzielimy ich na dwie drużyny to NA SZTYWNO  pierwsza drużyna ma więcej graczy a pozostałe mają mieć równo czyli tutaj pierwsza - limit 8, druga limit 7) gdy ten limit jest osiągnięty algorytm pomija te drużyny

3. Losowe ustawienie [pozostałych] zawodników (ustawiamy ich w arrayu losowo)
4. Wybieramy pulę graczy (do dostrojenia ilu tych graczy ma być, ale to jest od 1 do players.count) - to ma być na razie parametr int którym sobie będę edytował.

5. Z tej puli graczy GREEDY wybieramy najlepszy wybór dla najbliższej drużyny:

jeśli możemy dodać gracza (liczba graczy w drużyne < limit)

staramy się wybrać najlepsze ratio ranking/waga, 

po dodaniu przechodzimy do następnej drużyny i powtarzamy kroki 2 - 5 

----

po zakończeniu powinniśmy otrzymać 1 zestaw drużyn. Aby otrzymać ich więcej trzeba znowu wszystkich graczy ustawić w losowej kolejności (według tego samego seeda) i powtórzyć kroki 2 - 5 aż do opróżnienia puli. Robimy tak aż dojdziemy do int maxIterations (również do dostrojenia ten parametr)


WAŻNE: w jaki sposób dynamicznie zmieniają się wagi? 

Przed każdym wyborem do drużyny od nowa ustalamy wagi dla danej puli, dana pula może mieć różne wagi względem różnych drużyn,,
PRZYKŁADY:

drużyna A nie ma bramkarza

w puli [bramkarz (ranking 60)] - będzie miał wagę 1

--

druzyna B ma bramkarza, ponadto ten bramkarz z puli znajduje się w DraftRule (against) (opis w draft.md) a tak się złożyło że w tej drużynie już znajduje się drugi zawodnik z tej relacji

zatem jego ostateczna waga to:

1 + 100 (w składzie występuje bramkarz) + 100 (niespełniona reguła against)

--

drużyna C ma już dwóch bramkarzy, a  bramkarz z puli jest w regule typu together - reguła na razie nie jest spełniona - inni gracze z reguly nie zostali wybrani :

waga =
1 + 2 (ilość bramkarzy)*100 + 0(reguła jeszcze może zostać spełniona)


--

czyli podsumowując przy ocenie wagi danego awodnika bierzemy pod uwagę cały aktualby stan draftu 
przy ocenie reguł - jeśli jakaś reguła może zostać jeszcze spełniona to nie dajemy za tę regułę kary. 

jak oceniamy czy reguła może zostać spełniona przy większej liczbie drużyn? 

jeśli trzej gracze mieli być razem a na razie tylko jeden jest wybrany to przydzielenie nowego gracza do innej drużyny doda wage za niespelniona regule

wiec noramlnie

----


z całości  algorytmu podobnie jak w conbinatory wyciągamy top 20 układów i te zapisujemy, wszystko na zewnątrz jest tak samo, fajnie by było sprawdzić czy testy przechodzą również dla tej implementacji 