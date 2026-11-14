#!/usr/bin/env python3
"""Run a command with idle / total timeouts, streaming its output.

Why this exists: `pub publish` performs OAuth against accounts.google.com, but pub
has no timeout of its own. On a machine without a proxy the process can sit in
SYN_SENT forever with no output. `publish_package.sh` uses this helper so a hang
turns into a fast, actionable failure instead of an indefinitely stuck release.

Usage:
    python3 scripts/_run_with_timeout.py --idle-timeout 180 --total-timeout 600 \
        -- flutter pub publish --force

Exit codes:
    0..125  child exit code
    124     timeout (the child was killed)
    127     helper could not start the child
"""
from __future__ import annotations

import argparse
import os
import selectors
import signal
import subprocess
import sys
import time


def _kill_group(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=2)
        return
    except subprocess.TimeoutExpired:
        pass
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        return


def _run(command: list[str], *, idle_timeout: float, total_timeout: float, label: str) -> int:
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=None,
            start_new_session=True,
        )
    except OSError as error:
        print(f'✗ 无法启动 {label}：{error}', file=sys.stderr)
        return 127

    selector = selectors.DefaultSelector()
    streams = {process.stdout, process.stderr}
    for stream in streams:
        assert stream is not None
        selector.register(stream, selectors.EVENT_READ)

    started = time.monotonic()
    last_output = started
    open_streams = len(streams)
    timed_out: str | None = None
    try:
        while open_streams > 0:
            now = time.monotonic()
            if idle_timeout > 0 and now - last_output > idle_timeout:
                timed_out = f'{int(idle_timeout)}s 无输出'
                break
            if total_timeout > 0 and now - started > total_timeout:
                timed_out = f'总时长超过 {int(total_timeout)}s'
                break

            for key, _ in selector.select(timeout=0.2):
                stream = key.fileobj
                data = os.read(stream.fileno(), 65536)  # type: ignore[union-attr]
                if not data:
                    selector.unregister(stream)
                    open_streams -= 1
                    continue
                last_output = time.monotonic()
                target = sys.stdout.buffer if stream is process.stdout else sys.stderr.buffer
                target.write(data)
                target.flush()
    except KeyboardInterrupt:
        _kill_group(process)
        raise
    finally:
        selector.close()

    if timed_out is None:
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            timed_out = '输出已关闭但进程未退出'

    if timed_out is not None:
        _kill_group(process)
        print(
            f'✗ {label} 超时（{timed_out}），已终止。\n'
            '  1) 检查 HTTPS_PROXY / HTTP_PROXY（见 AGENTS.md「本机网络」）。\n'
            '  2) 先查 pub.dev 是否已出现该版本，不要直接重试。\n'
            '  3) 已上传但本地无快照：从 pub.dev 归档补快照后再 resume。',
            file=sys.stderr,
        )
        return 124

    return process.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description='Run a command with idle/total timeouts.')
    parser.add_argument('--idle-timeout', type=float, default=180.0)
    parser.add_argument('--total-timeout', type=float, default=600.0)
    parser.add_argument('--label', default='命令')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = list(args.command)
    if command and command[0] == '--':
        command = command[1:]
    if not command:
        parser.error('缺少要执行的命令（用 -- 分隔）')

    try:
        return _run(
            command,
            idle_timeout=args.idle_timeout,
            total_timeout=args.total_timeout,
            label=args.label,
        )
    except KeyboardInterrupt:
        print(f'✗ {args.label} 被中断', file=sys.stderr)
        return 130


if __name__ == '__main__':
    raise SystemExit(main())
