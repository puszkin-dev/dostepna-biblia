# Rejestr wymagań

| ID | Kryterium | Status | Źródło | Dowód lub ograniczenie |
|---|---|---|---|---|
| R-001 | Silnik Apple, lokalny i niezależny od VoiceOver | gotowe | ustawienia.txt §1 | AVSpeechSynthesizer na iPhonie 17 Pro; wspólna instancja, brak sieci w silniku i brak mikrofonu. |
| R-002 | Tekst czytnika w kolejności, pauza, wznowienie, stop, ponowny start, zakończenie i brak nakładania | gotowe | ustawienia.txt §2 | Wspólny TextScreen zasila mowę wyłącznie Reading.text. MowaTelefon2: Biblia, psalm, liturgia, pauza, wznowienie, restart i stop na urządzeniu. |
| R-003 | Piąta karta, trzy sekcje, wspólne preferencje wyglądu | gotowe | ustawienia.txt §3 | Pięć natywnych kart. Audyt kart i aktywacja każdej przez rzeczywistą usługę VoiceOver. Rozmiar korzysta nadal z jednego ReadingSettings i jednego klucza. |
| R-004 | O programie: obie role i nazwiska, pochodzenie, wersja, kompilacja, link i źródła/prawa | do_weryfikacji | ustawienia.txt §4 | Ekran Autorzy i źródła: obie role, oba nazwiska, wersja/kompilacja z Bundle i odnośnik systemowy. Dokumentacja Windows, stopka TwojaBiblia.pl i informacja Pallottinum. Nie potwierdzono praw do dystrybucji aplikacji. |
| R-005 | Głosy z urządzenia, polskie najpierw, zastępowanie brakujących | gotowe | ustawienia.txt §5 | 112 pozycji z polskim kodem języka w rzeczywistym API tego telefonu, w tym głosy rozszerzeń. Kod sortuje głosy polskie na początku. Próba brakującego ID z rzeczywistym silnikiem. |
| R-006 | Regulacje VO głosu, tempa i głośności, kroki, trwałość, reset | do_weryfikacji | ustawienia.txt §6 | Trzy ChoiceSlider; parametry i reset w UserDefaults. Próby wartości uszkodzonych i skrajnych. Sprawdzić końcową próbę trwałości w UI. |
| R-007 | Próbka po polsku, wspólny silnik i parametry | gotowe | ustawienia.txt §7 | Próbka zmienia przyciski po uruchomieniu i końcu; z aplikacją uruchomioną bez VO na iPhonie, MowaTelefon1. |
| R-008 | Sesja audio, VoiceOver, przejścia, przerwania, słuchawki i Bluetooth, tło i blokada | do_weryfikacji | ustawienia.txt §8 | Potwierdzono przejście na ekran początkowy i powrót podczas czytania. Sygnały przerwania i odłączenia trasy testowe; fizycznych słuchawek i rzeczywistej rozmowy telefonicznej nie testowano. |
| R-009 | Wygląd i dostępność, jasny i ciemny, duży tekst, fokus, mały ekran | do_weryfikacji | ustawienia.txt §9 | Jasny iPhone 17 Pro i ciemny 13 mini z AX5. Poprawiono paski i link po oględzinach: równe kontrolki z symbolami w trakcie mowy przy dużym tekście. Trwa próba końcowa na sprzęcie. |
| R-010 | Fizyczny iPhone: wszystkie 20 prób z §10, rozróżnienie dowodu i braku | w_toku | ustawienia.txt §10 | Testy fizyczne w toku. Nie zastępować odsłuchu człowieka odczytem stanu i nie zaliczać niedostępnych akcesoriów. |
| R-011 | Gałąź ios, dwa komputery, pamięć, commity, raport, bez wysyłki | w_toku | ustawienia.txt §11 | Lokalna gałąź ios, maczek.cmd, bez wysyłki i bez modyfikacji repozytorium Windows na GitHubie. |
