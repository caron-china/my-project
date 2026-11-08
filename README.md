# my-project

一个用于验证 **DeepSeek Harness（DSH）** 本地开发工作流的示例仓库。它把「初始化 Git → 配置 GitHub 登录 → 工作树隔离开发 → 提交 → Pull Request」整条链路跑通，并把过程中用到的脚本沉淀下来。

## 目录结构

```text
.
├── .gitignore                  # 依赖、构建产物、系统临时文件
├── install-git-gh.ps1          # 安装 Git 与 GitHub CLI（winget，带连通性预检）
├── configure-git-gh.ps1        # 写入 Git 身份、完成 gh 登录、配置凭据复用
├── setup-git-identity.ps1      # 单独设置全局 Git 身份
└── README.md
```

## 脚本说明

| 脚本 | 用途 | 前置条件 |
|---|---|---|
| `install-git-gh.ps1` | 检查 winget 与 github.com 连通性，安装 Git 和 GitHub CLI | 能访问 github.com 或可用的包源 |
| `setup-git-identity.ps1` | 设置 `user.name`、`user.email`、默认分支与换行策略 | 已安装 Git |
| `configure-git-gh.ps1` | 设置身份 → 浏览器授权登录 → `gh auth setup-git` → 验证账号 | 已安装 Git 和 gh |

运行方式：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-git-gh.ps1
powershell -ExecutionPolicy Bypass -File .\setup-git-identity.ps1
powershell -ExecutionPolicy Bypass -File .\configure-git-gh.ps1
```

> 脚本不接收、不保存任何密码或 token。GitHub 登录走 `gh auth login` 的浏览器授权，凭据存入系统凭据管理器。

## 工作流示例

### 1. 初始化并关联远端

```powershell
git init
git add .
git commit -m "初始化仓库"
gh repo create my-project --private --source . --push
```

### 2. 用工作树隔离开发

```powershell
git worktree add .agents/worktrees/add-readme -b add-readme
cd .agents/worktrees/add-readme
```

`main` 保持干净，改动都在 `add-readme` 分支的独立目录里进行。

### 3. 提交并发起 PR

```powershell
git add README.md
git commit -m "docs: 添加 README"
git push -u origin add-readme
gh pr create --fill
```

## 环境说明

- 操作系统：Windows 10/11
- 终端：PowerShell 5.1（`powershell.exe`）
- Git 身份：`caron-china`
- 默认分支：`main`

## License

本仓库仅作示例用途，未附带许可证。
