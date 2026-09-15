"""Recette réelle du service via D-Bus. Aucun mock du manager."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def main():
    if os.geteuid() == 0:
        print("SKIP: exécuter la recette D-Bus avec un compte non root")
        return 77
    if os.environ.get("CONSOLE_TEST_PRIVATE_BUS") != "1":
        return subprocess.call(["dbus-run-session", "--", sys.executable, __file__, sys.argv[1]],
                               env=dict(os.environ, CONSOLE_TEST_PRIVATE_BUS="1"))
    manager = Path(sys.argv[1]).resolve()
    client = manager.parent / "ipc-client"

    def call(method, *args):
        result = subprocess.run([str(client), method, *args], capture_output=True, text=True, timeout=4)
        if result.returncode:
            raise RuntimeError("D-Bus indisponible")
        return json.loads(result.stdout)

    def until(predicate):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                if predicate():
                    return
            except RuntimeError:
                pass
            time.sleep(0.05)
        raise AssertionError("délai dépassé")

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        game = root / "catalog" / "org.test.game"
        game.mkdir(parents=True)
        manifest = dict(schema_version=1, id="org.test.game", name="Test", version="1.0.0",
                        developer="Test", executable="game", runtime="native", permissions=[], controller_support=False)
        (game / "game.json").write_text(json.dumps(manifest))
        executable = game / "game"
        # exec conserve le PID : le MVP ne promet pas la gestion des descendants.
        executable.write_text('#!/bin/sh\nprintf "hello-test\\n"\nexec /bin/sleep 30\n')
        executable.chmod(0o700)
        env = dict(os.environ, XDG_DATA_HOME=str(root / "data"),
                   XDG_CONFIG_HOME=str(root / "config"), XDG_CACHE_HOME=str(root / "cache"))
        with (root / "service.log").open("w+") as logs:
            process = subprocess.Popen([str(manager), "--catalog", str(game.parent)], env=env, stderr=logs)
            try:
                until(lambda: call("Status")["state"] == "stopped")
                assert len(call("ListGames")["games"]) == 1
                assert call("Launch", "org.unknown.game")["error"] == "game_not_found"
                assert call("Launch", "org.test.game")["ok"]
                until(lambda: call("Status")["state"] == "running")
                assert call("Launch", "org.test.game")["error"] == "game_already_active"
                assert call("Stop", "org.unknown.game")["error"] == "game_not_running"
                assert call("Stop", "org.test.game")["ok"]
                until(lambda: call("Status")["state"] == "stopped")
                assert (root / "data/console-os/games/org.test.game/saves").is_dir()
                executable.write_text('#!/bin/sh\nexit 0\n')
                assert call("Launch", "org.test.game")["ok"]
                until(lambda: call("Status")["state"] == "stopped")
                executable.write_text('#!/nonexistent/interpreter\n')
                assert call("Launch", "org.test.game")["ok"]
                until(lambda: call("Status")["state"] == "failed")
                manifest["executable"] = "../escape"
                (game / "game.json").write_text(json.dumps(manifest))
                assert not call("ListGames")["games"]
                assert not call("Launch", "org.test.game")["ok"]
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            logs.seek(0)
            events = [json.loads(line) for line in logs if line.startswith("{")]
            assert any(event["event"] == "game_exit" for event in events)
            assert any(event["event"] == "manifest_rejected" for event in events)
        print("PASS: catalogue, lancement, concurrence, arrêt, échec exécutable et manifest hostile")
    return 0


if __name__ == "__main__":
    sys.exit(main())
