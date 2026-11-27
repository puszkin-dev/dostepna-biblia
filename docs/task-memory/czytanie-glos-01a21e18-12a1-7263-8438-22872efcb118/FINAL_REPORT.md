# Czytanie na głos i Ustawienia

Aplikacja **dostępna biblia 1.0 (9)** ma „Czytaj na głos” nad tekstem i piątą kartę Ustawienia. Syntezę dostarcza AVSpeechSynthesizer na urządzeniu; głos nie jest powiązany z głosem VoiceOver. Wspólna kolejka obejmuje akapity rzeczywiście otwartego tekstu, nie nazwy przycisków. Próbka nie nakłada się na czytanie. Odejście z czytnika zatrzymuje go, natomiast rozpoczęty tekst można odtwarzać w tle. Przyciski pauzy, kontynuacji i stopu współpracują z AVAudioSession i MediaPlayer; konfiguracja dla ekranu blokady sama w sobie nie jest dowodem sprzętowym.

Nad czytaniem jest szeroki przycisk z podpisem. Po uruchomieniu dołączają restart i stop. Przy największych literach są to trzy równe przyciski z czytelnymi symbolami oraz pełnymi nazwami VoiceOver; tekst Pisma pozostaje poniżej. Sekcja wyglądu prowadzi do istniejącego suwaka, nie tworzy drugiej kopii ustawienia. Ekran „O programie” ma nagłówki, pełne nazwiska, wyjaśnienie pochodzenia i polskie etykiety łączy. Kolory zależą od systemu. Oględziny zrzutów wykonał agent, nie osoba widząca.

**Źródła i publikacja.** Oryginał: [repozytorium Windows](https://github.com/puszkin-dev/dostepna-biblia/) i Dokumentacja.txt. Aplikacja pobiera czytania z [TwojaBiblia.pl](https://twojabiblia.pl/); serwis w stopce wskazuje własną zgodę wydawcy. [Wydawnictwo Pallottinum o wydaniu V i prawach](https://biblia.pl/informacje-o-wydaniu/). W dostarczonym projekcie nie ma potwierdzenia odrębnych praw do dystrybucji mobilnej i wykorzystania wszystkich treści liturgicznych. Nie deklarowano takiej zgody ani niczego nie wysyłano. Dokumentacja techniczna: [synteza Apple](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/), [sterowanie systemowe](https://developer.apple.com/documentation/mediaplayer/handling-external-player-events-notifications).

**Wydanie lokalne.** Implementacja: 8557e5d; osobny zapis odbioru obejmuje zrzuty, testy i ten raport. Archiwum w Organizerze: Biblia-mowa-204547.xcarchive. Podpis dystrybucyjny właściwego zespołu 9N975WV782. Identyfikator com.dostepna.biblia, wersja 1.0, kompilacja 9. Eksport i sprawdzenie codesign bez wysyłki. `ios/build/TestFlight/dostepna-biblia-1.0-9.ipa` ma ten sam SHA-256 na obu komputerach: `c2d50bc40c781d208ce1df0c18a618866beeb46db5aea9c35373a8f8d9e74a08`. Kod i dokumentacja synchronizowane wyłącznie lokalnie przez maczek.cmd.

## Odbiór na fizycznym iPhonie 17 Pro

Xcode 27.2, iOS 27.2.1, połączenie przewodowe przez Maca. Automat wywoływał rzeczywisty syntezator i rzeczywistą usługę VoiceOver. Nie jest to odsłuch akustyczny ani ocena osoby widzącej. Wyniki serii zawierających błędy podano bez dodawania ponowień do jednego fikcyjnego wyniku.

| Punkt §10 | Próba i wynik |
|---|---|
| 1. Liturgia | Pobrano czytania dnia. W otwartym tekście uruchomiono syntezę i przetestowano sterowanie. |
| 2. Psalm | Suwak „Część liturgii” → „Psalm”. Serwis zwrócił tekst; iPhone uruchomił syntezę i reagował na jej kontrolki. |
| 3. Biblia | Otworzono tekst Księgi Rodzaju i sprawdzono start, pauzę, wznowienie, restart i zatrzymanie. Test czytnika z numerowanym rozdziałem objął też werset i powrót do tekstu. |
| 4. Polskie głosy | Telefon zwrócił 112 pozycji z kodem rozpoczynającym się od „pl”, m.in. Zosia, Zosia (rozszerzony), Adam i Bogdan. To głosy dostępne poprzez API, również rozszerzenia, a nie lista fabryczna. Nie odsłuchiwano wszystkich 112. |
| 5. Próbka | Ten sam silnik przeczytał próbkę; po zakończeniu wrócił przycisk uruchomienia, test na telefonie. |
| 6. Szybkość | 11 pozycji od minimum do maksimum Apple, szósta odpowiada szybkości domyślnej. Zmieniono pozycję i odczytano ją po restarcie. Nie jest to procent szybkości VoiceOver. |
| 7. Głośność | 11 pozycji od ciszy do 100 procent, bez zmiany głośności urządzenia. Zmieniono wartość, sprawdzono pamięć i reset. |
| 8. Przyciski | Oddzielono przygotowanie silnika od rozpoczętej syntezy. Pauza, wznowienie, od początku i stop przeszły na fizycznym urządzeniu. |
| 9. Trwałość | Po zamknięciu i ponownym uruchomieniu zachowały się głos, tempo i głośność. W MowaTelefon2 test błędnie żądał dokładnie ósmej pozycji po przeciągnięciu do 70 procent toru; poprawiony test porównuje rzeczywiście wybraną pozycję. MowaTelefon3: zaliczony. |
| 10. VoiceOver włączony | Piąta karta, regulacja głosu gestami, próbka i nawigacja podczas mowy. Test pełnego czytania i nazwisk opisany poniżej. |
| 11. VoiceOver wyłączony | Rzeczywiste odtwarzanie Biblii, liturgii, psalmu i próbki bez korzystania z czytnika. Aplikacja nie przełącza VoiceOver. |
| 12. Przerwania | MowaTelefonAX5: drugi proces na tym samym iPhonie uruchomił niemiksowalną sesję i rzeczywiście odtworzył sekundę dźwięku; odczyt zakończył się bez samoczynnego wznowienia. Osobno w SpeechTests sprawdzono sztuczny komunikat przerwania i utraty wyjścia. Nie wykonano prawdziwego połączenia telefonicznego ani próby fizycznych słuchawek/Bluetooth (właściciel odłożył). Symulator nie odwzorował arbitrażu audio dwóch procesów, dlatego ta próba wymaga sprzętu. |
| 13. Karty | VoiceOver podał „Ustawienia”, „Karta 5 z 5”. Przeszło przełączanie czterech istniejących kart i nowej. |
| 14. O programie | Sprawdzono nazwy, opis, wersję, źródła, odnośnik, powrót i wybraną kartę. |
| 15. Autorzy | Pełne etykiety: „Pomysłodawca i autor wersji Windows: Grzegorz Przystupa” oraz „Projektant wersji iOS: Mieczysław Bąk”. Wynik próby rzeczywistej usługi VoiceOver poniżej. |
| 16. Repozytorium | Przycisk ma cechę łącza i opisuje oryginał Windows. Po aktywacji aplikacja przeszła w tło. Bezpośredni adres w kodzie: https://github.com/puszkin-dev/dostepna-biblia/. Wynik dodatkowej próby strony przeglądarki poniżej. |
| 17. Wersja | Wersja i numer kompilacji pochodzą z Bundle; sprawdzono widok i metadane podpisanej paczki 1.0 (9). |
| 18. Motywy | Jasny: fizyczny iPhone, tło w kolorze papieru, ciemny atrament, stonowany morski akcent. Ciemny: ciemna karta, jasne litery i złoty akcent. |
| 19. Największy tekst | Na małym symulatorze ciemny tryb AX5 ujawnił za wysoki pasek odtwarzania. Po poprawce trzy równe przyciski z symbolami nie przykrywają treści; etykiety VO pozostają pełne. W odnośniku usunięto ikonę zabierającą miejsce. |
| 20. Regresja | Jednostkowe i integracyjne próby danych, karty, kalendarz, wyszukiwanie, cytaty, TXT, wersety, wielkość czcionki, gesty. MowaTelefon2: 35/37; dwa błędy prób i ich osobne ponowienia opisano w raporcie. Mac: 14/14 pytest; Windows: 7 zaliczonych, 7 prób skryptu POSIX pominiętych. |

### Końcowe ponowienia i granice dowodów

Na fizycznym iPhonie **MowaOdbior 3/3**: wykonano sześć zdjęć, przetestowano przycisk mowy i chodzenie fokusem po kontrolkach podczas odsłuchu oraz kolejność „Grzegorz Przystupa” → „Mieczysław Bąk” → łącze GitHub. Po błędzie wywołanym przez baner powiadomienia test czeka na jego zniknięcie; nie ma potrzeby wyłączania powiadomień użytkownika. **MowaTelefonAX5 3/3**: ciemne Ustawienia, „O programie”, pasek aktywnego czytnika i realne przerwanie audio. **MowaTelefon3:** 1 zaliczona próba trwałości i 1 pominięta kontrolki systemowej. **MowaSystem:** ponowna próba łącza potwierdziła witrynę repozytorium w Safari, a nie tylko przejście aplikacji w tło. Ponownie sprawdzono aktualny interfejs na 13 mini. W repozytorium w `screenshots/` jest sześć obejrzanych, nieedytowanych plików RGB z telefonu, 1206 × 2622. Przenośne instrukcje: `ios/Instrukcja.md`; zasady publikacji i praw: `screenshots/Publikacja.md`.

**Niepotwierdzone:** połączenie telefoniczne z sieci komórkowej, fizyczne podłączanie i odłączanie słuchawek oraz Bluetooth, odtwarzanie i sterowanie po rzeczywistym zablokowaniu ekranu. XCTest na tej konfiguracji nie udostępnia naciśnięcia bocznego przycisku blokady; próba na ekranie początkowym nie jest testem blokady. Fizyczne akcesoria odłożono na życzenie właściciela. Nie wyłączano zabezpieczeń urządzenia ani nie wykonywano połączeń do postronnych osób. Nie oceniano barwy głosów na słuch. Zgodnie z zakresem próby niewykonane są oznaczone, nie zaliczone.

**Kontrolki systemowe:** MediaPlayer otrzymuje nazwę czytania oraz akcje, lecz na tym telefonie, w jego układzie Centrum sterowania, XCTest nie odnalazł pauzy również po próbie zmiany strony i dotarcia do wyspy. MowaSterowanie: 1 pominięta. Nie zgłaszamy sterowania z Centrum ani z ekranu blokady jako zweryfikowanego. Po testach zainstalowano i uruchomiono na telefonie aplikację z archiwum Release, system potwierdził 1.0 (9), VoiceOver włączony, wygląd jasny, tekst Large i wyłączone dodatkowe rozmiary dostępności zgodnie ze stanem sprzed testu.


| ID | Status | Wynik i dowód |
|---|---|---|
| R-001 | gotowe | AVSpeechSynthesizer na iPhonie 17 Pro; wspólna instancja, brak sieci w silniku i brak mikrofonu. |
| R-002 | gotowe | Wspólny TextScreen zasila mowę wyłącznie Reading.text. MowaTelefon2: Biblia, psalm, liturgia, pauza, wznowienie, restart i stop na urządzeniu. |
| R-003 | gotowe | Pięć natywnych kart. Audyt kart i aktywacja każdej przez rzeczywistą usługę VoiceOver. Rozmiar korzysta nadal z jednego ReadingSettings i jednego klucza. |
| R-004 | gotowe | Obie pełne role, mowa obu nazwisk na iPhonie (MowaOdbior), Safari potwierdziło stronę puszkin-dev/dostepna-biblia (MowaSystem); wersja i kompilacja z Bundle. Atrybucja i zakres niepotwierdzonych praw opisane w aplikacji i materiałach wydania. |
| R-005 | gotowe | 112 pozycji z polskim kodem języka w rzeczywistym API tego telefonu, w tym głosy rozszerzeń. Kod sortuje głosy polskie na początku. Próba brakującego ID z rzeczywistym silnikiem. |
| R-006 | gotowe | Trwałość głosu, tempa i głośności po restarcie oraz reset potwierdzone na fizycznym iPhonie (MowaTelefon3). Granice, błędne dane i zniknięcie głosu: SpeechTests. |
| R-007 | gotowe | Uruchomienie i samoczynny koniec wspólnego silnika w MowaTelefon3; aktywacja próbki i przejście do regulacji z włączoną usługą VoiceOver w MowaOdbior. |
| R-008 | odlozone | Zaliczono tło i prawdziwe przerwanie przez niemiksowalną sesję audio drugiego procesu na iPhonie. Osobno sprawdzono testowe komunikaty z systemu. Brak fizycznych słuchawek, połączenia telefonicznego i potwierdzenia po sprzętowej blokadzie. W próbach Centrum sterowania i wyspy XCTest nie znalazł kontrolki pauzy; pominięcie, nie sukces. |
| R-009 | gotowe | MowaTelefonAX5: oba testy wizualne na fizycznym iPhonie w ciemnym trybie AX5 zaliczone, zrzuty obejrzane. Jasny tryb na tym samym telefonie oraz mały symulator. Skorygowano pasek transportu, etykietę jakości głosu i wyrównanie linku. |
| R-010 | gotowe | 20 punktów rozpisanych w tabeli. Fizyczna instalacja, działająca synteza, obie konfiguracje VoiceOver, realne przerwanie przez drugi proces, oba nazwiska, przeglądarka, oba motywy i AX5. Wyłączenia sprzętowe wyszczególniono w R-008. |
| R-011 | gotowe | Kod i dokumentacja na lokalnej gałęzi ios obu komputerów, commit implementacji 8557e5d, lokalny eksport 1.0 (9), odświeżone rzeczywiste zrzuty, checkpoint i poniższe rozliczenie. Bez wysyłki. |
