#requires -Version 5.1
<#
  configure-git-gh.ps1
  在 Git 安装完成后运行：写入 git 身份、完成 gh 登录、验证 GitHub 集成状态。
  用法（在普通 PowerShell 窗口里）：
      powershell -ExecutionPolicy Bypass -File .\configure-git-gh.ps1
  安全提示：本脚本不接收、不保存任何密码或 token；
            GitHub 登录走 gh 的浏览器一次性 code 流程。
#>

$ErrorActionPreference = 'Stop'

function Test-Cmd($name) { (Get-Command $name -ErrorAction SilentlyContinue).Source }

Write-Host "== 0/4 检查前置条件 ==" -ForegroundColor Cyan
$git = Test-Cmd 'git'
$gh  = Test-Cmd 'gh'
if (-not $git) { Write-Host "未找到 git。请先运行 .\install-git-gh.ps1，然后重开一个 PowerShell 窗口。" -ForegroundColor Red; exit 1 }
if (-not $gh)  { Write-Host "未找到 gh。请先运行 .\install-git-gh.ps1，然后重开一个 PowerShell 窗口。" -ForegroundColor Red; exit 1 }
Write-Host ("git: " + $git)
Write-Host ("gh : " + $gh)

Write-Host "`n== 1/4 设置 Git 用户身份 ==" -ForegroundColor Cyan
Write-Host "（这只写进本机 git config，不是 GitHub 密码；仅作为提交记录里的显示名）"
$name = Read-Host "Git 显示名 [xiaoguangwu]"
if ([string]::IsNullOrWhiteSpace($name)) { $name = 'xiaoguangwu' }

$email = Read-Host "Git 邮箱（建议用 GitHub 账号邮箱，或隐私邮箱 xxx@users.noreply.github.com）"
while ([string]::IsNullOrWhiteSpace($email)) {
  $email = Read-Host "邮箱不能为空，请重新输入"
}

git config --global user.name  "$name"
git config --global user.email "$email"
git config --global init.defaultBranch main
git config --global core.autocrlf true

Write-Host "`n已写入：" -ForegroundColor Green
git config --global --get user.name
git config --global --get user.email

Write-Host "`n== 2/4 登录 GitHub ==" -ForegroundColor Cyan
$status = $null
try { gh auth status --hostname github.com 2>&1 | Out-Null; $status = 'ok' } catch { $status = 'no' }
if ($status -eq 'ok') {
  Write-Host "已登录 github.com，跳过。" -ForegroundColor Green
} else {
  Write-Host "即将打开浏览器授权。终端会显示一个 8 位 code，复制它粘贴到网页里即可。"
  Write-Host "本脚本不会让你输入 GitHub 密码——密码不能用于命令行登录。" -ForegroundColor Yellow
  gh auth login --hostname github.com --git-protocol https --web
}

Write-Host "`n== 3/4 让 git 复用 gh 的凭据 ==" -ForegroundColor Cyan
# gh 提供了 git credential helper；配置后 git push/pull 会自动用 gh 的登录态
try {
  gh auth setup-git --hostname github.com
  Write-Host "已配置 gh 作为 git 的 credential helper。" -ForegroundColor Green
} catch {
  Write-Host "setup-git 失败，可忽略（首次 push 时会提示重新授权）：$($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n== 4/4 验证 ==" -ForegroundColor Cyan
gh auth status
Write-Host "`nGitHub 账号："
gh api user --jq '.login + "  (" + (.name // "no name") + ")"' 2>$null

Write-Host "`n全部完成。现在请重启 DSH，然后打开一个 Git 仓库目录作为工作区。" -ForegroundColor Cyan
Write-Host "DSH 的『变更请求』面板会在此后可用；若仍显示 unauthenticated，重开 DSH 即可。"
