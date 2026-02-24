# Feature Doc Template + Prompt

## Jak uzywac
1. Skopiuj prompt z sekcji **Gotowy prompt**.
2. Podmien tylko placeholdery: `{FEATURE_NAME}` i opcjonalnie `{FEATURE_PATH}`.
3. Daj agentowi ten prompt 1:1.

## Gotowy prompt

```text
Pracujesz w repozytorium squads_web. Twoim zadaniem jest przerobic plan feature na dokumentacje stanu faktycznego implementacji.

Feature do opracowania: {FEATURE_NAME}
Glowna sciezka kodu feature: {FEATURE_PATH} (domyslnie: app/lib/features/{FEATURE_NAME})
Plan feature: docs/feature_plans/{FEATURE_NAME}.md
Doc docelowy: docs/features/{FEATURE_NAME}.md

Kontekst:
- docs/features/ to gotowe dokumenty
- docs/feature_plans/ to plany
- Plan traktuj jako pomocniczy kontekst, NIE jako zrodlo prawdy.
- Zrodlem prawdy jest aktualny kod + migracje SQL.

Wymagany sposob pracy:
1. Przeanalizuj implementacje feature w kodzie (domain/application/infrastructure/presentation).
2. Sprawdz routing w app/lib/core/app_router.dart i miejsca nawigacji do/z feature.
3. Sprawdz baze i RLS:
   - supabase/migrations (tabele, constraints, indeksy, RPC, policy)
   - uwzglednij tylko to, co realnie dotyczy tego feature.
4. Sprawdz punkty styku z innymi feature (use case, repository, provider, widget, RPC).
5. Zamien docs/features/{FEATURE_NAME}.md na dokumentacje "stan aktualny", NIE plan wdrozenia.

Reguly jakosci:
- Nie wymyslaj plikow, endpointow, tabel ani zachowan.
- Nie pisz "zrobimy", "TODO" jako planu; opisuj tylko to, co istnieje.
- Jesli cos jest niezaimplementowane, oznacz to krotko jako "Ograniczenie/status".
- Uzywaj prostego, technicznego jezyka.
- Zachowaj spojny szablon sekcji i numeracje.
- W sekcjach podawaj konkretne nazwy klas/plikow/tras/RPC.

Wymagany uklad dokumentu:

# {FEATURE_NAME} - dokumentacja feature (stan aktualny)
Stan na: <dzisiejsza data>

## 1. Cel i zakres
- Co obejmuje feature biznesowo i technicznie.

## 2. Co jest zaimplementowane
- Wysokopoziomowe elementy
- Stories / sub-features
- Najwazniejsze flow uzytkownika

## 3. Routing
- Trasy feature
- Skad mozna wejsc i dokad prowadzi nawigacja

## 4. DB i RLS (zbiorczo)
- Tabele i kluczowe pola
- Constraints / indeksy istotne dla feature
- RPC/Funkcje SQL uzywane przez feature
- Polityki RLS (kto czyta, kto modyfikuje)

## 5. Architektura
### 5.1 Domain
### 5.2 Application
### 5.3 Infrastructure
### 5.4 Presentation

## 6. Integracje / punkty styku
- Powiazania z innymi feature
- Ktore use case/repo/provider sa wspoldzielone lub wywolywane

## 7. Szybka mapa plikow
- Najwazniejsze pliki w feature
- Najwazniejsze pliki poza feature (router, SQL, integracje)

## 8. Ograniczenia i status (opcjonalnie, ale zalecane)
- Krotko: co jeszcze nie jest gotowe lub jest placeholderem

Wynik:
- Zmien tylko plik docs/features/{FEATURE_NAME}.md
- Na koniec podaj krotkie podsumowanie co zostalo zaktualizowane.
```

## Szybki przyklad uzycia

```text
{FEATURE_NAME} = matches
{FEATURE_PATH} = app/lib/features/matches
```
