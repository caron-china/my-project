#requires -Version 5.1
<#
  setup-git-identity.ps1
  用途：把 Git 全局身份写进 C:\Users\dell\.gitconfig（沙箱里我改不了，需你双击或运行一次）。
  这一步只影响“提交记录里显示谁”，不涉及任何密码。
  用法：右键“使用 PowerShell 运行”，或在终端执行
        powershell -ExecutionPolicy Bypass -File .\setup-git-identity.ps1
#>

$git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) {
  $cmd = Get-Command git -ErrorAction SilentlyContinue
  if ($cmd) { $git = $cmd.Source } else { Write-Host "未找到 git，请先安装 Git。" -ForegroundColor Red; exit 1 }
}

& $git config --global user.name "xiaoguangwu"
& $git config --global user.email "xiaoguangwu@users.noreply.github.com"
& $git config --global init.defaultBranch main
& $git config --global core.autocrlf true

Write-Host "已写入全局 Git 配置：" -ForegroundColor Green
& $git config --global --get user.name
& $git config --global --get user.email
Write-Host "`n如果想换成真实邮箱，重新执行：" -ForegroundColor Cyan
Write-Host '  git config --global user.email "你的邮箱@example.com"'
