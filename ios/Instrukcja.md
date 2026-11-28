# dostępna biblia — iPhone

Na dole jest pięć kart: Liturgia, Czytaj Biblię, Losuj cytat, Wyszukaj i Ustawienia. Przesunięciem jednym palcem w prawo lub lewo znajdź kartę, a dwukrotnym stuknięciem otwórz ją. Po powrocie na kartę pozostajesz w miejscu, w którym ją opuszczono.

**Liturgia.** Miesiąc, dzień i rok to trzy osobne systemowe koła. Przesuwaj jednym palcem w górę lub w dół, aby zmienić wartość, a w prawo, aby przejść do następnej regulacji. Krótszy miesiąc skraca listę dni. Kolejny suwak wybiera część liturgii bez otwierania menu. „Czytaj” otwiera tekst. „Zapisz do TXT” działa również bez wcześniejszego czytania.

Przy systemowych rozmiarach tekstu z kategorii dostępności zamiast trzech kół obok siebie pojawiają się trzy suwaki jeden pod drugim. Kolejność i gesty VoiceOver pozostają takie same.

**Czytaj Biblię.** Wyreguluj testament, księgę, a po pobraniu listy — rozdział. „0 — Wstęp” oznacza wprowadzenie do księgi. „Zapisz do TXT” zapisuje wybrany rozdział. Nie ma eksportu całej Biblii.

Gdy źródło podaje numery wersetów, w czytniku działa przycisk „Przejdź do wersetu”. Otwiera listę numerów z początkiem tekstu; wybranie wiersza przenosi do wskazanego miejsca bez ponownego pobierania. Wstępy bez numerowanych wersetów nie pokazują tego przycisku.

**Czytaj na głos.** Otwórz tekst, a następnie wybierz „Czytaj na głos” nad treścią. Ten sam przycisk pozwala wstrzymać mowę i wznowić ją od miejsca zatrzymania. Obok niego pojawiają się „Czytaj od początku” i „Zatrzymaj czytanie”. Liturgia, psalm, rozdział, wstęp, wylosowany cytat i wyniki korzystają z tego samego czytnika. Tekst jest pobierany z internetu, ale mowa powstaje na iPhonie. VoiceOver nie musi być włączony. Zmiana karty lub zamknięcie tekstu kończy odczyt; samo przejście na ekran początkowy nie zamyka czytnika. Po przerwaniu przez system lub odłączeniu aktywnych słuchawek aplikacja nie wznawia mowy samoczynnie na głośniku.

**Ustawienia.** Na piątej karcie najpierw wybierz silnik mowy, potem jego głos. Na liście są wyłącznie zainstalowane głosy, które iOS udostępnia dla języka polskiego. Jeżeli silnik ma jeden głos, jest on już wybrany; pod nazwą silnika odczytasz nazwę głosu bez dodatkowego gestu regulacji. W domyślnym zestawie opcja „Automatyczny” pozostawia wybór aplikacji. Szybkość i głośność ustawiasz od 0 do 100 procent, co 5 punktów; domyślnie odpowiednio 50 i 100. To skala syntezatora aplikacji, nie tempo VoiceOver ani liczba słów na minutę. Każdy suwak zmieniasz jednym palcem w górę lub w dół z VoiceOver. „Odsłuchaj próbkę” pozwala sprawdzić wybór, a reset syntezy nie zmienia wyglądu. W „O programie” są autorzy, wersja, kompilacja, źródła i odnośniki.

**Wielkość tekstu.** Na karcie Ustawienia wybierz sekcję „Wygląd i dostępność”. Skrót z literami przy nagłówkach czterech kart treści oraz w czytniku prowadzi do tej samej regulacji. Suwak „Wielkość tekstu Biblii” ma pięć pozycji i podgląd. Standard to druga pozycja. „Przywróć domyślny rozmiar” cofa zmianę. Ustawienie pozostaje po zamknięciu aplikacji. iOS skaluje tekst zgodnie z Dynamic Type tylko raz. Kolorystyka zmienia się razem z systemem.

**Losuj cytat.** Suwakiem wybierz kategorię i użyj przycisku „Losuj cytat”. Wróć z tekstu przyciskiem systemowym lub gestem cofnięcia. „Losuj ponownie” zachowuje kategorię, „Powrót” przywraca jej wybór.

**Wyszukaj.** Wpisz słowo lub frazę, po czym wybierz „Szukaj” na ekranie albo na klawiaturze. Wróć z tekstu, żeby wybrać poprzednią lub następną stronę albo wyeksportować bieżące wyniki. Pusty wynik nie tworzy pliku.

**Czytanie i zapis.** Ekran tekstu jest tylko do odczytu. Możesz czytać ciągiem, korzystać z pokrętła VoiceOver lub zaznaczyć i skopiować fragment systemową funkcją tekstu. „Zapisz do TXT” otwiera systemowy wybór miejsca w Plikach. Plik jest w UTF-8 i pozostaje dostępny bez internetu. Do pobierania nowych tekstów niezbędne jest połączenie z TwojaBiblia.pl. Nie ma konta, reklam, lokalnej bazy całego przekładu ani ustawień wymagających włączenia dostępności w samej aplikacji.

## Kompilacja i dystrybucja

Otwórz `ios/dostepna biblia.xcodeproj`, wybierz schemat „dostepna biblia” i podłączonego iPhone’a. Zależność SwiftSoup jest przypięta w Package.resolved, nie trzeba regenerować projektu. Minimalna wersja to iOS 17; próby sterowanej mowy korzystają z Xcode i iOS 27. Po zmianie project.yml w katalogu ios wykonaj `xcodegen generate` i dołącz zaktualizowany projekt Xcode. XCTest zawiera oddzielne testy parserów, integracji z serwisem oraz interfejsu. Testy żywego źródła zależą od dostępności i limitów pobrań. Na Windowsie zgodność katalogu z oryginałem sprawdza `python -m pytest ios/Sprawdzenia`.

Dla wydania wybierz **Product → Archive** w schemacie „dostepna biblia”, a potem **Distribute App** w Organizerze. Wersja aplikacji pozostaje dokładnie **1.0**. Budowanie, testowanie i każda archiwizacja odczytują ten sam numer z `ios/Build.xcconfig`. Powtórzenie albo przerwanie `Archive` nie zmienia licznika.

Tylko na żądanie uruchom na Macu `~/dostepna-biblia/podbij_build.sh`. Jedno uruchomienie podnosi numer o jeden dla aplikacji i obu pakietów testowych, w Debug i Release. Aby jedynie odczytać numer, użyj `~/dostepna-biblia/podbij_build.sh --obecny`. Gotowe archiwa zachowują swoje numery.

Zespół: `9N975WV782`. Identyfikator: `com.dostepna.biblia`. Do sprawdzania wydania bez wysyłki służy lokalny eksport według `ExportOptions.plist`: zachowuje numer z archiwum. W Xcode i w nazwach plików wydania używamy „dostepna biblia” bez znaków diakrytycznych. Nazwa widoczna dla użytkownika to „dostępna biblia”. Sama archiwizacja niczego nie publikuje.
