#!/bin/sh
# Rezerwuje kolejny numer dla wszystkich targetów iOS; nie wymaga XcodeGen.
set -eu
cd "$(dirname "$0")/ios"
exec /usr/bin/python3 - "$@" <<'PY'
import fcntl
import os
import re
import sys
import tempfile
from pathlib import Path

if sys.argv[1:] not in ([], ["--obecny"]):
    sys.exit("Użycie: podbij_build.sh [--obecny]")
config = Path("Build.xcconfig")
try:
    # Blokujemy katalog, a nie podmieniany plik: dwie rezerwacje nie zgubią numeru.
    directory = os.open(".", os.O_RDONLY)
    fcntl.flock(directory, fcntl.LOCK_EX)
    value = re.fullmatch(r"CURRENT_PROJECT_VERSION = ([1-9][0-9]*)\n?", config.read_text())
    if value is None:
        sys.exit("Niepoprawny licznik w Build.xcconfig; nie zmieniono numeru.")
    if sys.argv[1:]:
        print(value[1])
        sys.exit(0)
    number = int(value[1]) + 1
    with tempfile.NamedTemporaryFile(mode="w", dir=".", delete=False) as temporary:
        try:
            temporary.write(f"CURRENT_PROJECT_VERSION = {number}\n")
            temporary.flush()
            os.fchmod(temporary.fileno(), config.stat().st_mode & 0o777)
            os.fsync(temporary.fileno())
            os.replace(temporary.name, config)
        finally:
            Path(temporary.name).unlink(missing_ok=True)
    print(number)
except (OSError, ValueError) as error:
    sys.exit(f"Nie udało się podbić numeru kompilacji: {error}")
PY
