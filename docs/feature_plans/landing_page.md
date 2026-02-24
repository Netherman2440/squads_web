pickteams.pl 

LANDING PAGE 

Rzeczy które chciałbym zawrzeć. Informacje, albo raczej wektor emocjonalny który odbiorca ma zrozumieć.

Catchy tytuł

Na podstawie sekcji wydzielonej poniżej - gdzie opisuję trochę idee tego porjektu chce żebyś wyciągnął dwie rzeczy:
1. Jakiś catchy phrase, coś lepszego zamiast aktualnego "Zbalansowane drużyny w 60 sekund. Bez klotni" , obok dajemy wspomniany niżej widget z draftem.

2. Pierwsza sekcja pod spodem "Dlaczego pickteams.pl?" w której trochę tłumaczymmy sens tego rozwiązania 

---
Problem: "Gdy przychodzisz z kolegami na mecz ktoś musi wybrać składy" - zazwyczaj nikt się nie wyrywa - w końc udwie osoby jak za karę wybierają. Pal licho jeśli dobrze wybrali wtedy tracimy tylko czas, jeśli jednak skłądy są nierówne zabawa jest nieudana, jedna drużyna się nudzi druga frustruje, do tego denerwują się wszyscy na tych którzy wybierali" -- to dla ciebie dla kontekstu, nie tłumacz tego w landing page. 

Rozwiązaniem jest pickteams.pl

To apka webowa która wybierze drużyny za ciebie.

Wystarczy dodać graczy. Oszacować ich ranking i stworzyć pierwszy mecz - gotowe - od razu dostajesz układ. Nie podoba się? Proszę bardzo, dostajesz 20 zestawów wybranych z ponad 50 tysięcy możliwych układów. Wybrane składy były nierówne - inteligentny algorytm aktualizuje rankingi zawodników tak by z czasem składy były jeszcze równiejsze. 
---

Jak to działa? (chce taką nazœe sekcji ale ten opis pod spodem bym jakoś inaczej dał, zdecydowanie nie podoba mi się w takiej długiej formie i też dużo tam uproszczeń)

Algorytm najpierw tworzy ogromną liczbę kombinacji układu zawodników. Sprawdza na prawdę wiele zakamarków, równiez układy o których człowiek by nie pomyślał. Następnie wybiera 20 najlepszych zestawów i zwraca je użytkownikowi. Algorytm (nie wszystko jeszcze dodałem) bierze pod uwagę za równo pozycje zawodników, ich aktualną formę, oraz relacje (jeden zawodnik nie chce byc z drugim, a ten musi być razem) - dodatkowo algorytm bierze też nie tylko sumaryczną wartość całej drużyny pod uwagę. Świetnie sprawdza się przy nierównych drużynach meczach ze zmiennikiem. No i też biorę pod uwagę odchylenie standartdowe więc raczej nie ma takich sytuacji że jedna drużyna jest zbalansowana a druga ma tylko jednego dwóch dobrych grajków i reszta jest słabych,  Wszystko w ułamkach sekund, dostępne w każdej chwili. 

Najważniejsze funkcje 

- Draft wielu zestawów meczy 
- Zrownoważone składy
- aktualizowane rankingi zawodników
- śledzenie postępu wyników i statystyk

Pick Teams w liczbach:
- aktualna liczba graczy:
-liczba rozegranych meczy:
- liczba aktualizacji rankingów: 

wszystkie te liczby pobieramy normalnie z db jako count. na całych tablicach players matchest i rankinh history. Fajnie jakby te liczby się animowały od zera do tej liczby gdy użytkownik do tego pierwszy raz doskroluje.

---

tyle odnośnie treści. Zastanawiam sie też nad grafikami. Potrzebujemy ich kilku:

1. Wizualizacja sprawiedliwego draftu: - pokazywana gdzieś na górze 
 Możesz wzorować się na draft resutls page. Ważne żeby uchwycić to że składy są równe, mamy wiele opcji i ogólnie że bije z tego inteligencja systemu. Że to jakiś zajebisty algorytm przerobił -

2. Wizualizacja zmiany rankingu - Tutaj świetnie nada się coś w stylu app/lib/features/players/presentation/widgets/ranking_history_graph_widget.dart
Ważne żeby pokazać właśnie nazwę gracza i jak fajnie się zmienia ranking. Pokazywana może przy "Jak to działa" 

--

DOdatkowo fajnie by było jeśli każda z tych sekcji "Wjeżdżała od dołu" gdy użytkownik skroluje