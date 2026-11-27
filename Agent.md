# Zasada commitów

Po utworzeniu lokalnego repozytorium Git dla tego projektu twórz lokalny commit po każdej zmianie, nawet najmniejszej. Każdy commit musi mieć dokładny opis po polsku, który wskazuje, co zostało zmienione.

Po każdym utworzonym commicie wypchnij aktualny stan gałęzi z tym commitem do repozytorium GitHub `puszkin-dev/dostepna-biblia` (zdalne repozytorium `origin`). Potwierdź, że commit dotarł na GitHub.

## Wersjonowanie iOS

Wersja widoczna dla użytkownika zawsze wynosi dokładnie `1.0`. Zmieniaj wyłącznie numer kompilacji. Wszystkie targety iOS dziedziczą tę samą wersję i licznik. W Xcode wystarczą Archive i Distribute App: archiwizacja sama rezerwuje kolejny numer przed podpisaniem. Nie podbijaj go osobno przed Archive. Zachowuj ostatni licznik z `ios/Build.xcconfig` przy synchronizacji Windows–Mac. Nie wysyłaj kompilacji bez polecenia właściciela.

## Wersjonowanie wydań Windows

Przed publikacją każdego nowego wydania zwiększ numer wersji względem ostatniego opublikowanego wydania. Zastosuj nowy numer w metadanych aplikacji, dokumentacji, tagu Git i nazwie paczki. Przed publikacją sprawdź wersję w zbudowanym pliku EXE.

## Kompletność paczki

Każda paczka dla użytkowników musi zawierać aplikację oraz komplet wymaganych bibliotek i komponentów, w tym środowisko uruchomieniowe. Użytkownik ma móc rozpakować paczkę i uruchomić aplikację bez samodzielnego instalowania zależności. Przed publikacją uruchom aplikację z rozpakowanej paczki i sprawdź, czy korzysta z dołączonego środowiska.
