"""Backward-compatible import path for the PC UART host.

The wire contract lives in :mod:`host.uart_protocol`; the session/rendering
API is implemented in :mod:`host.ui_host`.  Keeping this shim allows older
scripts that imported ``designer.host_app`` to continue working without
creating a second protocol implementation.
"""

try:
    from host.ui_host import *  # noqa: F401,F403
except ImportError:  # direct execution from ``designer``
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from host.ui_host import *  # noqa: F401,F403


if __name__ == "__main__":
    from host.ui_host import main

    raise SystemExit(main())
