# YSYX Review Studio

这是一个零依赖的静态复习网站，内容以当前工作树中的实现为准，重点覆盖 YSYX 2306 C1–C6，并直接使用当前已经完成的五级流水线代码讲解考核知识点。

## 打开方式

在 WSL 中，一键启动本地服务并调用 Windows 浏览器：

```bash
./review-site/open.sh
```

首次运行会在后台启动服务；之后再次运行会复用同一个站点并重新打开浏览器。

脚本会把当前的 `WSL_DISTRO_NAME` 传给网页，用于生成 Windows 浏览器可用的 VS Code WSL Remote 链接。若发行版名不正确，可在网页左侧的“WSL 发行版”输入框中改成实际名称，例如 `Ubuntu` 或 `Ubuntu-22.04`。

脚本默认使用 `http://127.0.0.1:4173`；端口被占用时可改用：

```bash
YSYX_REVIEW_PORT=4174 ./review-site/open.sh
```

也可以直接在浏览器中打开 `index.html`。若浏览器限制本地剪贴板或 VS Code 链接，建议在仓库根目录运行：

```bash
python3 -m http.server 4173 --directory review-site
```

随后访问 `http://localhost:4173`。页面不需要安装 npm 包、构建工具或后端服务。

## 页面内容

- C1–C6 必做题、重要选做题、代码阅读锚点、为什么这样实现、验证命令和口述答案；
- 一周复习计划与本机保存的完成进度；
- 一生一芯项目架构图、当前 NPC 微架构图、AM 到 NPC 的 Makefile 调用时序图；
- 45 分钟模拟考核和全部题库答案；
- Windows 浏览器通过 VS Code WSL Remote URI 直达当前工作区源码；
- PPT 答辩骨架及飞书要求待核对提示。

## 安全提示

页面只复制命令，不会自动执行。`make -C npc npc` 和 `make -C npc run` 默认会走根目录 tracer Git 记录逻辑；网页给出的运行命令均在末尾带有 `git_commit=` 以覆盖该宏。运行之前仍应先检查 `git status --short --branch`，因为构建会产生镜像、日志和 build 目录内容。
