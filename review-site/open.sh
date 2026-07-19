#!/usr/bin/env bash
set -euo pipefail

site_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
port="${YSYX_REVIEW_PORT:-4173}"
url="http://127.0.0.1:${port}"
browser_url="${url}/?wslDistro=$(python3 -c 'from urllib.parse import quote; import sys; print(quote(sys.argv[1], safe=""))' "${WSL_DISTRO_NAME:-Ubuntu}")"

case "$port" in
  ''|*[!0-9]*) echo "YSYX_REVIEW_PORT 必须是端口号" >&2; exit 1 ;;
esac
if (( 10#$port < 1 || 10#$port > 65535 )); then
  echo "YSYX_REVIEW_PORT 必须在 1 到 65535 之间" >&2
  exit 1
fi

is_review_site() {
  curl -fsS "$url/" 2>/dev/null | grep -q "YSYX Review Studio"
}

if is_review_site; then
  echo "复习站点已运行：$url"
elif curl -fsS "$url/" >/dev/null 2>&1; then
  echo "端口 $port 已被其他服务占用；请用 YSYX_REVIEW_PORT=4174 ./review-site/open.sh 重试。" >&2
  exit 1
else
  log_file="/tmp/ysyx-review-site-${port}.log"
  setsid nohup python3 -m http.server "$port" --bind 127.0.0.1 --directory "$site_dir" >"$log_file" 2>&1 &
  for _ in {1..30}; do
    is_review_site && break
    sleep 0.1
  done
  if ! is_review_site; then
    echo "启动复习站点失败，请查看：$log_file" >&2
    exit 1
  fi
  echo "复习站点已启动：$url"
fi

[ "${1:-}" = "--no-open" ] && exit 0

open_browser() {
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Start-Process '$browser_url'" >/dev/null 2>&1
  elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$browser_url" >/dev/null 2>&1
  elif command -v wslview >/dev/null 2>&1; then
    wslview "$browser_url" >/dev/null 2>&1
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$browser_url" >/dev/null 2>&1
  else
    return 1
  fi
}

if open_browser; then
  echo "已请求浏览器打开：$browser_url"
else
  echo "站点已启动，但无法自动启动浏览器；请手动打开：$browser_url" >&2
fi
