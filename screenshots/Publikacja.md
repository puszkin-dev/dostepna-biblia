# dostępna biblia — polskie materiały do App Store Connect

**Nazwa:** dostępna biblia  
**Podtytuł:** Biblia i liturgia z VoiceOver  
**Kategoria główna:** Reference (religia, wyszukiwanie tekstów i cytatów)

**Kategoria dodatkowa do karty sklepu:** Books (Książki) — aplikacja ma też czytnik ksiąg, rozdziałów i wersetów.
**Słowa kluczowe:** czytania,ewangelia,pismo święte,wersety,cytat,kalendarz,liturgia dnia  
**Wersja:** 1.0

## Opis aplikacji

Przeczytaj liturgię wybranego dnia, otwórz rozdział Biblii albo odszukaj zapamiętaną frazę. Otwarty tekst możesz odsłuchać wybranym głosem iPhone’a, także bez VoiceOver. Pięć kart na dole prowadzi do liturgii, ksiąg, losowania cytatu, wyszukiwarki i ustawień.

W kalendarzu osobno wybierasz miesiąc, dzień i rok. Możesz przeczytać całą liturgię lub tylko jedną z jej części. W Biblii wybierasz testament, księgę i rozdział. W rozdziałach z numerowanymi wersetami możesz przejść bezpośrednio do wybranego wersetu.

Aplikacja współpracuje z VoiceOver. Wartości suwaków zmieniasz przesunięciem palca w górę lub w dół. Wielkość tekstu czytania możesz ustawić niezależnie od wielkości napisów w iOS. Aplikacja pamięta wybór i dopasowuje kolory do jasnego lub ciemnego wyglądu telefonu.

Do pobrania tekstów z serwisu TwojaBiblia.pl potrzebny jest internet. Wybrany tekst możesz zapisać jako plik TXT i czytać później bez połączenia. Korzystanie z aplikacji nie wymaga konta.

## Informacja dla osoby sprawdzającej aplikację

Nie trzeba się logować. Z internetem: w karcie Liturgia wybierz datę i użyj przycisku Czytaj. W karcie Czytaj Biblię wybierz księgę i rozdział. W ustawieniach czytania można zmienić wielkość liter. VoiceOver jest obsługiwany, ale nie jest wymagany do korzystania z aplikacji.

## Co jest w paczce, a co należy do karty sklepu

Stan po dodaniu mowy: aplikacja nie pobiera głosów z chmury ani nie nagrywa mikrofonu. Tryb tła `audio` służy wyłącznie słuchaniu rozpoczętego tekstu. Zdjęcia w tym katalogu pokazują aktualny interfejs 1.0 (9) z pięcioma kartami. Poniższy historyczny audyt 1.0 (8) dotyczy wcześniejszego wydania.

**Prawa do treści przed dystrybucją.** Dokumentacja Windows i stopka [TwojaBiblia.pl](https://twojabiblia.pl/) wskazują V wydanie Biblii Tysiąclecia. Serwis podaje, że korzysta z tekstu za zgodą Pallottinum. [Wydawca o prawach do opracowania](https://biblia.pl/informacje-o-wydaniu/) wskazuje ochronę i potrzebę uzyskania zgody. W projekcie nie znaleziono dokumentu rozszerzającego zgodę serwisu na dystrybucję tej aplikacji, odczyt głosowy i eksport tekstów. Sama atrybucja i publiczne repozytorium nie potwierdzają takich uprawnień. Przed udostępnieniem również w TestFlight trzeba wyjaśnić z uprawnionymi zakres korzystania z przekładu i pozostałych tekstów liturgicznych.

- W podpisanym IPA aplikacji dla iPhone’a są: ikona AppIcon, systemowy ekran startowy, trzy orientacje (pion i oba poziomy), manifest prywatności i deklaracja braku szyfrowania wymagającego dokumentacji eksportowej. Połączenia HTTPS obsługuje systemowy URLSession; SwiftSoup parsuje HTML.
- Zdjęcia ekranu w tym katalogu służą do karty sklepu, a **nie** do umieszczania w IPA. Pochodzą z aplikacji na fizycznym iPhonie 17 Pro. Zachowują oryginalny pionowy rozmiar urządzenia. Nie są makietami ani obrazami przeskalowanymi z innego modelu.
- Po stronie konta przed publicznym wydaniem trzeba podać prawdziwy adres wsparcia i publiczny adres polityki prywatności, kontakt dla recenzenta, dane o prawach do treści, odpowiedzi w kwestionariuszach prywatności i kategorii wiekowej oraz wybrać dostępność. Tych danych nie zastępuje wpis w Xcode. Nie zadeklarowano w imieniu właściciela praw do cudzych przekładów ani zasad przechowywania danych przez zewnętrzny serwis.
- Zrzuty są przeznaczone do pola iPhone w App Store Connect. Aplikacja nie deklaruje natywnego targetu iPad. Aktualne wymiary i formaty: [specyfikacja Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

## Kolejność zrzutów i wynik kontroli

Sześć plików PNG z fizycznego iPhone’a 17 Pro, kompilacja 9: 1206 × 2622 piksele, pion, bez kanału alfa. Pokazują kolejno liturgię, wybór księgi, czytanie rozdziału z przyciskiem mowy, listę wersetów, piątą kartę ustawień oraz losowanie. W podglądzie sprawdzono wszystkie kadry: bez prywatnych powiadomień, klawiatury i alertów testowych. Zachowano oryginalne piksele i pasek stanu telefonu. To materiały z polskiego interfejsu.

Sprawdzenie lokalne wydania 1.0 (7): trzy pakiety projektu — aplikacja, testy logiki i testy interfejsu — otrzymały 1.0 (7). Archiwa o kolejnych numerach 5, 6 i 7; numer 7 pozostał niezmieniony po budowaniu do testów. W IPA potwierdzono identyfikator, zespół, deklarację szyfrowania, ekran startowy, orientacje, rodzinę iPhone i manifest prywatności. Ikona źródłowa PNG i ikona sklepowa w skompilowanym katalogu mają 1024 × 1024 piksele i są nieprzezroczyste. Po wykonaniu zrzutów ponownie zainstalowano i uruchomiono na fizycznym iPhonie aplikację z archiwum. Eksport podpisany Apple Distribution, lokalny; nie przeprowadzano walidacji serwerowej ani wysyłki do App Store Connect.

## Audyt ustawień Xcode — 1.0 (8)

Sprawdzono wygenerowany projekt, ustawienia wszystkich targetów dla Debug i Release w Xcode 27.2 oraz produkt po archiwizacji i eksporcie. Poniższe pozycje opisują konfigurację lokalną, nie stan konta sklepowego.

| Sekcja | Konfiguracja i uzasadnienie |
|---|---|
| General — Identity | Kategoria **Reference**, nazwa „dostępna biblia”, identyfikator `com.dostepna.biblia`, wersja 1.0, build z jednego licznika. Nazwa i kategoria są jawnymi ustawieniami targetu aplikacji i z nich powstają wartości w IPA. |
| General — Supported Destinations i Minimum Deployments | Natywnie iPhone od iOS 17.0; kompilacja na urządzenie i symulator. Brak natywnego targetu iPad, Mac Catalyst, watchOS lub visionOS. Domyślnych ustawień zgodności „Designed for iPhone/iPad” nie zmieniano; to nie jest deklaracja przetestowania wersji na Maca lub Vision Pro. |
| General — Deployment Info | Pion i oba poziomy. Brak pionu do góry nogami jest zgodny z kontrolerem kart. Sceny tworzy delegat aplikacji. Brak głównego storyboardu jest zamierzony: aplikacja buduje interfejs w UIKit w kodzie. Nie wpisuje się tutaj szerokości ani wysokości ekranu w pikselach. |
| General — App Icons and Launch Screen | Katalog `AppIcon` z nieprzezroczystą ikoną 1024 × 1024; systemowy ekran startowy `UILaunchScreen`. Nie wskazuje się nieistniejącego storyboardu startowego. |
| General — Frameworks, Libraries, and Embedded Content | SwiftSoup 2.8.8 z przypiętej zależności pakietowej. Produkt nie wymaga osobnego osadzanego frameworka SwiftSoup ani rozszerzenia aplikacji. |
| Signing & Capabilities | Podpis automatyczny, zespół `9N975WV782`. Eksport: Apple Distribution, aktywne raporty beta, brak uprawnienia debuggera. Aplikacja nie wymaga iCloud, zakupów, powiadomień push, grup aplikacji ani pracy w tle. |
| Info oraz lokalizacje projektu | Polski język bazowy i jawna lokalizacja `pl`. Brak własnych schematów URL, typów importowanych/eksportowanych i obsługiwanych dokumentów: aplikacja **zapisuje** zwykły TXT przez systemowe Pliki, nie rejestruje się jako aplikacja do otwierania plików. |
| Prywatność i szyfrowanie | W IPA jest manifest prywatności z powodem użycia UserDefaults `CA92.1`. Systemowe HTTPS; `ITSAppUsesNonExemptEncryption = NO`. Nie dodano komunikatów o dostępie do mikrofonu, zdjęć, kontaktów ani lokalizacji — aplikacja nie prosi o te uprawnienia. |
| Build Settings, Build Phases, Build Rules | Aplikacja i obie paczki testowe dziedziczą wersję i licznik. Osobny target rezerwuje numer. Fazy kompilują źródła, łączą zależność i kopiują katalog zasobów, manifest oraz licencję. Reguły systemowe wystarczają. W Release włączono jawną walidację produktu; Xcode wykonał krok Validate na archiwalnej aplikacji. |
| Zasoby na żądanie, skróty systemowe i rozszerzenia | Nie ma paczek zasobów na żądanie, osobnego targetu rozszerzenia, funkcji Siri ani App Intents. Komunikat Xcode o pominięciu ekstrakcji App Intents odpowiada brakowi tej funkcji, nie brakującej deklaracji do wysyłki. |

W podpisanym IPA 1.0 (8) potwierdzono kategorię, nazwę, język, wersję, identyfikator, urządzenie, orientacje, ekran startowy, ikonę, manifest i uprawnienia podpisu. Podpis przeszedł kontrolę `codesign --verify --deep --strict`. Ekran Maca był zablokowany: odczyt ustawień pochodzi z narzędzi tego Xcode i z podpisanej paczki, nie z oględzin odblokowanego panelu General.

**Oddzielnie w App Store Connect:** Apple umieszcza religię w kategorii Reference, nie udostępnia osobnej kategorii Religion dla aplikacji iOS. Główną Reference i dodatkową Books należy wybrać w karcie aplikacji. Kwestionariusze wieku, prywatności, deklaracje dostępności, dane kontaktowe i adresy publikacji również należą do konta; nie zostały wysłane. [Definicje kategorii Apple](https://developer.apple.com/app-store/categories/) · [Przygotowanie projektu Xcode](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution).
