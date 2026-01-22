## Stories (zrodlo: `docs/prd.md`, `docs/ui_plan.md`, brief produktu)

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

###  Widok turnieju
- Routing: `/squads/:squadId/tournaments/:tournamentId`.
- Widok zawiera: liste druzyn (aktualne sklady), historie meczow i prosta tabele wynikow.
- Dane sa tylko do odczytu dla member/guest; edycje tylko dla owner/admin.

###  Edycja druzyn turniejowych
- W widoku turnieju owner/admin moze edytowac nazwe, kolor i sklad druzyn (dodawanie/usuwanie/zamiana zawodnikow).
- Edycja druzyn jest dozwolona takze po wpisaniu wynikow meczow.
- Zmiany skladu druzyn turniejowych nie zmieniaja historycznych skladów w juz rozegranych meczach; nowe mecze uzywaja aktualnych skladów.

### Dodawanie meczu turniejowego i wynik
- W widoku turnieju owner/admin moze dodac mecz, wybierajac dwie druzyny z turnieju.
- Uzytkownik wpisuje wynik meczu (home/away + opcjonalne metadane).
- Mecz pojawia sie w historii turnieju, a tabela wynikow aktualizuje sie po zapisie.
- Wynik turniejowy wplywa tylko na zawodnikow bioracych udzial w danym meczu.
