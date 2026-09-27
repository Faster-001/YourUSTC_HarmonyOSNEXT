#!/usr/bin/env bash
# 构建 YourUSTC_HarmonyOSNEXT 的 entry 模块（debug HAP）
# 用法: ./build.sh [额外的 hvigor 任务或参数]
# 示例: ./build.sh              # 常规构建
#       ./build.sh clean        # 先 clean 再构建
#
# 说明:
# - DEVECO_SDK_HOME / JAVA_HOME 在当前 shell 环境中未设置，此处统一指向 DevEco Studio 自带目录
# - 打包签名阶段需要 java，使用 DevEco Studio 自带的 jbr
# - PATH 中的 java 目录必须写成 POSIX 风格（/c/...）："C:/..." 形式的条目
#   在 Git Bash 中既无法被本 shell 的工具识别，传给子进程时也不会被正确转换，
#   会导致 hvigor 报 spawn java ENOENT（daemon 与 --no-daemon 模式下均会复现）
# - hvigor daemon 可能带着旧环境驻留（报 Invalid DEVECO_SDK_HOME 或
#   spawn java ENOENT），此时重启 daemon 也无济于事。因此构建失败时先
#   stop-daemon 清掉旧 daemon，再用 --no-daemon 在客户端进程内重试一次，
#   直接继承本脚本的环境，不依赖任何 daemon

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR" || exit 1

# DevEco Studio 安装路径（如有变动只需改这里）
DEVECO_HOME="C:/Program Files/Huawei/DevEco Studio"
HVIGORW="$DEVECO_HOME/tools/hvigor/bin/hvigorw.bat"

if [ ! -f "$HVIGORW" ]; then
  echo "错误: 未找到 hvigorw: $HVIGORW" >&2
  echo "请编辑本脚本中的 DEVECO_HOME 指向 DevEco Studio 安装目录" >&2
  exit 1
fi
if [ ! -f "$DEVECO_HOME/jbr/bin/java.exe" ]; then
  echo "错误: 未找到 java: $DEVECO_HOME/jbr/bin/java.exe" >&2
  echo "请编辑本脚本中的 DEVECO_HOME 指向 DevEco Studio 安装目录" >&2
  exit 1
fi

export DEVECO_SDK_HOME="$DEVECO_HOME/sdk"
export JAVA_HOME="$DEVECO_HOME/jbr"
export PATH="$(cygpath -u "$DEVECO_HOME/jbr/bin"):$PATH"

run_build() {
  "$HVIGORW" "$@" --mode module -p module=entry@default -p product=default -p debuggable=true assembleHap
}

run_build_no_daemon() {
  "$HVIGORW" --no-daemon "$@" --mode module -p module=entry@default -p product=default -p debuggable=true assembleHap
}

echo "== 开始构建 entry 模块 =="
run_build "$@"
status=$?

# 构建失败多半是 daemon 带着旧环境，停掉后以 --no-daemon 重试一次
if [ $status -ne 0 ]; then
  echo "== 构建失败，停用 daemon 后以非 daemon 模式重试 ==" >&2
  "$HVIGORW" --stop-daemon >/dev/null 2>&1
  run_build_no_daemon "$@"
  status=$?
fi

if [ $status -eq 0 ]; then
  echo "== 构建成功 =="
  HAP_PATH="$PROJECT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"
  [ -f "$HAP_PATH" ] && echo "产物: $HAP_PATH"
else
  echo "== 构建失败（退出码 $status）==" >&2
fi
exit $status
