# Apple Developer i App Store Connect — dostępna biblia

Stan po utworzeniu karty i sprawdzeniu zapisów, 27 listopada 2026. Dotyczy wyłącznie tej aplikacji. Dokument nie potwierdza publikacji.

1. **Autoryzacja:** działa ES256 z kluczem pozostającym na Macu. Sprawdzono rzeczywiste odczyty, bez drukowania klucza, wystawcy i tokenów.
2. **Zespół:** 9N975WV782 potwierdzony przez seedId zasobu Apple, lokalną konfigurację i podpis archiwum.
3. **Identyfikator:** com.dostepna.biblia już istniał pod nazwą techniczną „XC com dostepna biblia”, zasób Developer 2265A884YY, platforma UNIVERSAL. Odczyt listy możliwości pokazał IN_APP_PURCHASE; zastany wpis, nie aktywowano go w tej operacji. Kod nie oferuje zakupów.
4. **Rekord sklepu:** po przyjęciu umowy przez właściciela otwarto ponownie New App; utworzono kartę przez Safari, platforma iOS, ograniczony dostęp zespołu bez wskazywania nowych użytkowników. Wersja 1.0 ma stan PREPARE_FOR_SUBMISSION.
5. **Apple App ID: 6840151385.** [Karta w App Store Connect](https://appstoreconnect.apple.com/apps/6840151385/distribution/info).
6. **Zapisane:** dokładnie „dostępna biblia”, DOSTEPNA-BIBLIA-IOS, com.dostepna.biblia, język pl. Dwa wyszukania (SKU i bundle) zwróciły ten sam rekord.
7. **App Information:** Zapisano Reference i Books, polski podtytuł oraz Copyright wersji „2026 Mieczysław Bąk”. Informacje o prawach do kodu i do tekstów są odrębne.
8. **Lokalizacja:** na karcie pl zapisano i ponownie porównano opis (w tym obie role autorskie), słowa kluczowe i tekst promocyjny z screenshots/Metadane-pl.json. Pierwsze wydanie, bez What’s New.
9. **App Privacy:** Otworzono formularz w Safari. Właściciel nie ma informacji o retencji TwojaBiblia.pl, publiczne materiały nie rozstrzygają przechowywania IP i fraz przez serwis lub hosting. Ustalono przepływy, ale nie zaznaczono odpowiedzi za operatora i nie opublikowano etykiety. Publiczny URL prywatności i URL kontaktu dotyczącego danych zapisano niezależnie.
10. **Polityka:** [Polityka prywatności](https://axelek.pl/dostepna-biblia-prywatnosc.html) opublikowana na polecenie właściciela. [Strona marketingowa](https://axelek.pl/dostepna-biblia.html), pomoc #pomoc i kontakt dotyczący danych #kontakt działają. Obie strony wymieniają pomysł i autorstwo Windows Grzegorza Przystupy, projekt iOS Mieczysława Bąka i repozytorium pierwowzoru.
11. **Wiek:** próba PATCH odpowiedzi o funkcjach i rozpoznanych treściach zwróciła HTTP 409. Apple wymaga równocześnie pięciu pól: wulgarny humor/język, długotrwała drastyczna lub sadystyczna przemoc, dosłowne treści seksualne/nagość, tematy grozy i przemoc fantastyczna. Formularz WWW rozpoczyna się od kroku funkcji z przyciskami anulowania i przejścia dalej. Odczyt po błędzie potwierdza, że odpowiedzi nie zapisano. Nie przypisywać aplikacji żadnej kategorii. Szczególnie [2 Mch 7](https://twojabiblia.pl/czytaj/2-Mch/7/) i [Sdz 19](https://twojabiblia.pl/czytaj/Sdz/19/) wymagają rozróżnienia opisu literackiego od szczególnej kategorii Apple; jej zaznaczenie nawet jako sporadycznej może oznaczać brak klasyfikacji dla App Store. Nie zgadywano w żadną stronę.
12. **Dostępność:** zapisano dla iPhone’a VoiceOver, większy tekst, ciemny wygląd, rozróżnianie bez koloru i kontrast. GET potwierdził wartości, Safari pokazało Drafts (1). Nie naciskano Publish. Brak deklaracji sterowania głosem, napisów, audiodeskrypcji i ograniczenia ruchu.
13. **Recenzja:** Dla obu recenzji potwierdzono kontakt Grzegorza Przystupy (4 pola), brak potrzeby logowania oraz nowe instrukcje sprawdzenia faktycznych funkcji, sieci, syntezy, zapisu i odnośników. Telefon nie jest podany na stronach.
14. **TestFlight:** Polski opis beta, adres zwrotny, marketing i prywatność zapisane. Brak kompilacji w Apple; pola przypisane do konkretnego buildu nie dotyczą jeszcze żadnego rekordu.
15. **Weryfikacja:** Oddzielne odczyty potwierdziły identyfikator, stan wersji, kategorie, polskie teksty, oba formularze recenzji, wszystkie adresy (w tym dostępności), Copyright i 12/12 obrazów COMPLETE. Wydanie ustawione na ręczne (MANUAL). Lista buildów pusta.
16. **WWW:** po zalogowaniu i przyjęciu umowy przez właściciela utworzono rekord, sprawdzono szkic dostępności, rzeczywiste pytanie o zbieranie danych oraz początek ankiety wieku. VoiceOver pozostał włączony, nie ingerowano w umowy.
17. **Zakres REST:** sprawdzono oficjalny schemat OpenAPI: brak POST /v1/apps oraz publicznego formularza typów danych App Privacy. Zasoby kategorii, lokalizacji, wieku, dostępności i beta wymagają karty. [Tworzenie karty](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/) · [Zasób Apps](https://developer.apple.com/documentation/appstoreconnectapi/apps).
18. **Nadal otwarte:** Otwarte: licencja na użycie zewnętrznych treści i retencja u operatora, co blokuje oświadczenie o prawach i końcową etykietę prywatności. Klasyfikacja wieku nie została nadana (pkt 11). Przyszły wybór krajów i ustawień handlowych poza zakresem tej operacji. Dane kontaktowe i adresy stron nie są już brakami.
19. **Prawa:** nie udokumentowano, że zgoda dla TwojaBiblia.pl obejmuje dystrybucję tego portu, teksty liturgiczne, syntezę i eksport TXT; nie złożono oświadczenia. Autorstwa aplikacji to nie prawa do przekładu.
20. **Xcode:** Nowe archiwum Release i lokalny eksport 1.0 (10) na obu maszynach; SHA-256 IPA 5352d14d6e7a1528fe0ca7b2a4add8d7efba17a5e9d21490d41d5074d7a31451. Sprawdzony podpis i zespół. Zainstalowano i uruchomiono aplikację z archiwum na fizycznym iPhonie 17 Pro. Tło tylko dla czytania audio; brak własnych algorytmów szyfrowania.
21. **Uprawnienia:** odczyt i zapis kluczem potwierdzono dla użytych zasobów. Pierwotna blokada umowna ustąpiła. Odmowa częściowego zapisu wieku to walidacja formularza, nie uprawnień.
22. **Wykonane:** Zarejestrowano kartę, zapisano i sprawdzono metadane, odnośniki, obie recenzje i szkic dostępności, zrzuty oraz ręczny tryb wydania. Na osobne polecenie opublikowano WWW przez axel.cmd; archiwum i audyt telefonu wykonano przez maczek.cmd. Nie zmieniano innych aplikacji.
23. **Osobna zgoda:** Nie wysłano binarnego buildu, wersji do recenzji, zaproszeń, zapytania do operatora ani Apple. Nie uruchomiono dystrybucji. Wyraźna osobna zgoda dotyczyła jedynie publikacji stron WWW; przyjęcie umowy było decyzją właściciela.

## Test stron, aplikacji i dalsze potwierdzenia

Pięć plików wprost w /home/axel/www/. Publiczne odpowiedzi HTTPS i treść sprawdzone; sześć scenariuszy Chrome/axe: oba dokumenty, duży jasny ekran, mały ciemny ekran i 320 pikseli z dwukrotnym tekstem. Bez wykrytych naruszeń badanych reguł; sprawdzono klawiaturę, nagłówki, role autorów i brak poziomego przewijania. Obejrzano rzeczywiste zrzuty, bez przypisywania tej oceny człowiekowi. Osobne testy na fizycznym iPhonie otworzyły z ustawień oba odnośniki i potwierdziły odczyt odpowiednich nagłówków w Safari przez usługę VoiceOver (Www-links3: 2/2). Na Windowsie: pytest 7 zaliczonych, 7 pominiętych. Plik IPA: ios/build/TestFlight/dostepna-biblia-1.0-10.ipa.

[Kryteria stron i usług zewnętrznych Apple](https://developer.apple.com/app-store/review/guidelines/) · [Informacja o wydaniu przekładu](https://biblia.pl/informacje-o-wydaniu/) · [Analiza formularzy, proponowane odpowiedzi o wieku oraz niewysłana wiadomość do operatora](../../Formularze-Apple.md).

## Rozliczenie wymagań

| ID | Status | Wynik |
|---|---|---|
| R-001 | gotowe | Lokalny ios, Mac przez maczek.cmd; bez dystrybucji, ingerencji w umowy i inne aplikacje. |
| R-002 | gotowe | Oficjalne GET z krótkotrwałym podpisem ES256; seedId i podpis archiwum wskazują 9N975WV782. |
| R-003 | gotowe | GET kolekcji i pojedynczego zasobu 2265A884YY: com.dostepna.biblia. Nie tworzono nowego. |
| R-004 | gotowe | Po przyjęciu umowy utworzono kartę przez WWW. GET po bundle i SKU potwierdził Apple App ID 6840151385, nazwę dokładnie „dostępna biblia” i język pl. |
| R-005 | do_weryfikacji | App Information: zapis i niezależny odczyt Reference oraz Books, iOS/pl. Oświadczenie o prawach oczekuje na dowód licencji. Prawa do programu: 2026 Mieczysław Bąk, odczyt Apple. Zgoda wymieniona w stopce serwisu dotyczy serwisu; nie znaleziono publicznych warunków dla tego portu. |
| R-006 | gotowe | Nazwa, podtytuł, opis z autorami, frazy i promocja rzeczywiście zapisane w polskiej lokalizacji; wartości odczytane i porównane z projektem. |
| R-007 | do_weryfikacji | Sprawdzono aktualny formularz WWW: na wejściu wymaga odpowiedzi tak/nie dla wydawcy i partnerów. Retencja TwojaBiblia.pl niepotwierdzona; anulowano bez deklaracji. |
| R-008 | gotowe | Polityka opublikowana na axelek.pl i podłączona w aplikacji, App Information oraz TestFlight. Brak danych operatora jasno opisano. |
| R-009 | do_weryfikacji | Próba zapisu częściowej ankiety odrzucona przez Apple (409, pięć wymaganych pól). Ponowny odczyt potwierdza brak zapisu. Robocza macierz i fragmenty wymagające oceny w raporcie. |
| R-010 | gotowe | Zapisano pięć potwierdzonych cech iPhone’a, ponownie odczytano API i sprawdzono WWW: Drafts (1), nie publikowano. |
| R-011 | gotowe | Obie recenzje: brak konta, instrukcje z rzeczywistymi przykładami, podane przez właściciela pełne dane kontaktowe. Polski opis, kontakt zwrotny i URL beta potwierdzone ponownym GET. |
| R-012 | gotowe | Dwa zestawy po sześć kadrów COMPLETE. Archiwum i eksport wydania 1.0 (10), podpis, instalacja i uruchomienie archiwalnej aplikacji na iPhonie. |
| R-013 | gotowe | Kontrola końcowa zasobów Apple, oba zestawy grafik, wersja PREPARE_FOR_SUBMISSION, brak buildu na koncie. Pełny raport 23 pozycji. |
| R-014 | gotowe | Bezpośrednie publiczne adresy HTTPS, 5 plików w /home/axel/www/, bez podfolderu. Obie pełne role i link do pierwowzoru na każdej stronie. |
| R-015 | gotowe | Na publicznych stronach 6/6 prób Chrome/axe; oba nagłówki odczytane przez usługę VoiceOver w Safari na fizycznym iPhonie po otwarciu z Ustawień (Www-links3). |
| R-016 | gotowe | Adresy, 4 pola kontaktu w każdym formularzu, Copyright oraz notatki weryfikowane osobnymi odczytami. Telefon niewidoczny na WWW. |
