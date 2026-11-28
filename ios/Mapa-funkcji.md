# Mapa parytetu Windows → iPhone

Punkt odniesienia: DostepnaBiblia.cs, Dokumentacja.txt i projekt Windows 1.1.1. Kolumna „Sprawdzenie” wskazuje próbę, a nie domyślnie sukces; wynik konkretnego przebiegu podaje raport zadania. Inwentaryzację źródła wykonano przed pisaniem portu; tę tabelę utrwalono po pierwszej implementacji, po doprecyzowaniu właściciela.

| Funkcja lub zachowanie Windows | Odpowiednik iOS | Stan | Sprawdzenie |
|---|---|---|---|
| Start na liturgii; data lokalna, cała liturgia | Pierwsza z pięciu kart; kalendarz gregoriański; polskie nazwy | Przeniesione | Telefon: mowa na otwarciu, próba gestów |
| Pasek zakładek; Ctrl+Tab, strzałki, Tab/Shift+Tab | UITabBarController, gesty VO, systemowa nawigacja klawiatury, Ctrl+Tab i Ctrl+Shift+Tab | Dostosowane, nie emulujemy WinForms ani NVDA | Stan zaznaczenia i liczba kart: test UI i mowy. Fizycznej klawiatury nie użyto |
| Alt+strzałka, Enter, Spacja na liście Windows | Bez rozwijania — gest góra/dół zmienia wartość, dwukrotne stuknięcie uruchamia akcję | Dostosowane na życzenie | Test regulacji na urządzeniu |
| Dzień, miesiąc i rok, zakres od 2000 do następnego roku; skrócenie 31. dnia | Trzy natywne kolumny: miesiąc, dzień, rok; dostosowanie do 28, 29, 30, 31 dni | Przeniesione | testKalendarz, testPiecKartIRegulacje, mowa VO |
| Sześć części, kilka czytań tego samego rodzaju, nagłówki wariantów i Mszy | Suwak części; czytania dzielone według nagłówków | Przeniesione | testCzesci, testWszystkieCzesciLiturgii |
| Windows 1.1.3: Boże Narodzenie, Wielka Sobota, usunięcie nieczynnych wskazówek | Te same daty i części na dotychczasowym suwaku; dodatkowy lekcjonarz tylko dla brakujących Mszy. Przy awarii zachowujemy dostępne teksty | Przeniesione | testSwietaNaZywychDanych, testBrakCzytanWielkiejSoboty, testBrakJednejMszyNieKasujePozostalych, testEwangelieNarodzeniaZVoiceOver |
| Kalendarz miesięczny, weryfikacja adresu, brak daty/sekcji lub zmiana układu | HTTPS, sprawdzanie ścieżki dnia, komunikaty po polsku | Przeniesione | testBrakiIDaneBledne, testCzesci |
| Czytania na żądanie; domyślny przycisk Czytaj | Systemowy przycisk i osobny ekran czytania | Przeniesione z inną prezentacją | testCzytanieIZapisLiturgii |
| Cała Biblia / Stary / Nowy Testament; 73 księgi w kolejności oryginału | Suwaki zakresu i księgi | Przeniesione | testKatalog i porównanie każdej pozycji z C# w pytest |
| Lista rozdziałów, domyślny wstęp 0, pamięć podręczna, zmiana księgi w trakcie pobierania | Suwak rozdziałów, pamięć sesji, anulowanie starego żądania; ponowienie po awarii | Przeniesione | testBiblia, testRozdzialyIWstep; anulowanie: przegląd kodu |
| Krótkie księgi, wspólny wstęp Jana, Rdz 49–50; pominięcie przypisów i inicjałów | Osobne reguły źródła w BibleService | Przeniesione | Próby na kontrolnych danych i w żywym serwisie |
| Losowanie z pięciu kategorii, odsyłacz, przekład; ponowienie, zapis i powrót | Suwak kategorii i oddzielne przyciski akcji, bez listy akcji | Przeniesione | testCytat, testKategorieCytatow, testLosowanieIPowrot |
| Pole frazy, Enter i Szukaj, frazy wielowyrazowe, puste dane | UITextField, akcja klawiatury Szukaj, bezpieczne kodowanie zapytania, alert | Przeniesione | testPaginacja, testWyszukiwanie, testStronyIPustaFraza |
| Stronicowanie poprzednia/następna, fraza i numer strony, brak wyników | Linki źródłowe, przyciski zależne od dostępności, nazwa bieżącego eksportu | Przeniesione | testWyszukiwanie, testStronyIPustaFraza |
| Pole tekstowe tylko do odczytu, kursor na początku, zaznaczanie, kopiowanie | UITextView z selekcją; pokrętło VoiceOver zamiast komend NVDA; systemowy powrót | Przeniesione z inną nawigacją | Wejście w tekst: testy UI. Kopiowanie: zachowanie UIKit, nie test schowka |
| TXT: polskie znaki, proponowana nazwa, wybór folderu, anulowanie, komunikat, źródło | UIDocumentPicker, UTF-8; liturgia i rozdział także bez Czytaj; cytat i wyniki po pobraniu | Przeniesione | Próba UI eksportu; skład treści potwierdzają testy źródła |
| Sieć, błędy pobrania i zapisu, stan oczekiwania, blokada podwójnej akcji, brak kradzieży fokusu z innej karty | Stan na ekranie, komunikat VO lub alert; blokada akcji, kontrola widoczności | Przeniesione | Próby błędnych danych; osobny komunikat dla HTTP 429 |
| Ustawienia, konta, zakładki użytkownika, lokalna pełna Biblia, hurtowy eksport | W oryginale ich nie ma. Na iOS jest karta ustawień syntezy, wielkości tekstu i informacji o programie. Pozostałych wymienionych funkcji nie dodawano | Rozszerzenie zakresu | Test ustawień, resetu i ponownego uruchomienia |
| Paczka Windows zawiera środowisko .NET | Natywna aplikacja iOS; biblioteka parsera w produkcie, bez instalowania zależności przez użytkownika | Dostosowane | Archiwum Release i eksport IPA |

## Wynik pierwotnego audytu portu (przed dodaniem piątej karty i syntezy)

| Ścieżka | Wynik i zakres potwierdzenia |
|---|---|
| Start i data | Na fizycznym iPhonie odczytano miesiąc, dzień i rok w tej kolejności. Każdy z trzech gestów zmienił wartość i pozwolił wrócić. Wybór 31 stycznia → luty 2024 → zmiana na rok 2025 dał kolejno 29 i 28. |
| Pasek kart | Usługa VoiceOver podała cztery nazwy oraz pozycje „1 z 4” do „4 z 4”. Podwójne stuknięcie przełączyło ekran; zaznaczenie pierwszej karty było obecne w mowie. |
| Wybory z list | Mowa: „Część liturgii Cała liturgia regulacja”; gest w górę „Pierwsze czytanie”, w dół „Cała liturgia”. Kategorie i zakres również odczytane jako regulacje. Brak UIMenu w produkcie sprawdza test przenośny. |
| Liturgia i jej źródło | Na telefonie zaliczono pobranie aktualnych czytań i pięciu pojedynczych części z niedzielnej strony. Dodatkowo sprawdzono brak dnia, złą domenę, puste dane, brak sekcji oraz wiele psalmów na kontrolnych danych. |
| Księgi | Zgodne wszystkie 73 kody, nazwy, kolejność i testamenty z C#. Wstęp Rodzaju otwarto przez interfejs; osobno pobrano rzeczywisty wspólny wstęp Jana oraz Rdz 50. Sprawdzono próg przejścia z Rdz 49, pierwsze siedem odsyłaczy i usuwanie przypisów. |
| Cytaty | Fizyczny iPhone pobrał cytat w każdej z pięciu kategorii; zaliczono przejście do tekstu i powrót do wyboru kategorii. Podczas wcześniejszej serii wystąpił rzeczywisty limit HTTP 429, dla którego dodano polski komunikat. |
| Wyszukiwarka | Zaliczono wpisanie „chleb”, wyszukanie klawiszem na klawiaturze, otwarcie drugiej strony, wykrycie linku powrotnego i brak wyników dla nieistniejącego słowa. Pusta fraza daje alert; po zamknięciu interfejs pozostaje dostępny. |
| Czytnik | Na sprzęcie VoiceOver po załadowaniu przeczytał datę z początku liturgii, a powrót otworzył ponownie formularz. Wyszukanie wersetu z listy przenosi do tekstu. Selekcja i kopiowanie są natywne; nie odczytywano prywatnego schowka i nie testowano zewnętrznej klawiatury. |
| TXT | Zaliczono otwarcie okna zapisu na urządzeniu i osobno rzeczywisty zapis UTF-8 z polskimi znakami oraz błąd przy niepoprawnym miejscu zapisu. Nie zapisano testowego dokumentu w prywatnym iCloud właściciela. |
| Ustawienia | Test na telefonie ustawił największy rozmiar, zamknął aplikację, uruchomił ją od nowa i odczytał tę samą wartość. Podgląd i czytnik używają tego samego skalowania. |
| Dystrybucja | Przygotowano lokalne archiwum i IPA. Dokładny podpis, suma pliku i wyniki końcowej kompilacji są w raporcie. Nie wysyłano do Apple ani na GitHub. |
