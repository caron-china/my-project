#requires -Version 5.1
<#
  install-git-gh.ps1
  为 DSH 的 GitHub 集成（forge-github）准备 Git 与 GitHub CLI。
  用法：右键“使用 PowerShell 运行”，或在本目录执行
        powershell -ExecutionPolicy Bypass -File .\install-git-gh.ps1
  说明：需要联网。Git 使用机器级安装，会弹一次 UAC；gh 默认装到用户目录，不弹 UAC。
#>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Cmd($name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if ($c) { return $c.Source } else { return $null }
}

Write-Host "== 1/3 检查 winget ==" -ForegroundColor Cyan
$winget = Test-Cmd 'winget'
if (-not $winget) {
  Write-Host "未找到 winget。请打开 Microsoft Store 更新「应用安装程序 / App Installer」，或改用下面的手动下载方式。" -ForegroundColor Yellow
  Write-Host "Git:  https://git-scm.com/download/win"
  Write-Host "gh :  https://github.com/cli/cli/releases/latest (找 windows_amd64.msi)"
  exit 1
}
Write-Host "winget: $winget"

# winget 拉包走 CDN，若公司网络/代理拦截会失败，这里先做一次连通性探测
function Test-Url($url) {
  try {
    $r = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 20 -UseBasicParsing
    return $r.StatusCode -lt 400
  } catch {
    return $false
  }
}

if (-not (Test-Url 'https://github.com')) {
  Write-Host "无法连接 github.com，winget 下载会失败。请检查代理/VPN 后重试，或手动下载安装包。" -ForegroundColor Yellow
  Write-Host "Git:  https://git-scm.com/download/win"
  Write-Host "gh :  https://github.com/cli/cli/releases/latest"
  exit 2
}

Write-Host "`n== 2/3 安装 Git ==" -ForegroundColor Cyan
if (Test-Cmd 'git') {
  Write-Host "已安装：$(git --version)" -ForegroundColor Green
} else {
  winget install --id Git.Git -e --source winget `
    --accept-package-agreements --accept-source-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) { Write-Host "Git 安装失败（winget 退出码 $LASTEXITCODE）" -ForegroundColor Red; exit 3 }
}

Write-Host "`n== 3/3 安装 GitHub CLI ==" -ForegroundColor Cyan
if (Test-Cmd 'gh') {
  Write-Host "已安装：$(gh --version | Select-Object -First 1)" -ForegroundColor Green
} else {
  winget install --id GitHub.cli -e --source winget `
    --accept-package-agreements --accept-source-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) { Write-Host "gh 安装失败（winget 退出码 $LASTEXITCODE）" -ForegroundColor Red; exit 4 }
}

# 让当前窗口立刻能用新装的命令（新开窗口会自动读取系统 PATH）
foreach ($p in @(
    "$env:ProgramFiles\Git\cmd",
    "${env:ProgramFiles(x86)}\Git\cmd",
    "$env:LOCALAPPDATA\Programs\Git\cmd",
    "$env:ProgramFiles\GitHub CLI",
    "$env:LOCALAPPDATA\Programs\GitHub CLI"
  )) {
  if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) { $env:Path = "$p;$env:Path" }
}

Write-Host "`n== 安装结果 ==" -ForegroundColor Cyan
Write-Host ("git: " + (Test-Cmd 'git'))
Write-Host ("gh : " + (Test-Cmd 'gh'))

Write-Host "`n下一步（必须做，否则 DSH 面板显示 unauthenticated）：" -ForegroundColor Cyan
Write-Host "  gh auth login --hostname github.com --git-protocol https --web"
Write-Host "  按提示复制一次性 code，在浏览器里粘贴并授权即可。"
Write-Host "`n授权后回到这里验证：" -ForegroundColor Cyan
Write-Host "  gh auth status"
