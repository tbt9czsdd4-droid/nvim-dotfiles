"""Format one unsaved Neovim buffer with the VSG selected on PATH."""

import glob
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit(f"VSG formatting needs PyYAML in {sys.executable}")


# Extended identifiers are case sensitive. Skip quoted text and comments
# when checking if VSG's case rules changed one.
VHDL_QUOTED = re.compile(rb"""--[^\r\n]*|/\*[\s\S]*?\*/|'"'|"(?:[^"\r\n]|"")*"|(\\(?:\\\\|[^\\\r\n])+\\)""")


def extended_names(content):
    return [m[1] for m in VHDL_QUOTED.finditer(content) if m[1]]


def buffer_style(style, source, target):
    config = yaml.safe_load(style.read_bytes())
    if not isinstance(config, dict) or not ({"file_list", "file_rules"} & config.keys()):
        return style

    # VSG adds file_list to its --fix targets. Carry only this buffer's
    # per-file rules across to the private copy, in VSG's application order.
    for section in ("file_list", "file_rules"):
        for entry in config.pop(section, []):
            if isinstance(entry, dict):
                pattern, overrides = next(iter(entry.items()))
                pattern = os.path.expanduser(os.path.expandvars(pattern))
                if any(Path(path).resolve() == source for path in glob.iglob(pattern, recursive=True)):
                    config[section] = [{str(target): overrides}]
                    break
    selected = target.with_name("style.yaml")
    selected.write_text(yaml.safe_dump(config, sort_keys=False))
    return selected


def reported_violations(report, target):
    if not report.exists():
        return False
    data = json.loads(report.read_bytes())
    files = data.get("files", [])
    if len(files) != 1 or files[0].get("file_path") != str(target):
        return False
    violations = files[0].get("violations")
    return isinstance(violations, list) and bool(violations) and all(
        isinstance(item, dict) and item.get("rule") for item in violations
    )


def format_buffer(vsg, source, style):
    with tempfile.TemporaryDirectory(prefix="nvim-vsg-") as directory:
        staging = Path(directory)
        target = staging / "buffer.vhd"
        report = staging / "report.json"
        original = sys.stdin.buffer.read()
        target.write_bytes(original)
        selected = buffer_style(Path(style), Path(source).resolve(), target)
        result = subprocess.run(
            [vsg, "-p", "1", "--fix", "-of", "syntastic", "-f", str(target), "-c", str(selected), "-js", str(report)],
            capture_output=True,
            env={
                **os.environ,
                "NVIM_VSG_RULES": str(Path(__file__).resolve().with_name("vsg_rules")),
                "PYTHONDONTWRITEBYTECODE": "1",
            },
        )
        # A parser failure can also return 1. A completed style check has a
        # populated report and writes only syntastic diagnostics to stdout.
        partial = result.returncode == 1 and not result.stderr and reported_violations(report, target)
        # VSG can report a failed write on stdout even when its status is zero.
        if b"Could not write fixes back to file" in result.stdout or (result.returncode and not partial):
            message = result.stderr.strip() or result.stdout.strip() or f"VSG exited with status {result.returncode}".encode()
            sys.stderr.buffer.write(message.replace(os.fsencode(target), os.fsencode(source)) + b"\n")
            return 1
        formatted = target.read_bytes()
        if b"\\" in original and extended_names(original) != extended_names(formatted):
            sys.exit("VSG changed a case-sensitive extended identifier. Buffer left untouched.")
        sys.stdout.buffer.write(formatted)
        return 0


if __name__ == "__main__":
    # Unwind the subprocess and temporary directory when Conform cancels a run.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    try:
        sys.exit(format_buffer(*sys.argv[1:]))
    except (OSError, ValueError, yaml.YAMLError) as err:
        sys.exit(str(err))
