"""Uruchamia bezpłatne próby kontraktu ElevenLabs napisane dla natywnego kodu iOS."""

import os
from pathlib import Path
import subprocess
import sys

import pytest


def test_kontrakt_elevenlabs_na_ios() -> None:
    """Sprawdza tekst, granice, format ramek, błędy i żądanie bez łączenia z API."""
    destination = os.environ.get("BIBLIA_TEST_DESTINATION")
    if sys.platform != "darwin" or not destination:
        pytest.skip("Potrzebny jest Mac i urządzenie wskazane w BIBLIA_TEST_DESTINATION.")
    ios = Path(__file__).resolve().parents[1]
    result = subprocess.run(
        [
            "xcodebuild", "-project", "dostepna biblia.xcodeproj",
            "-scheme", "dostepna biblia", "-destination", destination,
            "-derivedDataPath", "build/Derived", "-disableAutomaticPackageResolution",
            "-parallel-testing-enabled", "NO",
            "-only-testing:dostepna biblia - testy/ElevenContractTests", "test",
        ],
        cwd=ios, check=False, capture_output=True, text=True, timeout=600,
    )
    assert result.returncode == 0, (result.stdout + result.stderr)[-6000:]
