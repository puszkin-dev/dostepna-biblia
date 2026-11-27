# dostępna biblia — polskie materiały do App Store Connect

**Nazwa:** dostępna biblia  
**Podtytuł:** Biblia i liturgia z VoiceOver  
**Kategoria:** Reference (aplikacja do korzystania z tekstów źródłowych)  
**Słowa kluczowe:** czytania,ewangelia,pismo święte,wersety,cytat,kalendarz,liturgia dnia  
**Wersja:** 1.0

## Opis aplikacji

Przeczytaj liturgię wybranego dnia, otwórz rozdział Biblii albo odszukaj zapamiętaną frazę. Cztery karty na dole ekranu prowadzą prosto do czytań, ksiąg, losowania cytatu i wyszukiwarki.

W kalendarzu osobno wybierasz miesiąc, dzień i rok. Możesz przeczytać całą liturgię lub tylko jedną z jej części. W Biblii wybierasz testament, księgę i rozdział. W rozdziałach z numerowanymi wersetami możesz przejść bezpośrednio do wybranego wersetu.

Aplikacja współpracuje z VoiceOver. Wartości suwaków zmieniasz przesunięciem palca w górę lub w dół. Wielkość tekstu czytania możesz ustawić niezależnie od wielkości napisów w iOS. Aplikacja pamięta wybór i dopasowuje kolory do jasnego lub ciemnego wyglądu telefonu.

Do pobrania tekstów z serwisu TwojaBiblia.pl potrzebny jest internet. Wybrany tekst możesz zapisać jako plik TXT i czytać później bez połączenia. Korzystanie z aplikacji nie wymaga konta.

## Informacja dla osoby sprawdzającej aplikację

Nie trzeba się logować. Z internetem: w karcie Liturgia wybierz datę i użyj przycisku Czytaj. W karcie Czytaj Biblię wybierz księgę i rozdział. W ustawieniach czytania można zmienić wielkość liter. VoiceOver jest obsługiwany, ale nie jest wymagany do korzystania z aplikacji.

## Co jest w paczce, a co należy do karty sklepu

- W podpisanym IPA aplikacji dla iPhone’a są: ikona AppIcon, systemowy ekran startowy, trzy orientacje (pion i oba poziomy), manifest prywatności i deklaracja braku szyfrowania wymagającego dokumentacji eksportowej. Połączenia HTTPS obsługuje systemowy URLSession; SwiftSoup parsuje HTML.
- Zdjęcia ekranu w tym katalogu służą do karty sklepu, a **nie** do umieszczania w IPA. Pochodzą z aplikacji na fizycznym iPhonie 17 Pro. Zachowują oryginalny pionowy rozmiar urządzenia. Nie są makietami ani obrazami przeskalowanymi z innego modelu.
- Po stronie konta przed publicznym wydaniem trzeba podać prawdziwy adres wsparcia i publiczny adres polityki prywatności, kontakt dla recenzenta, dane o prawach do treści, odpowiedzi w kwestionariuszach prywatności i kategorii wiekowej oraz wybrać dostępność. Tych danych nie zastępuje wpis w Xcode. Nie zadeklarowano w imieniu właściciela praw do cudzych przekładów ani zasad przechowywania danych przez zewnętrzny serwis.
- Zrzuty są przeznaczone do pola iPhone w App Store Connect. Aplikacja nie deklaruje natywnego targetu iPad. Aktualne wymiary i formaty: [specyfikacja Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

## Kolejność zrzutów i wynik kontroli

Sześć nowych plików PNG, 1206 × 2622 piksele, pion, bez kanału alfa. Pokazują kolejno liturgię, wybór księgi, czytanie rozdziału, listę wersetów, ustawienia wielkości tekstu i losowanie. W podglądzie sprawdzono wszystkie kadry: bez prywatnych powiadomień, klawiatury i alertów testowych. Zachowano oryginalne piksele i pasek stanu telefonu. To materiały z polskiego interfejsu, nie wersja angielska.

Sprawdzenie lokalne wydania 1.0 (7): trzy pakiety projektu — aplikacja, testy logiki i testy interfejsu — otrzymały 1.0 (7). Archiwa o kolejnych numerach 5, 6 i 7; numer 7 pozostał niezmieniony po budowaniu do testów. W IPA potwierdzono identyfikator, zespół, deklarację szyfrowania, ekran startowy, orientacje, rodzinę iPhone i manifest prywatności. Ikona źródłowa PNG i ikona sklepowa w skompilowanym katalogu mają 1024 × 1024 piksele i są nieprzezroczyste. Po wykonaniu zrzutów ponownie zainstalowano i uruchomiono na fizycznym iPhonie aplikację z archiwum. Eksport podpisany Apple Distribution, lokalny; nie przeprowadzano walidacji serwerowej ani wysyłki do App Store Connect.
