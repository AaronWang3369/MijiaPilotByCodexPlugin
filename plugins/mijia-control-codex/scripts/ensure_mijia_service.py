"""Ensure the local upstream mijia-control web service is running.

This helper starts only the upstream Flask service (`run.py`). It does not
call Xiaomi APIs, enumerate devices, or perform smart-home operations.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

DEFAULT_API_URL = "http://127.0.0.1:5000/api"
FALSE_VALUES = {"0", "false", "no", "off"}


def _emit(message: str, *, quiet: bool, stream) -> None:
    if not quiet:
        print(message, file=stream)


def _load_token() -> str | None:
    token = os.environ.get("MIJIA_TOKEN")
    if token:
        return token

    token_file = Path.home() / ".config" / "mijia-control" / "token.json"
    if not token_file.exists():
        return None

    try:
        data = json.loads(token_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None

    token = data.get("token")
    if isinstance(token, str) and token.strip():
        return token
    return None


def _auth_me_url(api_url: str) -> str:
    return api_url.rstrip("/") + "/auth/me"


def service_reachable(api_url: str, *, timeout: float = 2.0) -> tuple[bool, str]:
    url = _auth_me_url(api_url)
    request = Request(url, method="GET")
    token = _load_token()
    if token:
        request.add_header("Authorization", f"Bearer {token}")

    try:
        with urlopen(request, timeout=timeout) as response:
            return True, f"{url} returned HTTP {response.status}"
    except HTTPError as error:
        return True, f"{url} returned HTTP {error.code}"
    except TimeoutError:
        return False, f"{url} timed out"
    except URLError as error:
        return False, f"{url} is not reachable: {error.reason}"
    except OSError as error:
        return False, f"{url} is not reachable: {error}"


def _is_local_api(api_url: str) -> bool:
    parsed = urlparse(api_url)
    host = parsed.hostname
    return host in {"127.0.0.1", "localhost", "::1", "0.0.0.0"}


def _candidate_roots() -> list[Path]:
    candidates: list[Path] = []

    env_dir = os.environ.get("MIJIA_CONTROL_DIR")
    if env_dir:
        candidates.append(Path(env_dir))

    candidates.append(Path.cwd())
    candidates.append(Path.home() / "mijia-control")

    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        candidates.append(Path(user_profile) / "mijia-control")

    try:
        for parent in Path(sys.executable).resolve().parents:
            candidates.append(parent)
    except OSError:
        pass

    try:
        import mijia_cli  # type: ignore

        candidates.append(Path(mijia_cli.__file__).resolve().parent)
    except Exception:
        pass

    seen: set[Path] = set()
    unique: list[Path] = []
    for candidate in candidates:
        try:
            resolved = candidate.expanduser().resolve()
        except OSError:
            continue
        if resolved in seen:
            continue
        seen.add(resolved)
        unique.append(resolved)
    return unique


def find_upstream_root() -> Path | None:
    for candidate in _candidate_roots():
        if (candidate / "run.py").is_file():
            return candidate
    return None


def find_upstream_python(root: Path) -> str:
    explicit = os.environ.get("MIJIA_CONTROL_PYTHON")
    if explicit and Path(explicit).expanduser().is_file():
        return str(Path(explicit).expanduser())

    if os.name == "nt":
        venv_python = root / "venv" / "Scripts" / "python.exe"
    else:
        venv_python = root / "venv" / "bin" / "python"

    if venv_python.is_file():
        return str(venv_python)
    return sys.executable


def _state_dir() -> Path:
    explicit = os.environ.get("MIJIA_CONTROL_CODEX_STATE_DIR")
    if explicit:
        return Path(explicit).expanduser()

    if os.name == "nt":
        local_app_data = os.environ.get("LOCALAPPDATA")
        if local_app_data:
            return Path(local_app_data) / "mijia-control-codex"

    return Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "mijia-control-codex"


def start_service(root: Path, python: str) -> tuple[int, Path]:
    state_dir = _state_dir()
    state_dir.mkdir(parents=True, exist_ok=True)
    log_path = state_dir / "mijia-control-service.log"
    pid_path = state_dir / "mijia-control-service.pid"

    env = os.environ.copy()
    env.setdefault("PYTHONIOENCODING", "utf-8")

    creationflags = 0
    start_new_session = False
    if os.name == "nt":
        creationflags |= getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
        creationflags |= getattr(subprocess, "DETACHED_PROCESS", 0)
    else:
        start_new_session = True

    with log_path.open("ab") as log_file:
        process = subprocess.Popen(
            [python, "run.py"],
            cwd=str(root),
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            creationflags=creationflags,
            start_new_session=start_new_session,
        )

    pid_path.write_text(str(process.pid), encoding="utf-8")
    return process.pid, log_path


def ensure_service(
    *,
    api_url: str | None = None,
    start: bool = True,
    timeout: float = 20.0,
    quiet: bool = False,
    stream=sys.stdout,
) -> bool:
    effective_api_url = api_url or os.environ.get("MIJIA_API_URL") or DEFAULT_API_URL
    ok, detail = service_reachable(effective_api_url)
    if ok:
        _emit(f"mijia-control service is reachable: {detail}", quiet=quiet, stream=stream)
        return True

    _emit(f"mijia-control service is not reachable: {detail}", quiet=quiet, stream=stream)
    if not start:
        return False

    autostart = os.environ.get("MIJIA_CONTROL_AUTOSTART", "1").strip().lower()
    if autostart in FALSE_VALUES:
        _emit("MIJIA_CONTROL_AUTOSTART disables automatic startup.", quiet=quiet, stream=stream)
        return False

    if not _is_local_api(effective_api_url):
        _emit(
            f"MIJIA_API_URL is not local ({effective_api_url}); not starting a local service.",
            quiet=quiet,
            stream=stream,
        )
        return False

    root = find_upstream_root()
    if not root:
        _emit(
            "Could not find upstream mijia-control root. Set MIJIA_CONTROL_DIR to the directory containing run.py.",
            quiet=quiet,
            stream=stream,
        )
        return False

    python = find_upstream_python(root)
    pid, log_path = start_service(root, python)
    _emit(f"Started mijia-control service process {pid} from {root}.", quiet=quiet, stream=stream)
    _emit(f"Service log: {log_path}", quiet=quiet, stream=stream)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ok, detail = service_reachable(effective_api_url)
        if ok:
            _emit(f"mijia-control service is reachable: {detail}", quiet=quiet, stream=stream)
            return True
        time.sleep(0.5)

    _emit(
        f"Timed out waiting for mijia-control service at {effective_api_url}. Check {log_path}.",
        quiet=quiet,
        stream=stream,
    )
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Ensure local mijia-control service is running.")
    parser.add_argument("--api-url", default=None, help="API URL; defaults to MIJIA_API_URL or upstream default.")
    parser.add_argument("--timeout", type=float, default=20.0, help="Seconds to wait after starting the service.")
    parser.add_argument("--check-only", action="store_true", help="Check reachability without starting the service.")
    parser.add_argument("--quiet", action="store_true", help="Suppress status output.")
    args = parser.parse_args()

    ok = ensure_service(
        api_url=args.api_url,
        start=not args.check_only,
        timeout=args.timeout,
        quiet=args.quiet,
        stream=sys.stdout,
    )
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
