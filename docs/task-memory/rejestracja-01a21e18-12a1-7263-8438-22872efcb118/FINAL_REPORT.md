# Apple Developer i App Store Connect — dostępna biblia

Stan po utworzeniu karty i sprawdzeniu zapisów, 27 listopada 2026. Dotyczy wyłącznie tej aplikacji. Dokument nie potwierdza publikacji.

1. **Autoryzacja:** działa ES256 z kluczem pozostającym na Macu. Sprawdzono rzeczywiste odczyty, bez drukowania klucza, wystawcy i tokenów.
2. **Zespół:** 9N975WV782 potwierdzony przez seedId zasobu Apple, lokalną konfigurację i podpis archiwum.
3. **Identyfikator:** com.dostepna.biblia już istniał pod nazwą techniczną „XC com dostepna biblia”, zasób Developer 2265A884YY, platforma UNIVERSAL. Odczyt listy możliwości pokazał IN_APP_PURCHASE; zastany wpis, nie aktywowano go w tej operacji. Kod nie oferuje zakupów.
4. **Rekord sklepu:** po przyjęciu umowy przez właściciela otwarto ponownie New App; utworzono kartę przez Safari, platforma iOS, ograniczony dostęp zespołu bez wskazywania nowych użytkowników. Wersja 1.0 ma stan PREPARE_FOR_SUBMISSION.
5. **Apple App ID: 6840151385.** [Karta w App Store Connect](https://appstoreconnect.apple.com/apps/6840151385/distribution/info).
6. **Zapisane:** dokładnie „dostępna biblia”, DOSTEPNA-BIBLIA-IOS, com.dostepna.biblia, język pl. Dwa wyszukania (SKU i bundle) zwróciły ten sam rekord.
7. **App Information:** zapisano i odczytano kategorię podstawową Reference oraz dodatkową Books; podtytuł „Biblia i liturgia z VoiceOver”.
8. **Lokalizacja:** na karcie pl zapisano i ponownie porównano opis (w tym obie role autorskie), słowa kluczowe i tekst promocyjny z screenshots/Metadane-pl.json. Pierwsze wydanie, bez What’s New.
9. **App Privacy:** w Safari otwarto Get Started. Pierwsze pytanie wymaga odpowiedzi tak/nie także za partnerów; nie mamy informacji o retencji fraz i IP przez dostawcę. Anulowano bez zapisu i bez publikacji.
10. **Polityka:** docs/Polityka-prywatnosci-iOS.md; brak potwierdzonego publicznego adresu i danych kontaktowych do opublikowania.
11. **Wiek:** próba PATCH odpowiedzi o funkcjach i rozpoznanych treściach zwróciła HTTP 409. Apple wymaga równocześnie pięciu pól: wulgarny humor/język, długotrwała drastyczna lub sadystyczna przemoc, dosłowne treści seksualne/nagość, tematy grozy i przemoc fantastyczna. Formularz WWW rozpoczyna się od kroku funkcji z przyciskami anulowania i przejścia dalej. Odczyt po błędzie potwierdza, że odpowiedzi nie zapisano. Nie przypisywać aplikacji żadnej kategorii. Szczególnie [2 Mch 7](https://twojabiblia.pl/czytaj/2-Mch/7/) i [Sdz 19](https://twojabiblia.pl/czytaj/Sdz/19/) wymagają rozróżnienia opisu literackiego od szczególnej kategorii Apple; jej zaznaczenie nawet jako sporadycznej może oznaczać brak klasyfikacji dla App Store. Nie zgadywano w żadną stronę.
12. **Dostępność:** zapisano dla iPhone’a VoiceOver, większy tekst, ciemny wygląd, rozróżnianie bez koloru i kontrast. GET potwierdził wartości, Safari pokazało Drafts (1). Nie naciskano Publish. Brak deklaracji sterowania głosem, napisów, audiodeskrypcji i ograniczenia ruchu.
13. **Recenzja:** w danych beta i recenzji sklepowej zapisano instrukcje po angielsku i brak wymogu konta. Na wyraźne polecenie właściciela kontakt pozostał pusty: sprawdzono cztery pola obu formularzy bez wypisywania danych osobistych.
14. **TestFlight:** zapisano i ponownie odczytano polski opis beta z instrukcją testów. Nie przesłano aplikacji ani nie rozpoczęto testów. Opisu dla konkretnej binarnej kompilacji nie można powiązać bez tej kompilacji.
15. **Weryfikacja:** końcowy odczyt sprawdził identyfikatory, stan wersji, kategorie, polskie teksty, dane obydwu recenzji, szkic dostępności i dwa zestawy obrazów (12/12 COMPLETE, poprawna kolejność). GET builds zwrócił pustą listę.
16. **WWW:** po zalogowaniu i przyjęciu umowy przez właściciela utworzono rekord, sprawdzono szkic dostępności, rzeczywiste pytanie o zbieranie danych oraz początek ankiety wieku. VoiceOver pozostał włączony, nie ingerowano w umowy.
17. **Zakres REST:** sprawdzono oficjalny schemat OpenAPI: brak POST /v1/apps oraz publicznego formularza typów danych App Privacy. Zasoby kategorii, lokalizacji, wieku, dostępności i beta wymagają karty. [Tworzenie karty](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/) · [Zasób Apps](https://developer.apple.com/documentation/appstoreconnectapi/apps).
18. **Nadal otwarte:** prawa do treści, publiczne adresy wsparcia/prywatności, potwierdzenie praktyk operatora źródła i końcowa ocena wieku. Kontakt pusty na życzenie. Nie deklarowano dostępności w konkretnych krajach ani zgodności regionalnej bez potwierdzenia. Nie zmieniano finansów.
19. **Prawa:** nie udokumentowano, że zgoda dla TwojaBiblia.pl obejmuje dystrybucję tego portu, teksty liturgiczne, syntezę i eksport TXT; nie złożono oświadczenia. Autorstwa aplikacji to nie prawa do przekładu.
20. **Xcode:** projekt ~/dostepna-biblia/ios/Biblia.xcodeproj; Debug i Release: podpis automatyczny, zgodny zespół, bundle, dokładna nazwa, wersja 1.0 (9). Zweryfikowano istniejące archiwum codesign --verify --deep --strict, tryb tła tylko audio, szyfrowanie niezwolnione = false. Bez niepotrzebnego archiwizowania nowego numeru.
21. **Uprawnienia:** odczyt i zapis kluczem potwierdzono dla użytych zasobów. Pierwotna blokada umowna ustąpiła. Odmowa częściowego zapisu wieku to walidacja formularza, nie uprawnień.
22. **Wykonane:** rejestracja karty, uzupełnienie i ponowne odczyty metadanych, danych recenzji i beta, szkicu dostępności oraz dwunastu zrzutów, audyt kodu i Xcode, projekty dokumentów prywatności. Bez zmian w innych aplikacjach.
23. **Osobna zgoda:** wysyłka buildu, recenzja App Store lub zewnętrzna TestFlight, zaproszenia, dystrybucja, publikacja polityki; żadnej nie wykonano. Przyjęcie umowy to decyzja właściciela.

## Rozliczenie wymagań

| ID | Status | Wynik |
|---|---|---|
| R-001 | gotowe | Lokalny ios, Mac przez maczek.cmd; bez dystrybucji, ingerencji w umowy i inne aplikacje. |
| R-002 | gotowe | Oficjalne GET z krótkotrwałym podpisem ES256; seedId i podpis archiwum wskazują 9N975WV782. |
| R-003 | gotowe | GET kolekcji i pojedynczego zasobu 2265A884YY: com.dostepna.biblia. Nie tworzono nowego. |
| R-004 | gotowe | Po przyjęciu umowy utworzono kartę przez WWW. GET po bundle i SKU potwierdził Apple App ID 6840151385, nazwę dokładnie „dostępna biblia” i język pl. |
| R-005 | do_weryfikacji | App Information: zapis i niezależny odczyt Reference oraz Books, iOS/pl. Oświadczenie o prawach oczekuje na dowód licencji. |
| R-006 | gotowe | Nazwa, podtytuł, opis z autorami, frazy i promocja rzeczywiście zapisane w polskiej lokalizacji; wartości odczytane i porównane z projektem. |
| R-007 | do_weryfikacji | Sprawdzono aktualny formularz WWW: na wejściu wymaga odpowiedzi tak/nie dla wydawcy i partnerów. Retencja TwojaBiblia.pl niepotwierdzona; anulowano bez deklaracji. |
| R-008 | gotowe | docs/Polityka-prywatnosci-iOS.md: szkic polski; nie potwierdzono publicznego URL, kontaktu ani zasad operatora. Nie publikowano. |
| R-009 | do_weryfikacji | Próba zapisu częściowej ankiety odrzucona przez Apple (409, pięć wymaganych pól). Ponowny odczyt potwierdza brak zapisu. Robocza macierz i fragmenty wymagające oceny w raporcie. |
| R-010 | gotowe | Zapisano pięć potwierdzonych cech iPhone’a, ponownie odczytano API i sprawdzono WWW: Drafts (1), nie publikowano. |
| R-011 | gotowe | Opis beta po polsku, instrukcje recenzenta i brak logowania zapisane w beta oraz instrukcje i brak logowania w App Review wersji 1.0. Kontakt pusty na polecenie właściciela, potwierdzono odczytem. |
| R-012 | gotowe | Debug/Release i podpis 1.0 (9) zgodne. Na polskiej karcie 6 kadrów fizycznego telefonu i 6 dużego symulatora, wszystkie COMPLETE, potwierdzono kolejność. |
| R-013 | gotowe | Kontrola końcowa zasobów Apple, oba zestawy grafik, wersja PREPARE_FOR_SUBMISSION, brak buildu na koncie. Pełny raport 23 pozycji. |
