# Rejestr wymagań — rozszerzenie portu

| ID | Warunek | Status | Źródło | Dowód |
|---|---|---|---|---|
| R-001 | Konto, granice zgody, gałąź ios i maczek.cmd (§1–3, 16). | gotowe | ios/rejestracja.txt | Lokalny ios, Mac przez maczek.cmd; bez dystrybucji, ingerencji w umowy i inne aplikacje. |
| R-002 | JWT ES256 tylko na Macu i odczyt właściwego zespołu (§3–4). | gotowe | ios/rejestracja.txt | Oficjalne GET z krótkotrwałym podpisem ES256; seedId i podpis archiwum wskazują 9N975WV782. |
| R-003 | Zweryfikować jawny identyfikator, nie dublować go ani nie włączać usług (§4). | gotowe | ios/rejestracja.txt | GET kolekcji i pojedynczego zasobu 2265A884YY: com.dostepna.biblia. Nie tworzono nowego. |
| R-004 | Sprawdzić SKU, utworzyć kartę przez obsługiwaną metodę, potwierdzić Apple App ID (§5). | zablokowane | ios/rejestracja.txt | GET apps po dokładnym bundle i SKU: brak; zalogowany użytkownik, New App → Agreement Update, nieaktualna umowa. Brak Apple App ID. |
| R-005 | Kategorie, język, nazwa, dane formalne i prawa do treści (§6, 14). | zablokowane | ios/rejestracja.txt | Wybrane Reference i Books, język pl i właściwa nazwa; brak karty do zapisu. Prawa do treści nierozstrzygnięte. |
| R-006 | Polskie pola i limity oraz poprawne autorstwo obu wersji (§7–8). | zablokowane | ios/rejestracja.txt | Komplet tekstów w screenshots/Metadane-pl.json. Limity sprawdzone; autorzy w kodzie i opisie. Brak karty do zapisu. |
| R-007 | Przepływ danych i odpowiedzi App Privacy; bez niepotwierdzonej publikacji (§9). | do_weryfikacji | ios/rejestracja.txt | Audyt w docs/Formularze-Apple.md. Serwis otrzymuje m.in. frazy i IP. Retencja i powiązanie po stronie źródła nieznane. |
| R-008 | Znaleźć politykę lub przygotować polski projekt i udokumentować brak URL (§10). | gotowe | ios/rejestracja.txt | docs/Polityka-prywatnosci-iOS.md: szkic polski; nie potwierdzono publicznego URL, kontaktu ani zasad operatora. Nie publikowano. |
| R-009 | Przeanalizować ankietę wieku, zapisać wiarygodne odpowiedzi i odczytać (§11). | do_weryfikacji | ios/rejestracja.txt | Przeanalizowano typy treści i pytania z aktualnego schematu; częstotliwość wymaga potwierdzenia. Brak zapisanej kategorii. |
| R-010 | Przygotować deklarację iPhone tylko według dowodów dostępności (§12). | do_weryfikacji | ios/rejestracja.txt | Propozycje tylko dla iPhone’a według rzeczywistych prób. Szkic lokalny; brak nowej publicznej deklaracji. |
| R-011 | Przygotować TestFlight i informacje do recenzji bez dystrybucji ani zaproszeń (§13). | zablokowane | ios/rejestracja.txt | Opis beta, instrukcja PL i uwagi EN gotowe, bez logowania; brak rekordu i potwierdzonego kontaktu. |
| R-012 | Zweryfikować grafiki, szyfrowanie, możliwości i Xcode w obu konfiguracjach (§14–15). | gotowe | ios/rejestracja.txt | Xcode Debug/Release i podpis archiwum zgodne: 1.0 (9). Test działającej aplikacji 1/1; 6 PNG z dużego symulatora oprócz 6 z telefonu. |
| R-013 | Ponowne odczyty, synchronizacja i raport wszystkich 23 pozycji (§16–17). | w_toku | ios/rejestracja.txt | Powtórzono oficjalne odczyty. Raport poniżej; po odblokowaniu powtórzyć sprawdzenie i dokończyć zależne zapisy. |
