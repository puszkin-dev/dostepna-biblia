# Zasada commitów

Po utworzeniu lokalnego repozytorium Git dla tego projektu twórz lokalny commit po każdej zmianie, nawet najmniejszej. Każdy commit musi mieć dokładny opis po polsku, który wskazuje, co zostało zmienione.

Prace nad portem iOS prowadź na gałęzi `ios`. Po każdej sprawdzonej zmianie utwórz commit i od razu wyślij go na gałąź `ios` repozytorium `puszkin-dev/dostepna-biblia` poleceniem `git push origin ios:ios`. Porównaj wynik `git rev-parse ios` z `git ls-remote origin refs/heads/ios` i zsynchronizuj lokalne kopie na Windowsie i Macu. Jeśli zdalna gałąź ma nowe commity, pobierz je i zintegruj bez wymuszania zapisu. Nie wypychaj zmian portu do `main`. Ta zasada zastępuje wcześniejszy zakaz wysyłania kodu portu na GitHub; nie dotyczy publikacji aplikacji w usługach Apple.

## Gałąź `main` Grzegorza — tylko do odczytu

Nigdy nie zmieniaj lokalnej ani zdalnej gałęzi `main`: nie zapisuj na niej zmian, nie przesuwaj jej, nie usuwaj i niczego do niej nie wysyłaj ani nie scalaj. Dotyczy to również osobnego katalogu roboczego Windows. Do odczytu nie trzeba przełączać gałęzi.

Przed planowaniem lub implementacją kolejnej funkcji iOS, pozostając na `ios`, odśwież wyłącznie lokalny podgląd zdalnej gałęzi: `git fetch --no-tags origin refs/heads/main:refs/remotes/origin/main`. Porównaj ostatni sprawdzony commit z `origin/main` za pomocą `git log` i `git diff`. Sprawdzaj nie tylko nowe funkcje, ale też poprawki zachowania, dostępności oraz zmiany źródeł danych istotne dla portu. W podsumowaniu pracy zapisz sprawdzony hash i wynik. Zmiany istotne dla bieżącej funkcji odwzoruj natywnie na `ios`; pozostałe wskaż jako kandydatów na później. Nie scalaj automatycznie `main` z `ios`.

Punkt odniesienia po PR nr 1: `acf8194` (Windows 1.1.3; liturgia Narodzenia Pańskiego, Wielkiej Soboty i komunikaty wigilijne).

## Orientacja podczas testów iOS

Nie przełączaj systemowej blokady orientacji na iPhonie właściciela w celu wykonania testu. Gdy potrzebny jest poziom, zadaj orientację w teście i potwierdź rzeczywisty układ okna. Jeśli iOS pozostaje w pionie, sprawdź poziom na symulatorze i rozróżnij w raporcie oba wyniki. Test niezwiązany z obrotem nie wymaga zmiany blokady.

## Wersjonowanie iOS

Wersja widoczna dla użytkownika zawsze wynosi dokładnie `1.0`. Wszystkie targety iOS dziedziczą tę samą wersję i licznik z `ios/Build.xcconfig`. Dopiero jawne uruchomienie `./podbij_build.sh` na żądanie właściciela zwiększa wspólny numer. Archive nie zmienia licznika. Nie wysyłaj kompilacji do Apple bez polecenia właściciela.

## Wersjonowanie wydań Windows

Przed publikacją każdego nowego wydania zwiększ numer wersji względem ostatniego opublikowanego wydania. Zastosuj nowy numer w metadanych aplikacji, dokumentacji, tagu Git i nazwie paczki. Przed publikacją sprawdź wersję w zbudowanym pliku EXE.

## Kompletność paczki

Każda paczka dla użytkowników musi zawierać aplikację i wszystkie wymagane pliki spoza obsługiwanego systemu Windows. Korzystaj z systemowego .NET Framework 4.8 lub nowszego w celu utrzymania niewielkiej paczki. Użytkownik obsługiwanej wersji Windows ma móc rozpakować paczkę i uruchomić aplikację bez instalowania dodatkowych zależności. Zapisuj nazwy plików w ZIP-ie w UTF-8. Przed publikacją rozpakuj paczkę w Windows i sprawdź uruchomienie programu.
