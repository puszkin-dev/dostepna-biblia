# Prywatność w aplikacji „dostępna biblia” dla iPhone’a

Projekt dla wersji 1.0. Nie został opublikowany. Przed publikacją wydawca uzupełni swoją tożsamość i właściwy kanał kontaktu, datę obowiązywania oraz potwierdzi z operatorem źródła zasady dzienników serwera. Ten dokument dotyczy portu iOS, nie innych aplikacji biblijnych.

## Kiedy telefon łączy się z internetem?

Aplikacja nie wymaga konta. Aby pokazać treść, pobiera ją przez szyfrowane połączenie HTTPS z TwojaBiblia.pl. Serwis otrzymuje dane potrzebne do danego wyboru: rok i miesiąc kalendarza oraz datę czytania, oznaczenie księgi i rozdziału, kategorię losowania albo wpisaną frazę wyszukiwania i żądaną stronę wyników. Wybór części liturgii z pobranego czytania odbywa się na telefonie. W pole wyszukiwania nie musisz wpisywać danych osobowych.

Serwer obsługujący żądanie widzi adres IP połączenia i techniczne informacje o żądaniu. To Twój telefon łączy się ze źródłem, nie pośredniczy w tym oddzielny serwer aplikacji. Nie ustaliliśmy, czy i jak długo operator lub dostawca jego hostingu przechowuje adresy zapytań, adresy IP albo identyfikatory sesji. Nie obiecujemy więc anonimowości ani natychmiastowego usuwania danych po stronie serwisu.

## Co pozostaje na urządzeniu?

Aplikacja zachowuje rozmiar tekstu czytania, wybór głosu, szybkość i głośność w ustawieniach aplikacji na iPhonie. Nie zakłada profilu czytelnika. W trakcie korzystania przechowuje w pamięci bieżące wyniki i wybory; nie prowadzi własnej trwałej historii zapytań. System iOS obsługuje połączenia sieciowe, pamięć podręczną i ewentualne pliki cookie zgodnie z ustawieniami użytej sesji. Ustawienia mowy i rozmiaru tekstu można przywrócić w aplikacji do wartości domyślnych.

## Czytanie na głos i pliki

Tekst do odczytu aplikacja przekazuje systemowemu mechanizmowi mowy i wybranemu głosowi dostępnemu w iOS. Nie nagrywa głosu, nie używa mikrofonu i nie wysyła tekstu do własnej usługi syntezy. Jeżeli zainstalujesz głos innego dostawcy, jego zasady mogą być odrębne. Podczas czytania iOS otrzymuje tytuł, nazwę aplikacji i stan odtwarzania; tytuł może być widoczny np. na ekranie blokady lub akcesorium.

Po wybraniu „Zapisz do TXT” aplikacja przygotowuje tymczasową kopię tekstu, a Ty wybierasz miejsce zapisu w systemowych Plikach. Może to być folder lokalny albo chmura Twojego dostawcy. Po zakończeniu lub anulowaniu wyboru aplikacja usuwa swoją kopię tymczasową. Wyeksportowany dokument należy usunąć samodzielnie w wybranej lokalizacji; usunięcie aplikacji nie usuwa takich dokumentów.

## Reklamy, statystyki i strony zewnętrzne

Aplikacja nie ma reklam, narzędzi śledzenia, własnej zdalnej analityki ani mechanizmu wysyłającego wydawcy historię lektur lub raporty awarii. Nie odczytuje identyfikatora reklamowego, lokalizacji, kontaktów ani zdjęć. SwiftSoup przetwarza pobrany tekst strony na urządzeniu; aplikacja nie wyświetla strony w przeglądarce osadzonej i nie wykonuje dołączonych do niej skryptów reklamowych.

W informacjach o programie możesz otworzyć w przeglądarce odnośnik do GitHuba lub wydawcy przekładu. Dopiero po wybraniu odnośnika zaczynają obowiązywać zasady danej strony i przeglądarki. Sklep, TestFlight, ustawienia diagnostyki i kopie zapasowe urządzenia to odrębne usługi Apple.

## Pytania i usunięcie danych

Możesz usunąć aplikację wraz z jej lokalnymi danymi z telefonu. Nie ma konta do skasowania. W sprawach dotyczących danych obsługiwanych przez wydawcę należy skorzystać z jego kontaktu ds. prywatności. **Do uzupełnienia przed publikacją: potwierdzone dane wydawcy i adres kontaktowy.** W sprawach dzienników zewnętrznego serwisu potrzebna jest weryfikacja z jego operatorem. Jeśli zostanie potwierdzone dalsze przetwarzanie, przed publikacją należy podać odpowiednie cele, podstawy, odbiorców, okresy i sposób realizacji praw.
