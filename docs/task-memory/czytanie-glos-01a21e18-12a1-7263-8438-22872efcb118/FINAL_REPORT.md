# Czytanie na głos i Ustawienia

Etap: działający czytnik i ustawienia. Trwają końcowe testy urządzenia, audyt i sprawdzenie lokalnego wydania. Pełna specyfikacja w ios/ustawienia.txt.

| ID | Status | Wynik i dowód |
|---|---|---|
| R-001 | gotowe | AVSpeechSynthesizer na iPhonie 17 Pro; wspólna instancja, brak sieci w silniku i brak mikrofonu. |
| R-002 | gotowe | Wspólny TextScreen zasila mowę wyłącznie Reading.text. MowaTelefon2: Biblia, psalm, liturgia, pauza, wznowienie, restart i stop na urządzeniu. |
| R-003 | gotowe | Pięć natywnych kart. Audyt kart i aktywacja każdej przez rzeczywistą usługę VoiceOver. Rozmiar korzysta nadal z jednego ReadingSettings i jednego klucza. |
| R-004 | do_weryfikacji | Ekran Autorzy i źródła: obie role, oba nazwiska, wersja/kompilacja z Bundle i odnośnik systemowy. Dokumentacja Windows, stopka TwojaBiblia.pl i informacja Pallottinum. Nie potwierdzono praw do dystrybucji aplikacji. |
| R-005 | gotowe | 112 pozycji z polskim kodem języka w rzeczywistym API tego telefonu, w tym głosy rozszerzeń. Kod sortuje głosy polskie na początku. Próba brakującego ID z rzeczywistym silnikiem. |
| R-006 | do_weryfikacji | Trzy ChoiceSlider; parametry i reset w UserDefaults. Próby wartości uszkodzonych i skrajnych. Sprawdzić końcową próbę trwałości w UI. |
| R-007 | gotowe | Próbka zmienia przyciski po uruchomieniu i końcu; z aplikacją uruchomioną bez VO na iPhonie, MowaTelefon1. |
| R-008 | do_weryfikacji | Potwierdzono przejście na ekran początkowy i powrót podczas czytania. Sygnały przerwania i odłączenia trasy testowe; fizycznych słuchawek i rzeczywistej rozmowy telefonicznej nie testowano. |
| R-009 | do_weryfikacji | Jasny iPhone 17 Pro i ciemny 13 mini z AX5. Poprawiono paski i link po oględzinach: równe kontrolki z symbolami w trakcie mowy przy dużym tekście. Trwa próba końcowa na sprzęcie. |
| R-010 | w_toku | Testy fizyczne w toku. Nie zastępować odsłuchu człowieka odczytem stanu i nie zaliczać niedostępnych akcesoriów. |
| R-011 | w_toku | Lokalna gałąź ios, maczek.cmd, bez wysyłki i bez modyfikacji repozytorium Windows na GitHubie. |
