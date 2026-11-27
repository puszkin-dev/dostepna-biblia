"""Sprawdzenia zgodności przenośnego katalogu i konfiguracji wydania."""

import plistlib
import re
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]


def _books(source: str, pattern: str) -> list[tuple[str, str, str]]:
    books = re.findall(pattern, source)
    if not books or len({book[0] for book in books}) != len(books):
        raise ValueError("Katalog musi zawierać księgi o niepowtarzalnych kodach.")
    return books


WINDOWS = r'new BibleBook\("([^"]+)", "([^"]+)", (true|false)\)'
IOS = r'Book\(code: "([^"]+)", name: "([^"]+)", newTestament: (true|false)\)'


def test_katalog_bez_zmiany_kolejnosci_i_pisowni() -> None:
    """Porównuje wszystkie 73 kody, nazwy i testamenty ze źródłem Windows."""
    original = _books((ROOT / "DostepnaBiblia.cs").read_text("utf-8-sig"), WINDOWS)
    port = _books((ROOT / "ios/App/Book.swift").read_text("utf-8"), IOS)
    assert len(original) == 73
    assert port == original


@pytest.mark.parametrize("source", ["", 'new BibleBook("A", "B", false)' * 2])
def test_odrzuca_brak_lub_powtorzenie_ksiegi(source: str) -> None:
    """Pusty albo zdublowany katalog nie może przejść cichego porównania."""
    with pytest.raises(ValueError, match="Katalog"):
        _books(source, WINDOWS)


def test_dystrybucja_bez_wysylki() -> None:
    """Eksportuje dla podanego zespołu, nie zleca wysyłki do Apple."""
    options = plistlib.loads((ROOT / "ios/ExportOptions.plist").read_bytes())
    assert options["destination"] == "export"
    assert options["method"] == "app-store-connect"
    assert options["teamID"] == "9N975WV782"


def test_kontrolki_wyboru_bez_menu() -> None:
    """Pilnuje, żeby dla list nie wróciło menu kontekstowe."""
    files = (ROOT / "ios/App").glob("*.swift")
    code = "\n".join(path.read_text("utf-8") for path in files)
    assert "UIMenu(" not in code
    assert "showsMenuAsPrimaryAction" not in code
    for label in ("Część liturgii", "Co chcesz czytać", "Wybierz księgę",
                  "Wybierz rozdział", "Kategoria cytatu"):
        assert f'ChoiceSlider("{label}")' in code
