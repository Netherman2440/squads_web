#Wysokopoziomowa idea Invite links:
w pliku @app/lib/features/squads/presentation/pages/squad_settings_page.dart  mamy sekcję zaproszeń 
Chciałbym zaimplementować feature który będzie spełniał poniższe User stories:

Jako admin chce móc wygnerować działający link z zaproszeniem do składu 


Jako użytkownik gdy kliknę w ten link zostaje dodany do składu (nowy wpis w talibcy user squads z rolą member)

Jako użytkownik jeśli nie jestem zalogowany w aplikacji a kliknąłem w link jestem przenoszony na auth page. Po zalogowaniu / utworzeniu konta automatycznie dodawany jest mi nowy skład.

---

Jak chciałbym to zrobić:

W DB chce mieć nową tablicę `invite_links`:
`code`: string
`squad_id`: string
`created_at`: datetime
`valid_until`: datetime

- limit jeden wpis per squad id 

1. admin generuje nowy `code` 
2. wykonuje się upsert na bazie , 
3. tworzymy link z zaproszeniem:
`adres-prod.com/code?={KOD Z DB}`
4. przy wejściu na domenę ten link zapisuje się w pamięci tymczasowej 

5. po zalogowaniu jeśli kod z pamięci != null
5.1 wykonujemy flow dołączania do składu podając ten kod 
6. usuwamy kod z pamięci podręcznej

--
obsługa casu gdy już jesteśmy w danym skłądzie
poprawna obsługa braku dostępu (przekierowanie na login)
obsługa niepoprawnie wpisywanych kodów (komunikat - kod jest niepoprawny lub wygasł)

----
##implementacja:

###DB:
`invite_links`:
`code`: string
`squad_id`: string
`created_at`: datetime
`valid_until`: datetime
---
###domain:
entity:
InviteLink (mapowanie db)

InviteLinksRepository:
-createInviteLink(squadId, code, jak długo ma być valid) //created at ustawia repo, 
- getInviteLink(squadId) => for seetings page to show result from db mem

SquadRepository:
now metoda:
joinSquad(string code) (na podstawie auth weryfikujemy kod i user id), dodajemy rekord member (bez opcji wyboru admin czy inncyh ról) do tablicy user squads
-getSquadByCode(string code) => returns Sqaud, for checking if code is valid

###Infrastructure:
SupabaseInviteLinksRepostiory:
z użyciem supabase jak wszędzie



###Application:
generateInviteLink(linkRepo) : create uuid,, appconfig przechowuje info o tym jak długo link ma być valid - bazowo to godzina, przekazuje wszystkie parametry do repo, zwraca obiekt klasy InviteLink

getSquadInviteLinkUsecase(linkRepo): dla settings page, jeśli instieje valid link to go zwraca, jeśli istnieje rekord w bazie ale jest nieaktualny to zwraca null

joinSquadUseCase(sqaudRepo, linkRepo, tokenRepo?) - logika pobierania z local storage current code, sprawdzania czy istnieje, jeśli tak to dodawanie roli member do squadu ( jak to potem ogarnąć w rlsie, żeby taki gostek 'z ulicy' mial dostep do db tego składu)


//skąd brać lokalnie zapisany token Może z token Repository? Może trzeba dodac pole squadCode do authEntity i od razu je aktualizować przy pojawieniu się go w linku albo przy poprawnym dołączeniu do składu to może chcemy go od razu potem usunąć? Jeśli tak to potrzebujemy w tokenRepostiory też metod do tego


###Presentation

Tu UI już jest stworzone, dodam tylko że jeśli link jest invalid to możeme od razu go nie pokazywać tylko samo 'Geneate invite link'