## Opis

Feature "relacje draftu" pozwala definiowac zasady doboru skladow jeszcze przed generowaniem propozycji. Uzytkownik wskazuje grupy graczy, ktorzy musza byc razem, oraz grupy, ktorzy musza byc po przeciwnych stronach (dla meczu lub turnieju). Algorytm draftu musi respektowac te relacje lub zwracac czytelny blad, gdy nie da sie ich spelnic.

## Stories (relacje draftu)

### US-029: Definiowanie relacji "razem" przed draftem
- Po wyborze graczy do draftu widze krok "Razem".
- Mogę dodac relacje "musza byc razem" jako pary, trojki, itp.
- Lista relacji "razem" jest edytowalna (usun/zmien sklad grupy).
- Te relacje sa czescia listy zasad przekazywanej do generowania draftu.
- Ten krok można pominąć

### US-030: Definiowanie relacji "przeciwko sobie" przed draftem
- Po kroku "Razem" widze krok "Przeciwko sobie".
- Dla zwyklego meczu relacja "przeciwko sobie" zawiera tylko 2 graczy.
- Dla turnieju relacja "przeciwko sobie" zawiera tylu graczy, ile jest druzyn.
- Lista relacji "przeciwko sobie" jest edytowalna (usun/zmien sklad grupy).
- ten krok można pominąć

### US-031: Walidacja relacji i konfliktow
- Nie moge dodac gracza do wiecej niz jednej grupy "razem".
- Ten sam gracz nie moze byc jednoczesnie w relacji "razem" i "przeciwko sobie".
- Grupy "przeciwko sobie" nie moga zawierac duplikatow graczy.
- Przy konflikcie widze jasny komunikat i nie moge przejsc do generowania draftu.
- Jest twardy limit graczy będących w relacji przeciwko że liczba graczy w tej relacji nie może przekraczać liczby drużyn

### US-032: Algorytm draftu respektuje relacje
- Draft przypisuje graczy z relacji "razem" do tej samej druzyny.
- Draft przypisuje graczy z relacji "przeciwko sobie" do roznych druzyn.
- Gdy nie da sie spelnic relacji, widze blad i prosbe o korekte zasad.

---
Chciałbym na pewno mieć testy sprawdzające te storki na poziomie UI - czy relacje trafiają do draft repo