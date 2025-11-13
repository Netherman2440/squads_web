# **Squads – MVP**

## **Jaki problem rozwiązuje aplikacja**

W amatorskich rozgrywkach sportowych wybór składów przed meczem jest zwykle źródłem chaosu i sporów.
Zamiast ręcznego wybierania drużyn, **Squads** automatycznie tworzy **zbalansowane składy** na podstawie rankingów graczy.

Aplikacja:

* generuje **wiele propozycji drużyn** dopasowanych pod względem poziomu,
* pozwala **zapisać wynik meczu**, po którym ranking graczy aktualizuje się automatycznie,
* dzięki temu z każdym kolejnym meczem **składy stają się coraz bardziej wyrównane i uczciwe**.

**Rezultat:** szybkie rozpoczęcie gry, brak dyskusji o „niesprawiedliwych składach” i większa satysfakcja wszystkich uczestników.

---

## **Co wchodzi w skład MVP**

* **Konta użytkowników i autoryzacja**
  Rejestracja, logowanie (w tym tryb gościa), role użytkowników oraz obsługa tokenów dostępu i odświeżania.

* **Zarządzanie składami (Squads)**
  Tworzenie, edycja i usuwanie składów; przeglądanie listy składów; zarządzanie członkami i rolami w składzie; dostęp tylko dla zalogowanych użytkowników.

* **Zawodnicy (Players)**
  Dodawanie, edycja i usuwanie graczy; wyświetlanie statystyk; automatyczna aktualizacja rankingu po meczach.

* **Mecze (Matches)**
  Tworzenie meczu na podstawie wybranego draftu, wprowadzanie wyników, aktualizacja statystyk i rankingów.

* **Losowanie zbalansowanych drużyn (Drafting)**
  Generowanie wielu propozycji wyrównanych składów na podstawie rankingów graczy.

* **Statystyki i wyniki**
  Podstawowe statystyki składów i graczy: liczba meczów, bilans zwycięstw/porażek, średnie oceny, trendy.

* **Turnieje (Tournaments)**
  Tworzenie i zarządzanie prostymi turniejami opartymi na meczach między drużynami.

---

## **Co nie wchodzi w skład MVP**

* **Płatne subskrypcje i ograniczenia dostępu**
  Wersja MVP udostępnia wszystkie funkcje bez opłat — każdy użytkownik może tworzyć własne składy.

* **Zaawansowane reguły draftu**
  Brak możliwości definiowania niestandardowych zasad doboru graczy (np. „Krzyś zawsze z Maćkiem”, „Marek przeciwko Andrzejowi”).

---

## **Kryteria sukcesu**

* Użytkownicy stanowią **50% graczy** w składach.
* Co **5** użytkownik tworzy skład.

---
