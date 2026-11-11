#!/usr/bin/env bash
# 仓库脚本共用的 Python 环境守卫。source 使用，不要直接执行。
#
# 用法：
#   source "$root/scripts/_python.sh"
#   if ! require_python_yaml; then exit 2; fi
#
# 文件名以下划线开头：check_gate_coverage 不把它当成面向用户的脚本。
# 这里只做「缺依赖时给人话」，不安装任何东西，也不改 PYTHONPATH。

require_python_yaml() {
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    return 0
  fi
  cat >&2 <<'EOF'
✗ 缺少 PyYAML：检查脚本需要 `import yaml`。
  修法 1（推荐）：python3 -m pip install pyyaml
  修法 2（无 pip 权限 / 沙箱）：
    python3 -m pip install --target /tmp/pylibs pyyaml && export PYTHONPATH=/tmp/pylibs
EOF
  return 2
}
