# dostępna biblia — iPhone

Na dole są cztery karty: Liturgia, Czytaj Biblię, Losuj cytat i Wyszukaj. Przesunięciem jednym palcem w prawo lub lewo znajdź kartę, a dwukrotnym stuknięciem otwórz ją. Po powrocie na kartę pozostajesz w miejscu, w którym ją opuszczono.

**Liturgia.** Miesiąc, dzień i rok to trzy osobne systemowe koła. Przesuwaj jednym palcem w górę lub w dół, aby zmienić wartość, a w prawo, aby przejść do następnej regulacji. Krótszy miesiąc skraca listę dni. Kolejny suwak wybiera część liturgii bez otwierania menu. „Czytaj” otwiera tekst. „Zapisz do TXT” działa również bez wcześniejszego czytania.

**Czytaj Biblię.** Wyreguluj testament, księgę, a po pobraniu listy — rozdział. „0 — Wstęp” oznacza wprowadzenie do księgi. „Zapisz do TXT” zapisuje wybrany rozdział. Nie ma eksportu całej Biblii.

**Losuj cytat.** Suwakiem wybierz kategorię i użyj przycisku „Losuj cytat”. Wróć z tekstu przyciskiem systemowym lub gestem cofnięcia. „Losuj ponownie” zachowuje kategorię, „Powrót” przywraca jej wybór.

**Wyszukaj.** Wpisz słowo lub frazę, po czym wybierz „Szukaj” na ekranie albo na klawiaturze. Wróć z tekstu, żeby wybrać poprzednią lub następną stronę albo wyeksportować bieżące wyniki. Pusty wynik nie tworzy pliku.

**Czytanie i zapis.** Ekran tekstu jest tylko do odczytu. Możesz czytać ciągiem, korzystać z pokrętła VoiceOver lub zaznaczyć i skopiować fragment systemową funkcją tekstu. „Zapisz do TXT” otwiera systemowy wybór miejsca w Plikach. Plik jest w UTF-8 i pozostaje dostępny bez internetu. Do pobierania nowych tekstów niezbędne jest połączenie z TwojaBiblia.pl. Nie ma konta, reklam, lokalnej bazy całego przekładu ani ustawień wymagających włączenia dostępności w samej aplikacji.

## Kompilacja i dystrybucja

Otwórz `ios/Biblia.xcodeproj`, wybierz schemat Biblia i podłączonego iPhone’a. Zależność SwiftSoup jest przypięta w Package.resolved, nie trzeba regenerować projektu. Minimalna wersja to iOS 17; próby sterowanej mowy korzystają z Xcode i iOS 27. Po zmianie project.yml w katalogu ios wykonaj `xcodegen generate` i dołącz zaktualizowany projekt Xcode. XCTest zawiera oddzielne testy parserów, integracji z serwisem oraz interfejsu. Testy żywego źródła zależą od dostępności i limitów pobrań. Na Windowsie zgodność katalogu z oryginałem sprawdza `python -m pytest ios/Sprawdzenia`.

Dla wydania wybierz w Xcode archiwizację schematu Biblia. ExportOptions.plist wskazuje dystrybucję App Store Connect, ale z **lokalnym eksportem**, nie wysyłką. Zespół 9N975WV782, identyfikator com.dostepna.biblia. Dla kolejnej kompilacji przeznaczonej do wysłania należy użyć niewykorzystanego numeru kompilacji. Stan rzeczywistych testów i artefaktów podaje raport zadania.
