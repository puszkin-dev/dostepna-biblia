# Odbiór portu „dostępna biblia” na iPhone’a

**Wydanie 1.2.0 (1), 27 listopada 2026 r.** Cztery karty odpowiadają czterem zakładkom Windows. Port obejmuje pobieranie liturgii, czytanie 73 ksiąg ze wstępami i rozdziałami, losowe cytaty, wyszukiwanie ze stronicowaniem oraz eksport TXT. [Mapa funkcji i wyników](../../../ios/Mapa-funkcji.md) podaje osobno zachowania oryginału, odpowiedniki dla iOS i sposób ich sprawdzenia. [Instrukcja telefonu](../../../ios/Instrukcja.md) opisuje obsługę gestami.

## Jak wygląda i jak się go używa

W dzień tło ma kolor ciepłego papieru, tekst jest ciemny, a najważniejszy przycisk ma morski kolor i biały napis. W nocy papier zastępuje grafit, tekst jest jasny, a przycisk i aktywna część suwaka są piaskowozłote. Wysoki kontrast przełącza podstawowe tło na czyste białe albo czarne. Zaznaczoną kartę wyróżnia system, a VoiceOver mówi o jej stanie i pozycji; nie trzeba rozpoznawać kolorów.

Na karcie najpierw jest tytuł, po jego prawej stronie przycisk wielkości tekstu, niżej wybory i przyciski akcji. Pasek czterech kart pozostaje na dole. W czytniku szeryfowy tekst jest wyrównany do początku wiersza, ma odstępy między liniami i marginesy po bokach. Na górze są powrót i działania: przejście do wersetu (gdy tekst ma numerację), wielkość pisma i zapis. Lista wersetów pokazuje numer oraz początek tekstu. Numer nie zastępuje treści.

Suwak wielkości ma pięć pozycji, żywy podgląd i przycisk resetu. Zmienia bazową wielkość pisma tekstów, nie rozmiar całej aplikacji; iOS skaluje ją tylko raz według Dynamic Type. Wybór pozostaje po restarcie. Gdy systemowe litery są bardzo duże, formularze można przewijać, długie nazwy się zawijają, a trzy wybory daty układają się pionowo. Gest w górę lub w dół nadal reguluje jedną wartość.

## Co faktycznie sprawdzono

Na fizycznym **iPhonie 17 Pro** końcowy pełny przebieg `Telefon10.xcresult`: **28/28 zaliczonych, 0 pominiętych**. Obejmował 13 prób logiki, ustawień i wyglądu, 4 integracje z żywym serwisem, 5 testów interfejsu, 3 wizualne i 3 rzeczywistego VoiceOver. Dostęp do serwisu sprawdzono tego dnia; nie oznacza to gwarancji jego przyszłej dostępności. W poprzednim przebiegu (Telefon9, 27/28) baner systemowy zasłonił przycisk. Poprawiono synchronizację testu zamiast zmieniać zachowanie aplikacji. Po testach zainstalowano i uruchomiono na iPhonie wersję Release z archiwum, z podpisem deweloperskim dla sprzętu. Osobna kopia IPA ma podpis dystrybucyjny.

- Usługa VoiceOver na fizycznym urządzeniu, nie symulacja etykiet: osobne „Wybierz miesiąc”, „Wybierz dzień” i „Wybierz rok” z wartością i cechą „regulacja”; w obu kierunkach zmieniały się także dzień i rok. „Część liturgii Cała liturgia regulacja” → „Pierwsze czytanie” → „Cała liturgia”. Po pobraniu czytnik zaczął od daty. Odczytano nazwy i numerację 1–4, aktywowano karty oraz sprawdzono mowę ustawień tekstu. Test kotwiczy fokus na znanych elementach i nie próbuje przejść dalej za ostatnią kartę.
- Na symulatorach iPhone 17 Pro Max (jasny) i 13 mini (ciemny, AX5, zwiększony kontrast) przeszły po trzy scenariusze, także po obrocie. Obejrzano zestawy po 13 zrzutów: kalendarz, wybory, wszystkie karty, pusta fraza, ustawienia przed zmianą i po zmianie, rozdział, lista wersetów i poziom. To analiza obrazów z działającej aplikacji, nie ocena człowieka. Sprawdzono także zdjęcia z telefonu. Zrzuty lokalne: `ios/build/Audyt`; wyniki Xcode na Macu: `ios/build/*.xcresult`.
- Na dodatkowym symulatorze iPhone SE 3 z iOS 26.2 obejrzano ekrany pionowe przy AX5. Dwa scenariusze nie potwierdziły poziomego okna; osobna próba przy standardowym tekście także nie przeszła. W kontroli z Safari na tym samym symulatorze po poleceniu obrotu widok również pozostał pionowy. Nie rozstrzygnięto przyczyny i nie zaliczono poziomu na SE.
- Dla podstawowego tekstu na tle współczynniki kontrastu w zwykłym trybie wyniosły 12,86:1 (dzień) i 14,74:1 (noc), a dla napisów głównych przycisków 9,04:1 i 9,97:1. Tor suwaka na powierzchni wyborów: 4,08:1 oraz 4,95:1. Test bada osobno jasny/ciemny i standardowy/zwiększony kontrast. Odniesienia: [typografia Apple](https://developer.apple.com/design/human-interface-guidelines/typography), [kryterium kontrastu WCAG](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
- Oględziny ujawniły podwójny tytuł ustawień, przyciętą ikonę przy AX5, słabo widoczny tor suwaka i obramowanie pola oraz brak odsyłaczy do pierwszych sześciu wersetów Rdz 50. Poprawiono te miejsca i na nowych obrazach potwierdzono, że lista zaczyna się od wersetu 1.
- Windows: 5/5 prób pytest, w tym porównanie wszystkich 73 ksiąg z oryginałem. Fizyczna klawiatura zewnętrzna oraz prywatny schowek nie były testowane. Sprawdzono ekranową klawiaturę Szukaj, systemowe okno zapisu na urządzeniu oraz osobno rzeczywisty zapis bajtów UTF-8. Nie zapisywano w prywatnym iCloud właściciela. Nie wykonano osobnej próby każdego dostępnego połączenia ustawień systemowych ani wszystkich wersji iOS od minimalnej 17.

## Wydanie oraz trwałe instrukcje

Archiwum na Macu: `~/dostepna-biblia/ios/build/TestFlight-final/Biblia.xcarchive`. Dystrybucyjny plik na obu komputerach: `ios/build/TestFlight/dostepna-biblia-1.2.0-1.ipa`. SHA-256: `770411f6d810ca5923ee42006bba3b7b55a8f5d0bbb90eabc47b246e38f5a40b`. Metadane: „dostępna biblia”, `com.dostepna.biblia`, Team `9N975WV782`, wersja 1.2.0 (1). Podpis dystrybucyjny zweryfikowano po rozpakowaniu; `beta-reports-active=true`, `get-task-allow=false`. Pakiet zawiera ikonę i manifest prywatności, bez śledzenia. Nie wykonano push, wysyłki, publikacji ani walidacji serwerowej w App Store Connect.

Sekcja o jakości interfejsów jest w aktywnym globalnym AGENTS.md, poza repozytorium. Istnieje osobna kopia sprzed zmiany. Poprzednia zawartość jest identycznym prefiksem pliku po zmianie; potwierdzono wczytanie nowej instrukcji razem z SOUL i pamięcią. Reguła dotyczy docelowej platformy, nie narzuca wyglądu iOS innym aplikacjom.

## Rozliczenie 31 wymagań

| ID | Status | Dowód |
|---|---|---|
| R-001 | gotowe | Lokalna gałąź ios wywodzi się z cc466f8. Bez publikacji i bez zmiany main. |
| R-002 | gotowe | Czytania całego dnia i pięć części sprawdzono na rzeczywistym źródle; zapis UTF-8 i otwarcie systemowych Plików w osobnych testach. |
| R-003 | gotowe | Porównano 73 księgi z C#. Próby obejmowały testamenty, domyślny wstęp, wspólny wstęp Jana, Rdz 49–50 i treść eksportu. |
| R-004 | gotowe | Na iPhonie pobrano cytaty wszystkich pięciu kategorii oraz sprawdzono otwarcie i powrót. Losowanie ponowne zachowuje kategorię. |
| R-005 | gotowe | Wyszukano frazę klawiaturą ekranową, sprawdzono obie strony nawigacji, brak wyników, pustą frazę i eksport bieżącej strony. |
| R-006 | gotowe | Na iPhonie systemowy wybieracz ma osobne regulacje w kolejności miesiąc, dzień, rok; przy dużych literach ten sam wybór ma trzy pionowo ułożone suwaki. |
| R-007 | gotowe | UITabBarController ma cztery rzeczywiste karty. Próba aktywacji i odczytu na iPhonie przeszła. |
| R-008 | gotowe | Podpisany plik Info.plist: „dostępna biblia”; com.dostepna.biblia; podpis TeamIdentifier 9N975WV782. |
| R-009 | gotowe | Audyt interfejsu Apple i rzeczywiste gesty, odczyty oraz zmiany fokusu przez usługę VoiceOver na iPhonie 17 Pro. Nie jest to opinia człowieka. |
| R-010 | gotowe | Mac przez maczek.cmd: ~/dostepna-biblia. Lokalna synchronizacja z zachowaniem wspólnej historii; wydanie ma identyczną sumę SHA-256. |
| R-011 | gotowe | Release 1.2.0 (1), archiwum i eksport lokalny IPA. Poprawny podpis Apple Distribution, beta-reports-active; bez wysyłki do Apple. |
| R-012 | gotowe | Mapa w ios/Mapa-funkcji.md opisuje także stan, domyślne akcje, pamięć podręczną, błędy, tekst, klawiaturę, dane i ograniczenia sprawdzeń. |
| R-013 | gotowe | Fizyczna usługa VoiceOver: etykiety, wartości, cecha regulacja i zmiany w obu kierunkach; kalendarz i test UI sprawdziły 31 → 29 → 28. |
| R-014 | gotowe | VoiceOver podał wybraną Liturgię i pozycje wszystkich czterech kart; podwójne stuknięcia otworzyły właściwe formularze. |
| R-015 | gotowe | Na telefonie sprawdzono kolejność daty, zmianę części, odczyt od początku treści i powrót. Kontrole automatyczne uzupełniają, nie zastępują gestów. |
| R-016 | gotowe | Git przenoszony lokalnym pakietem przez maczek.cmd; sprawdzanie historii przed synchronizacją. Nie wykonywano push. |
| R-017 | gotowe | W dystrybucyjnym IPA potwierdzono CFBundleDisplayName z „ę”, identyfikator, wersję, TeamIdentifier i application-identifier. |
| R-018 | gotowe | Instalacja i uruchomienie na sprzęcie; XCTest, dziennik Xcode i odczyty usługi VoiceOver. Niewykonane próby są opisane poniżej. |
| R-019 | gotowe | Archiwum Release, ikona, zasoby, manifest prywatności i lokalny eksport; codesign --verify --deep --strict poprawny. Nie przeprowadzano walidacji po stronie App Store Connect. |
| R-020 | gotowe | Etapy zapisane na gałęzi ios w lokalnych commitach i tym samym zestawie dokumentów zadania. |
| R-021 | gotowe | Porównanie z oryginałem, żywe źródło, realny telefon, gesty i wizualne sprawdzenie; ograniczenia wyszczególniono osobno. |
| R-022 | gotowe | Kontrolki części, testamentu, księgi, rozdziału i kategorii to suwaki. Na telefonie „Cała liturgia” → „Pierwsze czytanie” → „Cała liturgia” bez otwarcia menu. |
| R-023 | gotowe | Adaptacyjna paleta, jeden układ formularzy, rozróżnione akcje, typografia czytnika i skok do wersetu. Oględziny działających ekranów, nie makiet. |
| R-024 | gotowe | Sprawdzono AX5 na małych ekranach, pogrubienie w teście czcionki i kontrast w obu trybach. Przejścia aplikacji respektują systemowe ograniczenie ruchu (kontrola kodu). |
| R-025 | gotowe | Pięciostopniowa regulacja, wspólny podgląd i czytnik, reset i pamięć po restarcie. Test UIFontMetrics wyklucza podwójne skalowanie. |
| R-026 | gotowe | Test palety w 4 kombinacjach wyglądu i kontrastu, próby audytu systemowego. Wybrana karta ma systemowe zaznaczenie, regulacje odczytywane są słownie. |
| R-027 | gotowe | Zrzuty czterech kart, formularzy, czytnika, listy wersetów, ustawień i alertu. Obejrzano telefon oraz mały i duży symulator, jasny/ciemny i AX5. Wyjątek dodatkowego SE opisano osobno. |
| R-028 | gotowe | Po zmianach wyglądu na iPhonie przeszły próby VoiceOver daty, części, kart, powrotu i regulacji tekstu. Ikony dekoracyjne nie są osobnymi akcjami. |
| R-029 | gotowe | Opis wyglądu i poprawek poniżej oraz w instrukcji iPhone. Oceniono obrazy narzędziem wizualnym, nie zlecano oceny osobie widzącej. |
| R-030 | gotowe | Przed dopisaniem sekcji do globalnego AGENTS.md wykonano osobną kopię. Porównano oryginalne bajty, sprawdzono wczytanie nowej reguły, SOUL i pamięci; nie zmieniano hooków. |
| R-031 | gotowe | Wymagania R-023–031 w pierwotnej specyfikacji i rejestrze; jeden checkpoint, raport dla 31 identyfikatorów i lokalna historia. |
