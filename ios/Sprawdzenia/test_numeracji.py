"""Regresje licznika używanego przez Xcode przed podpisaniem pakietów."""

import os
import plistlib
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture
def projekt(tmp_path: Path) -> Path:
    """Daje każdej próbie prywatną kopię licznika, bez zmiany numeru wydania."""
    if os.name != "posix" or not Path("/usr/bin/python3").is_file():
        pytest.skip("Próba skryptu dla Xcode wymaga środowiska POSIX z Pythonem.")
    (tmp_path / "ios").mkdir()
    (tmp_path / "ios/Build.xcconfig").write_text("CURRENT_PROJECT_VERSION = 9\n")
    return Path(shutil.copy2(ROOT / "podbij_build.sh", tmp_path))


def _wykonaj(skrypt: Path, *argumenty: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(skrypt), *argumenty], capture_output=True, text=True, check=False,
        cwd=skrypt.parent.parent, timeout=20,
    )


def test_odczyt_i_podbicie(projekt: Path) -> None:
    """Odczyt nie zużywa numeru, a rezerwacja przechodzi z 9 na 10."""
    for argumenty, numer in [(("--obecny",), 9), ((), 10), (("--obecny",), 10)]:
        wynik = _wykonaj(projekt, *argumenty)
        assert wynik.returncode == 0, wynik.stderr
        assert wynik.stdout.strip() == str(numer)


def test_niezalezne_rezerwacje(projekt: Path) -> None:
    """Osobne procesy nie dostają tego samego numeru nawet przy równoległym starcie."""
    with ThreadPoolExecutor(max_workers=6) as pula:
        wyniki = list(pula.map(_wykonaj, [projekt] * 12))
    assert all(wynik.returncode == 0 for wynik in wyniki)
    assert sorted(int(wynik.stdout) for wynik in wyniki) == list(range(10, 22))


@pytest.mark.parametrize("wartosc", ["", "0", "2.5", "12\nCURRENT_PROJECT_VERSION = 13"])
def test_uszkodzony_licznik(projekt: Path, wartosc: str) -> None:
    """Uszkodzony plik pozostaje nietknięty i nie tworzy pozornie dobrego numeru."""
    licznik = projekt.parent / "ios/Build.xcconfig"
    tekst = f"CURRENT_PROJECT_VERSION = {wartosc}\n"
    licznik.write_text(tekst)
    wynik = _wykonaj(projekt)
    assert wynik.returncode != 0 and not wynik.stdout
    assert "Niepoprawny licznik" in wynik.stderr
    assert licznik.read_text() == tekst


def test_obca_opcja_nie_rezerwuje(projekt: Path) -> None:
    """Literówka przy wywołaniu nie może zwiększyć licznika."""
    assert _wykonaj(projekt, "--literowka").returncode != 0
    assert _wykonaj(projekt, "--obecny").stdout.strip() == "9"


def test_wersja_i_eksport() -> None:
    """Stała wersja i brak przenumerowania podczas eksportu to umowa projektu."""
    konfiguracja = (ROOT / "ios/project.yml").read_text(encoding="utf-8")
    assert 'MARKETING_VERSION: "1.0"' in konfiguracja
    opcje = plistlib.loads((ROOT / "ios/ExportOptions.plist").read_bytes())
    assert opcje["manageAppVersionAndBuildNumber"] is False


def test_xcode_tylko_odczytuje_numer() -> None:
    """Archiwizacja nie uruchamia skryptu, a wszystkie pakiety czytają wspólny licznik."""
    for nazwa in ("project.yml", "dostępna biblia.xcodeproj/project.pbxproj"):
        konfiguracja = (ROOT / "ios" / nazwa).read_text(encoding="utf-8")
        assert "podbij_build.sh" not in konfiguracja
        assert "Build.xcconfig" in konfiguracja
    for nazwa in ("Info.plist", "InfoTests.plist"):
        info = plistlib.loads((ROOT / "ios" / nazwa).read_bytes())
        assert info["CFBundleVersion"] == "$(CURRENT_PROJECT_VERSION)"


def test_metadane_do_dystrybucji() -> None:
    """Chroni deklarację HTTPS, ekran startowy, orientacje i ikonę przed regresją."""
    import json
    import struct

    info = plistlib.loads((ROOT / "ios/Info.plist").read_bytes())
    assert info["ITSAppUsesNonExemptEncryption"] is False
    assert info["UIBackgroundModes"] == ["audio"]
    assert "NSMicrophoneUsageDescription" not in info
    assert "NSSpeechRecognitionUsageDescription" not in info
    assert isinstance(info["UILaunchScreen"], dict)
    assert set(info["UISupportedInterfaceOrientations"]) == {
        "UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    }
    projekt = (ROOT / "ios/project.yml").read_text(encoding="utf-8")
    for klucz, wartosc in {
        "CFBundleDisplayName": "dostępna biblia",
        "LSApplicationCategoryType": "public.app-category.reference",
    }.items():
        assert info[klucz] == f"$(INFOPLIST_KEY_{klucz})"
        assert any(
            linia.strip() == f"INFOPLIST_KEY_{klucz}: {wartosc}"
            for linia in projekt.splitlines()
        )
    assert info["CFBundleLocalizations"] == ["pl"]
    katalog = ROOT / "ios/App/Assets.xcassets/AppIcon.appiconset"
    ikony = json.loads((katalog / "Contents.json").read_bytes())["images"]
    obraz = next(ikona for ikona in ikony if ikona["size"] == "1024x1024")
    dane = (katalog / obraz["filename"]).read_bytes()
    assert dane.startswith(b"\x89PNG\r\n\x1a\n")
    assert struct.unpack(">II", dane[16:24]) == (1024, 1024)
    assert dane[25] == 2  # Obraz RGB bez kanału alfa.
