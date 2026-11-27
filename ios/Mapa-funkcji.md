# Mapa parytetu Windows → iPhone

Punkt odniesienia: DostepnaBiblia.cs, Dokumentacja.txt i projekt Windows 1.1.1. Kolumna „Sprawdzenie” wskazuje próbę, a nie domyślnie sukces; wynik konkretnego przebiegu podaje raport zadania. Inwentaryzację źródła wykonano przed pisaniem portu; tę tabelę utrwalono po pierwszej implementacji, po doprecyzowaniu właściciela.

| Funkcja lub zachowanie Windows | Odpowiednik iOS | Stan | Sprawdzenie |
|---|---|---|---|
| Start na liturgii; data lokalna, cała liturgia | Pierwsza z czterech kart; kalendarz gregoriański; polskie nazwy | Przeniesione | Telefon: mowa na otwarciu, próba gestów |
| Pasek zakładek; Ctrl+Tab, strzałki, Tab/Shift+Tab | UITabBarController, gesty VO, systemowa nawigacja klawiatury, Ctrl+Tab i Ctrl+Shift+Tab | Dostosowane, nie emulujemy WinForms ani NVDA | Stan zaznaczenia i liczba kart: test UI i mowy. Fizycznej klawiatury nie użyto |
| Alt+strzałka, Enter, Spacja na liście Windows | Bez rozwijania — gest góra/dół zmienia wartość, dwukrotne stuknięcie uruchamia akcję | Dostosowane na życzenie | Test regulacji na urządzeniu |
| Dzień, miesiąc i rok, zakres od 2000 do następnego roku; skrócenie 31. dnia | Trzy natywne kolumny: miesiąc, dzień, rok; dostosowanie do 28, 29, 30, 31 dni | Przeniesione | testKalendarz, testCzteryKartyIRegulacje, mowa VO |
| Sześć części, kilka czytań tego samego rodzaju, nagłówki wariantów i Mszy | Suwak części; czytania dzielone według nagłówków | Przeniesione | testCzesci, testWszystkieCzesciLiturgii |
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
| Ustawienia, konta, zakładki użytkownika, lokalna pełna Biblia, hurtowy eksport | W oryginale ich nie ma, nie dodano ich w porcie | Zgodne | Przegląd źródła i całej dokumentacji |
| Paczka Windows zawiera środowisko .NET | Natywna aplikacja iOS; biblioteka parsera w produkcie, bez instalowania zależności przez użytkownika | Dostosowane | Archiwum Release i eksport IPA |
