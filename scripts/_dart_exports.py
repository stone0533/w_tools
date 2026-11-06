"""解析 Dart 包的 barrel 导出（`export` / `part` / `show` / `hide`）。

`check_public_catalog.py`（公开类型 → catalog）与 `check_doc_symbols.py`
（文档 import 边界）共用同一份解析，避免“公开类型”有两套定义。
只依赖标准库；脚本直接运行或 import 时都能从 `scripts/` 找到本模块。
"""
from __future__ import annotations

import pathlib
import re

DECL = re.compile(r'\b(?:class|enum|mixin|typedef|extension)\s+([A-Z][A-Za-z0-9_]*)')
BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
LINE_COMMENT = re.compile(r'//[^\n]*')
EXPORT = re.compile(r"^\s*export\s+'([^']+)'(?:\s+show\s+([^;]+)|\s+hide\s+([^;]+))?;", re.M)
PART = re.compile(r"^\s*part\s+'([^']+)'", re.M)


def strip_comments(text: str) -> str:
    return LINE_COMMENT.sub('', BLOCK_COMMENT.sub('', text))


def exported_types(package_dir: pathlib.Path) -> set[str]:
    """包 barrel（`lib/w_tools_*.dart`）真正对外导出的公开类型名。"""
    lib = package_dir / 'lib'
    barrels = list(lib.glob('w_tools_*.dart'))
    out: set[str] = set()
    seen: set[pathlib.Path] = set()

    def visit(path: pathlib.Path, show: set[str] | None, hide: set[str]) -> None:
        path = path.resolve()
        if path in seen or not path.exists():
            return
        seen.add(path)
        text = path.read_text()
        code = strip_comments(text)
        for m in PART.finditer(text):
            visit(path.parent / m.group(1), show, hide)
        for m in EXPORT.finditer(text):
            target = (path.parent / m.group(1)).resolve()
            child_show = set(x.strip() for x in m.group(2).split(',')) if m.group(2) else show
            child_hide = set(x.strip() for x in m.group(3).split(',')) if m.group(3) else hide
            visit(target, child_show, child_hide)
        for m in DECL.finditer(code):
            name = m.group(1)
            if show is not None and name not in show:
                continue
            if name in hide:
                continue
            out.add(name)

    for barrel in barrels:
        visit(barrel, None, set())
    return out
