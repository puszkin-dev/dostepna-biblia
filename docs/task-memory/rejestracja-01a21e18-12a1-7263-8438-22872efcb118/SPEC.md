# Rejestracja — rozszerzenie portu iOS

Źródło w całości: `ios/rejestracja.txt` (§1–17 i cel ostateczny). Kontynuacja portu iOS i wydania z czytaniem; nie ponawiamy zakończonych odbiorów. Dziedziczone rejestry: `../port-ios-01a21e18-12a1-7263-8438-22872efcb118/TASK_REQUIREMENTS.md` i `../czytanie-glos-01a21e18-12a1-7263-8438-22872efcb118/TASK_REQUIREMENTS.md`. Konto tylko dla tej aplikacji. Bez zmieniania umów, finansów, innych aplikacji, wysyłki, publikacji i zewnętrznych testów. Informować na bieżąco.

R-001 — Konto, granice zgody, gałąź ios i maczek.cmd (§1–3, 16).

R-002 — JWT ES256 tylko na Macu i odczyt właściwego zespołu (§3–4).

R-003 — Zweryfikować jawny identyfikator, nie dublować go ani nie włączać usług (§4).

R-004 — Sprawdzić SKU, utworzyć kartę przez obsługiwaną metodę, potwierdzić Apple App ID (§5).

R-005 — Kategorie, język, nazwa, dane formalne i prawa do treści (§6, 14).

R-006 — Polskie pola i limity oraz poprawne autorstwo obu wersji (§7–8).

R-007 — Przepływ danych i odpowiedzi App Privacy; bez niepotwierdzonej publikacji (§9).

R-008 — Znaleźć politykę lub przygotować polski projekt i udokumentować brak URL (§10).

R-009 — Przeanalizować ankietę wieku, zapisać wiarygodne odpowiedzi i odczytać (§11).

R-010 — Przygotować deklarację iPhone tylko według dowodów dostępności (§12).

R-011 — Przygotować TestFlight i informacje do recenzji bez dystrybucji ani zaproszeń (§13).

R-012 — Zweryfikować grafiki, szyfrowanie, możliwości i Xcode w obu konfiguracjach (§14–15).

R-013 — Ponowne odczyty, synchronizacja i raport wszystkich 23 pozycji (§16–17).

Doprecyzowania: R-004/R-006 — oba słowa małymi literami; R-011 — na polecenie właściciela kontakt do recenzji pozostaje pusty.

## Dopiski właściciela — strony i pozostałe pola

Zastąpiono poprzednie polecenie o pustym kontakcie: dane Grzegorza Przystupy w obu formularzach. Właściciel wskazał do Copyright aplikacji iOS Mieczysława Bąka i aktualny rok. Publiczny dostęp do źródła został wskazany przez właściciela; nie posiada informacji o retencji u operatora. Uzupełnić maksymalnie dużo pól samodzielnie, zrozumiale opisać korzystanie z usług, nie deklarować niepotwierdzonych faktów. Zgoda na WWW nie jest zgodą na wydanie w sklepie.

R-014 — Opublikować strony marketingu/wsparcia i polityki prywatności bez podkatalogu; obaj autorzy i pierwowzór na obu stronach.

R-015 — Powiązać działające publiczne strony z aplikacją i kartą, sprawdzić wygląd, dostępność, archiwum i telefon.

R-016 — Wypełnić potwierdzony kontakt w obu formularzach, prawa do programu i rzetelne instrukcje recenzji.

R-017 — Numer kompilacji zmienia wyłącznie jawne uruchomienie podbij_build.sh. Przywrócono 1.0 (10); Archive nie zwiększa licznika. Nazwa projektu Xcode, schematu, targetu aplikacji, produktu i nowych archiwów: „dostępna biblia”. Alias na biurku prowadzi do przemianowanego projektu. Dopisek zastępuje wcześniejszy automatyczny przyrost przy archiwizacji. Nie zmienia identyfikatora pakietu ani historii starych archiwów.

Aktualizacja R-017: numer początkowy pierwszego wydania to 1 (zastępuje 10); bez zmian w zasadzie ręcznego podbijania, nazwie i wersji 1.0.

R-018 — Korekta R-017: techniczne nazwy w Xcode, ścieżki .app/.ipa i nowe archiwa bez „ę” („dostepna biblia”). Pod ikoną oraz w sklepie nadal „dostępna biblia”. Bez zmiany numeru i identyfikatora.

## 28.11.2026 — ustawienia mowy po testach

Źródło: oba zgłoszenia z `ios/babcia.txt` oraz późniejsze polecenie właściciela dotyczące języka. R-019 — prześledzić skalę od regulacji do wypowiedzi, zapewnić krok 5 punktów, spójność i migrację starych ustawień. R-020 — zidentyfikować przyczynę pozornych duplikatów, rozróżnić silniki i ich warianty, zachować wybór po restarcie; po doprecyzowaniu widoczne i używane mają być wyłącznie głosy języka polskiego. R-021 — sprawdzić regulacje, komunikaty i wybór gestami rzeczywistego VoiceOver oraz udokumentować granice pomiaru.

## ElevenLabs — rozszerzenie odczytu iOS

Pełne źródło prywatne: `ios/elevenlabs.txt`. R-022: wybór silnika, bezpieczny klucz użytkownika, sprawdzenie bez generacji, głosy konta i polska próbka wybranego głosu. R-023: polski eleven_v4, strumieniowy MP3, oczyszczenie bez utraty treści i podział najwyżej po 10 000 znaków. R-024: odtwarzanie przy napływie danych, najwyżej jeden następny fragment, brak równoległych duplikatów, anulowanie, atomowy cache. R-025: zachowanie sesji, wznowienie z pozycją, rozłączne polskie błędy i brak automatycznych płatnych ponowień. R-026: odbiór na telefonie, VoiceOver i API odroczony na wyraźne polecenie do otrzymania klucza; przygotować przypadki, nie uruchamiać testów.
