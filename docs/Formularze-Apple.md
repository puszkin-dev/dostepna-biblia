# Karta sklepu i formularze dla iOS 1.0 (10)

Stan zapisów potwierdzonych ponownym odczytem podaje raport rejestracji. Wskazówki o otwartych formularzach nie są złożoną deklaracją. Teksty pól: [Metadane-pl.json](../screenshots/Metadane-pl.json). Nazwa: 15/30 znaków; podtytuł: 29/30; promocja: 119/170; opis: 999/4000; słowa kluczowe: 71/100 bajtów UTF-8. Wydanie pierwsze: bez osobnej historii zmian wymaganej dla aktualizacji. SKU DOSTEPNA-BIBLIA-IOS (techniczny, po utworzeniu niezmienny). Potwierdzono polską lokalizację, iOS i identyfikator com.dostepna.biblia. Kategorie Reference oraz Books, bez podkategorii gier. Brak zakupów i subskrypcji w aplikacji.

## Dane i prywatność

| Co sprawdzono w kodzie produkcyjnym | Wynik dla formularza |
|---|---|
| Readings.swift, BibleService, wszystkie wywołania fetch | HTTPS do twojabiblia.pl: miesiąc/rok i data; księga/rozdział; kategoria cytatu (Base64 to kodowanie, nie anonimizacja); wyszukiwanie GET z frazą w parametrze s, potem adres strony wyników. Część liturgii wycina aplikacja lokalnie. Walidowana domena odpowiedzi; URLSession.shared stosuje systemowe zasady przekierowań i cookie. |
| Ruch i odbiorcy | IP, żądany URL i dane protokołu są widoczne u źródła/hostingu. Nie znaleziono własnego serwera portu. Nie wykonano przechwytywania całego ruchu ani audytu operatora. Nie można wnioskować o zawartości i czasie przechowywania logów z samej odpowiedzi HTTP. |
| Reklamy, analityka, marketing, identyfikatory, diagnostyka | Brak w aplikacji mechanizmów reklam, kupowania, śledzenia między aplikacjami, analityki, IDFA, IDFV i własnego wysyłania awarii. SwiftSoup parsuje HTML lokalnie; strona nie wykonuje JS w osadzonym widoku. Biblioteka systemowa mowy nie jest reklamowym SDK. Usługi dystrybucji i diagnostyki Apple to oddzielna warstwa. |
| Ustawienia, synteza, eksport, odnośniki | UserDefaults: rozmiar, głos, tempo, głośność, powód CA92.1. Tytuł widoczny w systemowym odtwarzaczu. TXT oraz ewentualna chmura Plików z wyboru użytkownika. Odnośniki do GitHuba, biblia.pl, pomocy i polityki prywatności otwierają się w przeglądarce. Szczegóły i usuwanie: [polityka prywatności](Polityka-prywatnosci-iOS.md). |
| Odpowiedzi App Privacy | Dla części lokalnej nie wskazywać jako zbieranych: preferencji, audio z mikrofonu, kontaktów, położenia, fotografii, danych płatniczych ani historii zapisanej przez port. Nie znaleziono wykorzystania do śledzenia. „Search History” i potencjalnie „Product Interaction” wymagają ustalenia retencji i celu po stronie źródła. IP klasyfikuje się według użycia, nie automatycznie jako lokalizację lub ID użytkownika. Powiązanie z użytkownikiem, użycie do analityki/reklam oraz podwykonawcy: niepotwierdzone. Nie oznaczać religii użytkownika na podstawie samego korzystania z Biblii. |
| Warunek zatwierdzenia | Uzyskać od operatora: czy przechowuje pełne adresy/hasła wyszukiwania, IP, identyfikatory sesji lub historię lektur po obsłużeniu odpowiedzi, na jak długo, w jakim celu, z kim je łączy i komu udostępnia. Przy retencji ustalić typy, cele i powiązanie. Przy wyłącznie obsłudze w czasie rzeczywistym zastosować definicję Apple. Pusty wykaz z manifestu nie rozstrzyga tej kwestii. |
| Adresy publiczne | [Opis](https://axelek.pl/dostepna-biblia.html), [wsparcie](https://axelek.pl/dostepna-biblia.html#pomoc), [polityka prywatności](https://axelek.pl/dostepna-biblia-prywatnosc.html) i [kontakt dotyczący danych](https://axelek.pl/dostepna-biblia-prywatnosc.html#kontakt). Zapisane w Apple, oddzielnie od nierozstrzygniętego kwestionariusza. |

[Definicje prywatności Apple](https://developer.apple.com/app-store/app-privacy-details/) · [Kwestionariusz w portalu](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)

## Wiek — odpowiedzi do deklaracji

Brak reklam, kontroli rodzicielskiej, weryfikacji wieku, społeczności, randek, czatu, publikacji użytkowników, udostępniania lokalizacji, płatnych losowań, hazardu, konkursów i swobodnej przeglądarki WWW. Fraza przeszukuje jedno źródło; przekierowanie do zewnętrznego Safari odnośnikami informacyjnymi nie jest nieograniczoną przeglądarką w aplikacji. Losowy cytat nie jest symulacją hazardu. Brak porad medycznych, leczenia i funkcji monitorowania zdrowia; aplikacja nie jest dla kategorii dziecięcej. Bez ręcznego obniżenia wieku i bez numeru GRAC.

Treści nie są jedynie dekoracją religijną: występują opisy zabójstw, wojen, broni i egzekucji (np. Rdz 4, 1 Sm 17, Mk 15), wzmianki o winie (J 2), tematy dojrzałe, przemoc seksualna (2 Sm 13) i poezja miłosna (Pnp). Ocena robocza: przemoc realistyczna i broń powtarzają się; dojrzałe tematy powtarzają się; alkohol i niegraficzne treści seksualne są obecne. Wymaga oceny kontekstu oraz częstości dla pełnego korpusu, w tym tematów lęku, wulgarności, fantastycznej przemocy i szczegółowych opisów cierpienia. Brak filmów i ilustracji przemocy nie oznacza braku jej opisów. Nie zadeklarowano na ślepo 4+ ani kategorii dla dzieci; wynik regionalny oblicza Apple na podstawie odpowiedzi. [Kryteria Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/).

## Dostępność — iPhone

VoiceOver: za sprawdzonymi zadaniami przemawiają rzeczywiste gesty na urządzeniu, pięć kart, regulacje daty/wyboru i mowy, nawigacja do wersetów, powrót i aktywacja. Większy tekst: Dynamic Type do AX5, ponadto regulacja czytnika; znaleziony problem paska odtwarzania poprawiono. Ciemny wygląd: sprawdzono na działającej aplikacji. Kontrast: próby palety w czterech kombinacjach i systemowy audyt. Rozróżnianie bez koloru: tekstowe stany kontrolek, ikony i systemowe zaznaczenie karty. Redukcja ruchu: ścieżki przejść w kodzie respektują ustawienie; nie ma osobnego potwierdzenia każdej typowej czynności przy włączonej opcji. Nie deklarować obsługi sterowania głosem na podstawie samego VoiceOver. Napisy i audiodeskrypcja materiałów wideo nie dotyczą tej aplikacji; synteza mowy nie jest audiodeskrypcją. Nie przenosić wyników iPhone’a na iPada. Dowody historyczne, nie nowy audyt urządzenia: raporty portu i czytania w docs/task-memory.

Dla publicznego wpisu stosować próg funkcjonalny Apple dla wszystkich typowych czynności; nie publikować pozostałych niezweryfikowanych cech. [Deklaracje API a widoczność w sklepie](https://developer.apple.com/documentation/appstoreconnectapi/configuring-accessibility-declarations).

## TestFlight i pozostałe sekcje

Opis beta po polsku i angielskie instrukcje recenzenta są w pliku metadanych. Instrukcja testowa: z internetem wybierz datę, odczytaj Ewangelię, przejdź do rozdziału i wersetu; wyszukaj „światło”, zapisz stronę jako TXT, następnie zmień głos, tempo i rozmiar liter. Sprawdź obsługę z VoiceOver i bez. Logowanie: nie; bez fikcyjnego konta demonstracyjnego. Nie wpisano prywatnego adresu Apple ID jako kontaktu dla testerów. Zatwierdzony kontakt Grzegorza Przystupy jest zapisany w obu formularzach; e-mail zwrotny testerów również potwierdzony. Co testować dla konkretnego buildu można powiązać po jego osobno zleconej wysyłce.

Brak implementacji kryptografii poza transportem systemowym: podpisana aplikacja deklaruje ITSAppUsesNonExemptEncryption=false; nie oznacza to braku HTTPS. Bez wniosków o dodatkowe usługi, subskrypcje, kampanie, zmiany finansów, dostępności terytorialnej i umów. Nie potwierdzono uprawnień do dystrybucji przekładu V wydania Biblii Tysiąclecia ani wszystkich tekstów liturgicznych, syntezy i eksportu TXT. Pozostawić oświadczenie o prawach bez zatwierdzenia do wyjaśnienia z uprawnionymi. Nie mylić praw do kodu z prawami do tekstów.

## Materiały wizualne

Sześć oryginałów z fizycznego iPhone’a 17 Pro ma 1206 × 2622 (6,3 cala). Uzupełniający katalog screenshots/iphone-6_9 zawiera sześć nowych PNG 1320 × 2868 z rzeczywistego uruchomienia na symulatorze dużego iPhone’a. To nie są zdjęcia z fizycznego Pro Max ani przeskalowane miniatury. Sprawdzono brak kanału alfa, wymiary i kadry: liturgia, księga, czytanie, wersety, ustawienia i losowanie. Ikonę sklepu Apple bierze z archiwum — nie wysyłano buildu. [Wymiary Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

Stan po rejestracji: kategorie, lokalizację, 12 zrzutów, oba zestawy notatek dla recenzenta i opis beta zapisano dla 6840151385. Obie recenzje zawierają instrukcje testu, kontakt i brak wymogu logowania; zapisano także publiczne adresy i Copyright „2026 Mieczysław Bąk”. Pięć cech dostępności w szkicu. API odrzuciło niepełną deklarację wieku; prywatność i prawa pozostają nierozstrzygnięte. [Wynik każdej sekcji](task-memory/rejestracja-01a21e18-12a1-7263-8438-22872efcb118/FINAL_REPORT.md).

Robocze uzupełnienie ankiety: sporadyczny obraźliwy język (np. 1 Sm 20), motywy grozy i przemocy fantastycznej (Ap 9). Nie stwierdzono dosłownej, szczegółowej prezentacji aktu seksualnego w analizowanych przykładach; odrębnie uwzględniono przemoc seksualną i dojrzałe motywy. Najważniejszy sporny deskryptor to przedłużona, szczegółowa lub sadystyczna przemoc: w 2 Mch 7 rozbudowany opis męczeństwa, w Sdz 19 brutalny epizod. Nie pomijać tekstu tylko dlatego, że nie ma ilustracji. Apple wiąże ten deskryptor nawet przy sporadycznym wystąpieniu z wynikiem bez klasyfikacji. Nie jest to wynik nadany tej karcie przez Apple. Pytanie do wyjaśnienia: czy Apple stosuje ten szczególny deskryptor do takiego opisu w nieilustrowanym wydaniu literackim, obok zwykłej przemocy realistycznej? Nie wysłano zapytania ani aplikacji do recenzji.

## Wiadomość do operatora — przygotowana, niewysłana

Do: kontakt@twojabiblia.pl

Temat: dostępna biblia na iPhone’a — warunki korzystania ze źródła i prywatność zapytań

Dzień dobry,

przygotowujemy „dostępną biblię”, aplikację na iPhone’a przystosowaną do VoiceOver. To port projektu Grzegorza Przystupy dla Windows. Aplikacja pobiera kalendarz i cytaty z Państwa API, a rozdziały, czytania i wyniki wyszukiwania z Państwa stron. Czytelnik może odsłuchać tekst systemowym głosem iOS lub zapisać otwarty fragment do pliku TXT. Opis aplikacji: https://axelek.pl/dostepna-biblia.html.

Czy obecne warunki zezwalają na takie użycie w aplikacji udostępnianej przez TestFlight i App Store? Będziemy wdzięczni za wskazanie warunków, wymaganej atrybucji oraz informację, czy powinniśmy uzyskać oddzielne potwierdzenie wydawcy przekładu lub czytań liturgicznych.

Drugie pytanie dotyczy informacji dla czytelników. Wyszukiwana fraza jest przesyłana w adresie żądania. Czy po udzieleniu odpowiedzi Państwo lub hosting przechowują IP, pełne adresy z frazami, identyfikator sesji lub historię żądań? Jeśli tak: w jakim celu, przez jaki czas, czy są wiązane z użytkownikiem lub urządzeniem i komu udostępniane? Wystarczy odnośnik do aktualnych zasad, jeżeli obejmują te dane.

Dziękuję za pomoc,

Mieczysław Bąk, projektant wersji iOS
