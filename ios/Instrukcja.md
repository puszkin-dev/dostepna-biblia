# dostępna biblia — iPhone

Na dole jest pięć kart: Liturgia, Czytaj Biblię, Losuj cytat, Wyszukaj i Ustawienia. Przesunięciem jednym palcem w prawo lub lewo znajdź kartę, a dwukrotnym stuknięciem otwórz ją. Po powrocie na kartę pozostajesz w miejscu, w którym ją opuszczono.

**Liturgia.** Miesiąc, dzień i rok to trzy osobne systemowe koła. Przesuwaj jednym palcem w górę lub w dół, aby zmienić wartość, a w prawo, aby przejść do następnej regulacji. Krótszy miesiąc skraca listę dni. Kolejny suwak wybiera część liturgii bez otwierania menu. „Czytaj” otwiera tekst. „Zapisz do TXT” działa również bez wcześniejszego czytania.

Przy systemowych rozmiarach tekstu z kategorii dostępności zamiast trzech kół obok siebie pojawiają się trzy suwaki jeden pod drugim. Kolejność i gesty VoiceOver pozostają takie same.

**Czytaj Biblię.** Wyreguluj testament, księgę, a po pobraniu listy — rozdział. „0 — Wstęp” oznacza wprowadzenie do księgi. „Zapisz do TXT” zapisuje wybrany rozdział. Nie ma eksportu całej Biblii.

Gdy źródło podaje numery wersetów, w czytniku działa przycisk „Przejdź do wersetu”. Otwiera listę numerów z początkiem tekstu; wybranie wiersza przenosi do wskazanego miejsca bez ponownego pobierania. Wstępy bez numerowanych wersetów nie pokazują tego przycisku.

**Czytaj na głos.** Otwórz tekst, a następnie wybierz „Czytaj na głos” nad treścią. Ten sam przycisk pozwala wstrzymać mowę i wznowić ją od miejsca zatrzymania. Obok niego pojawiają się „Czytaj od początku” i „Zatrzymaj czytanie”. Liturgia, psalm, rozdział, wstęp, wylosowany cytat i wyniki korzystają z tego samego czytnika. Tekst jest pobierany z internetu, ale mowa powstaje na iPhonie. VoiceOver nie musi być włączony. Zmiana karty lub zamknięcie tekstu kończy odczyt; samo przejście na ekran początkowy nie zamyka czytnika. Po przerwaniu przez system lub odłączeniu aktywnych słuchawek aplikacja nie wznawia mowy samoczynnie na głośniku.

**Ustawienia.** Na piątej karcie wybierz głos, szybkość (11 kroków, domyślny jest szósty) i głośność (co 10 procent). Wszystkie trzy suwaki zmieniasz jednym palcem w górę lub w dół z VoiceOver. Polskie głosy są na początku; dostępność zależy od tego, co system udostępnił syntezatorowi. „Odsłuchaj próbkę” pozwala sprawdzić wybór, a reset syntezy nie zmienia wyglądu. W „O programie” są autorzy, wersja, kompilacja, źródła i odnośniki.

**Wielkość tekstu.** Na karcie Ustawienia wybierz sekcję „Wygląd i dostępność”. Skrót z literami przy nagłówkach czterech kart treści oraz w czytniku prowadzi do tej samej regulacji. Suwak „Wielkość tekstu Biblii” ma pięć pozycji i podgląd. Standard to druga pozycja. „Przywróć domyślny rozmiar” cofa zmianę. Ustawienie pozostaje po zamknięciu aplikacji. iOS skaluje tekst zgodnie z Dynamic Type tylko raz. Kolorystyka zmienia się razem z systemem.

**Losuj cytat.** Suwakiem wybierz kategorię i użyj przycisku „Losuj cytat”. Wróć z tekstu przyciskiem systemowym lub gestem cofnięcia. „Losuj ponownie” zachowuje kategorię, „Powrót” przywraca jej wybór.

**Wyszukaj.** Wpisz słowo lub frazę, po czym wybierz „Szukaj” na ekranie albo na klawiaturze. Wróć z tekstu, żeby wybrać poprzednią lub następną stronę albo wyeksportować bieżące wyniki. Pusty wynik nie tworzy pliku.

**Czytanie i zapis.** Ekran tekstu jest tylko do odczytu. Możesz czytać ciągiem, korzystać z pokrętła VoiceOver lub zaznaczyć i skopiować fragment systemową funkcją tekstu. „Zapisz do TXT” otwiera systemowy wybór miejsca w Plikach. Plik jest w UTF-8 i pozostaje dostępny bez internetu. Do pobierania nowych tekstów niezbędne jest połączenie z TwojaBiblia.pl. Nie ma konta, reklam, lokalnej bazy całego przekładu ani ustawień wymagających włączenia dostępności w samej aplikacji.

## Kompilacja i dystrybucja

Otwórz `ios/Biblia.xcodeproj`, wybierz schemat Biblia i podłączonego iPhone’a. Zależność SwiftSoup jest przypięta w Package.resolved, nie trzeba regenerować projektu. Minimalna wersja to iOS 17; próby sterowanej mowy korzystają z Xcode i iOS 27. Po zmianie project.yml w katalogu ios wykonaj `xcodegen generate` i dołącz zaktualizowany projekt Xcode. XCTest zawiera oddzielne testy parserów, integracji z serwisem oraz interfejsu. Testy żywego źródła zależą od dostępności i limitów pobrań. Na Windowsie zgodność katalogu z oryginałem sprawdza `python -m pytest ios/Sprawdzenia`.

Dla wydania wybierz **Product → Archive** w schemacie Biblia, a potem **Distribute App** w Organizerze. Wersja aplikacji pozostaje dokładnie **1.0**. Archiwizacja rezerwuje jeden wspólny numer kompilacji aplikacji i targetów testowych. Zwykłe uruchomienie, kompilacja i testy używają ostatniego numeru, bez podbijania. Jeżeli archiwizacja zostanie przerwana już po rezerwacji, jej numer nie wraca do puli.

Skrypt `podbij_build.sh` leży w głównym katalogu repozytorium. Xcode uruchamia go sam. Ręczne uruchomienie również rezerwuje numer; opcja `--obecny` tylko go odczytuje. Licznik jest przechowywany w śledzonym pliku `ios/Build.xcconfig`, wspólnym dla Debug i Release. Nie cofaj tego pliku podczas synchronizacji.

Zespół: `9N975WV782`. Identyfikator: `com.dostepna.biblia`. Do sprawdzania wydania bez wysyłki służy lokalny eksport według `ExportOptions.plist`: zachowuje numer z archiwum. Sama archiwizacja niczego nie publikuje.
