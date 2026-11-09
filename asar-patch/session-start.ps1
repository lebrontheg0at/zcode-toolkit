# ZCode Toolkit 会话启动钩子：
#   1) agent 运行时净化器 —— zcode.cjs 不被进程锁定，随时可打
#   2) app.asar 补丁 —— ZCode 运行时文件被锁，打不了；发现缺失/过期就启动
#      退出监视器（repatch-once.ps1），ZCode 完全退出后自动补丁并重启
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
$node = 'D:\nodejs\node.exe'
$log = Join-Path $here 'auto-install.log'
function L($m) {
  Add-Content -Path $log -Value ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) -Encoding UTF8
}

if (-not (Test-Path $node)) { L 'session-start: node 不存在，跳过'; exit 0 }

# 1) agent 净化器（ZCode 升级会整个替换 zcode.cjs，每次启动都检查）
& $node (Join-Path $here '..\agent-patch\install-agent-fix.mjs') 2>&1 | ForEach-Object { L ('agent: ' + $_) }

# 2) app.asar：只判断是否需要更新（真打补丁要等 ZCode 退出，由监视器完成）
& $node (Join-Path $here 'install-asar.mjs') --needs-update 2>&1 | ForEach-Object { L ('asar: ' + $_) }
if ($LASTEXITCODE -ne 0) {
  L 'session-start: app.asar 补丁缺失/过期 —— 已启动退出监视器，ZCode 完全退出后自动补丁并重启'
  Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $here 'repatch-once.ps1')
  ) -WindowStyle Hidden
}
