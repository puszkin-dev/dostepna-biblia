# Apple Developer i App Store Connect — dostępna biblia

Stan etapu przed zniesieniem blokady umownej, 27 listopada 2026. Dotyczy wyłącznie tej aplikacji. Dokument nie potwierdza publikacji.

1. **Autoryzacja:** działa ES256 z kluczem pozostającym na Macu. Sprawdzono rzeczywiste odczyty, bez drukowania klucza, wystawcy i tokenów.
2. **Zespół:** 9N975WV782 potwierdzony przez seedId zasobu Apple, lokalną konfigurację i podpis archiwum.
3. **Identyfikator:** com.dostepna.biblia już istniał pod nazwą techniczną „XC com dostepna biblia”, zasób Developer 2265A884YY, platforma UNIVERSAL. Odczyt listy możliwości pokazał IN_APP_PURCHASE; zastany wpis, nie aktywowano go w tej operacji. Kod nie oferuje zakupów.
4. **Rekord sklepu:** API zwróciło pustą listę po dokładnym bundle. W zalogowanym Safari wybrano New App; zamiast formularza Apple wyświetliło Agreement Update dotyczące nieaktualnej umowy aplikacji płatnych. Właściciel zajmuje się umową osobiście na Windowsie.
5. **Numeryczny Apple App ID:** brak. Identyfikator zasobu Developer z punktu 3 nie jest numerem aplikacji sklepowej.
6. **Nazwa i SKU:** plan „dostępna biblia” i DOSTEPNA-BIBLIA-IOS; filtr SKU nie wykazał widocznego konfliktu. Nie zarezerwowane.
7. **App Information:** brak zapisu; wybrane iOS, polski, Reference/Books.
8. **Lokalizacja:** gotowa lokalnie w screenshots/Metadane-pl.json, w tym podtytuł, opis, słowa kluczowe i promocja. Brak What’s New dla pierwszej wersji. Nie wprowadzono fikcyjnych adresów.
9. **App Privacy:** zbadano kod i usługi; szczegółowa kwalifikacja w docs/Formularze-Apple.md. Nie zatwierdzono „Data Not Collected”.
10. **Polityka:** docs/Polityka-prywatnosci-iOS.md; brak potwierdzonego publicznego adresu i danych kontaktowych do opublikowania.
11. **Wiek:** brak zadeklarowanej kategorii lub wyniku z Apple. Lokalna ocena pytań i opisów treści, w tym wojny, przemocy i broni; nie wybrano 4+.
12. **Dostępność:** lokalna macierz i dowody dla iPhone’a; bez publikacji. Nie obiecano nieprzetestowanych udogodnień.
13. **Beta App Review:** przygotowano instrukcje EN i odpowiedź „bez logowania”; brak zapisanych informacji np. kontaktu recenzenckiego.
14. **TestFlight:** przygotowany opis po polsku, scenariusz odsłuchu, testowania i eksportu; brak grup, zaproszeń i publicznego linku.
15. **Odczyty API:** kolekcja i pojedynczy Bundle ID, możliwości, odczyty aplikacji po bundle i SKU. Żaden zapis nie nastąpił — nie ma nowych zasobów do odczytu po zapisie.
16. **WWW:** użytkownik zalogował się do Safari. Natywne drzewo dostępności pozwoliło obsłużyć menu i odczytać faktyczną blokadę, bez wyłączania VoiceOver.
17. **Zakres REST:** sprawdzono oficjalny schemat OpenAPI: brak POST /v1/apps oraz publicznego formularza typów danych App Privacy. Zasoby kategorii, lokalizacji, wieku, dostępności i beta wymagają karty. [Tworzenie karty](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/) · [Zasób Apps](https://developer.apple.com/documentation/appstoreconnectapi/apps).
18. **Pola oczekujące:** utworzenie karty, lokalizacje, zrzuty w portalu, kategorie, URL wsparcia/prywatności, ankiety wieku i prywatności, prawa do treści, kontakt dla recenzenta i beta. Adres marketingowy opcjonalny. Bez zmian cen, umów i danych finansowych.
19. **Prawa:** nie udokumentowano, że zgoda dla TwojaBiblia.pl obejmuje dystrybucję tego portu, teksty liturgiczne, syntezę i eksport TXT; nie złożono oświadczenia. Autorstwa aplikacji to nie prawa do przekładu.
20. **Xcode:** projekt ~/dostepna-biblia/ios/Biblia.xcodeproj; Debug i Release: podpis automatyczny, zgodny zespół, bundle, dokładna nazwa, wersja 1.0 (9). Zweryfikowano istniejące archiwum codesign --verify --deep --strict, tryb tła tylko audio, szyfrowanie niezwolnione = false. Bez niepotrzebnego archiwizowania nowego numeru.
21. **Uprawnienia:** odczyt kluczem działa; uprawnień zapisu do metadanych nie da się potwierdzić odczytem. Znana przeszkoda dotyczy umowy w WWW, a nie błędnego JWT.
22. **Faktyczne prace:** odczyty Apple, próba w Safari, weryfikacja Xcode, audyt kodu, lokalne materiały i sześć nowych zrzutów 1320 × 2868 (symulator); bez naruszania sześciu rzeczywistych zrzutów iPhone’a 1206 × 2622.
23. **Osobna zgoda:** wysyłka buildu, recenzja App Store lub zewnętrzna TestFlight, zaproszenia, dystrybucja, publikacja polityki; żadnej nie wykonano. Przyjęcie umowy to decyzja właściciela.

## Rozliczenie wymagań

| ID | Status | Wynik |
|---|---|---|
| R-001 | gotowe | Lokalny ios, Mac przez maczek.cmd; bez dystrybucji, ingerencji w umowy i inne aplikacje. |
| R-002 | gotowe | Oficjalne GET z krótkotrwałym podpisem ES256; seedId i podpis archiwum wskazują 9N975WV782. |
| R-003 | gotowe | GET kolekcji i pojedynczego zasobu 2265A884YY: com.dostepna.biblia. Nie tworzono nowego. |
| R-004 | zablokowane | GET apps po dokładnym bundle i SKU: brak; zalogowany użytkownik, New App → Agreement Update, nieaktualna umowa. Brak Apple App ID. |
| R-005 | zablokowane | Wybrane Reference i Books, język pl i właściwa nazwa; brak karty do zapisu. Prawa do treści nierozstrzygnięte. |
| R-006 | zablokowane | Komplet tekstów w screenshots/Metadane-pl.json. Limity sprawdzone; autorzy w kodzie i opisie. Brak karty do zapisu. |
| R-007 | do_weryfikacji | Audyt w docs/Formularze-Apple.md. Serwis otrzymuje m.in. frazy i IP. Retencja i powiązanie po stronie źródła nieznane. |
| R-008 | gotowe | docs/Polityka-prywatnosci-iOS.md: szkic polski; nie potwierdzono publicznego URL, kontaktu ani zasad operatora. Nie publikowano. |
| R-009 | do_weryfikacji | Przeanalizowano typy treści i pytania z aktualnego schematu; częstotliwość wymaga potwierdzenia. Brak zapisanej kategorii. |
| R-010 | do_weryfikacji | Propozycje tylko dla iPhone’a według rzeczywistych prób. Szkic lokalny; brak nowej publicznej deklaracji. |
| R-011 | zablokowane | Opis beta, instrukcja PL i uwagi EN gotowe, bez logowania; brak rekordu i potwierdzonego kontaktu. |
| R-012 | gotowe | Xcode Debug/Release i podpis archiwum zgodne: 1.0 (9). Test działającej aplikacji 1/1; 6 PNG z dużego symulatora oprócz 6 z telefonu. |
| R-013 | w_toku | Powtórzono oficjalne odczyty. Raport poniżej; po odblokowaniu powtórzyć sprawdzenie i dokończyć zależne zapisy. |
