# Zasada commitów

Po utworzeniu lokalnego repozytorium Git dla tego projektu twórz lokalny commit po każdej zmianie, nawet najmniejszej. Każdy commit musi mieć dokładny opis po polsku, który wskazuje, co zostało zmienione.

Prace nad portem iOS prowadź na gałęzi `ios`. Po każdej sprawdzonej zmianie utwórz commit i od razu wyślij go na gałąź `ios` repozytorium `puszkin-dev/dostepna-biblia` poleceniem `git push origin ios:ios`. Porównaj wynik `git rev-parse ios` z `git ls-remote origin refs/heads/ios` i zsynchronizuj lokalne kopie na Windowsie i Macu. Jeśli zdalna gałąź ma nowe commity, pobierz je i zintegruj bez wymuszania zapisu. Nie wypychaj zmian portu do `main`. Ta zasada zastępuje wcześniejszy zakaz wysyłania kodu portu na GitHub; nie dotyczy publikacji aplikacji w usługach Apple.

## Wersjonowanie iOS

Wersja widoczna dla użytkownika zawsze wynosi dokładnie `1.0`. Wszystkie targety iOS dziedziczą tę samą wersję i licznik z `ios/Build.xcconfig`. Dopiero jawne uruchomienie `./podbij_build.sh` na żądanie właściciela zwiększa wspólny numer. Archive nie zmienia licznika. Nie wysyłaj kompilacji do Apple bez polecenia właściciela.

## Wersjonowanie wydań Windows

Przed publikacją każdego nowego wydania zwiększ numer wersji względem ostatniego opublikowanego wydania. Zastosuj nowy numer w metadanych aplikacji, dokumentacji, tagu Git i nazwie paczki. Przed publikacją sprawdź wersję w zbudowanym pliku EXE.

## Kompletność paczki

Każda paczka dla użytkowników musi zawierać aplikację i wszystkie wymagane pliki spoza obsługiwanego systemu Windows. Korzystaj z systemowego .NET Framework 4.8 lub nowszego w celu utrzymania niewielkiej paczki. Użytkownik obsługiwanej wersji Windows ma móc rozpakować paczkę i uruchomić aplikację bez instalowania dodatkowych zależności. Zapisuj nazwy plików w ZIP-ie w UTF-8. Przed publikacją rozpakuj paczkę w Windows i sprawdź uruchomienie programu.
