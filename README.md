# 介绍

针对 [BitComet](https://www.bitcomet.com/en/archive) 的外挂脚本，作为 BTN 兼容客户端，遵循 [BTN-Spec](https://github.com/PBH-BTN/BTN-Spec)

支持的功能为

1. 获取 BTN 服务器配置
2. 提交 Peers 快照
3. 更新 BTN 封禁规则
4. 订阅 IP 黑名单

启动获取 BTN 服务器配置后，遵循要求的间隔与首次延迟，计划并循环执行任务。

Peers 快照通过 BitComet WebUI 提取并分析，封装后提交。

支持目前规范中的所有字段，其中 [Flag](https://github.com/PBH-BTN/quick-references/blob/main/utp_flags.md) 替换为 qBittorrent 格式，可识别 `d D u U K ? I`

支持 IP 形式的封禁规则，使用 Windows 防火墙配合 [动态关键字](https://learn.microsoft.com/zh-cn/windows/security/operating-system-security/network-security/windows-firewall/dynamic-keywords) 以实现封禁。

自动订阅 IP 黑名单（[combine/all.txt](https://github.com/PBH-BTN/BTN-Collected-Rules/blob/main/combine/all.txt)）

# 使用方法

请先从以下链接创建 BTN 用户应用程序，记下 AppId 与 AppSecret

https://btn-prod.ghostchu-services.top/

动态关键字至少要求 Windows 10 21H2 左右的版本 （[未确认](https://github.com/MicrosoftDocs/windows-powershell-docs/blob/main/docset/winserver2022-ps/netsecurity/Get-NetFirewallDynamicKeywordAddress.md)）

可选择不使用动态关键字的 `nofw` 脚本，但不提供过滤功能

**所有脚本及命令默认在 PowerShell 下以管理员权限执行**

按下 **Win + X 键**，Windows 11 选择 “**终端管理员**”，Windows 10 选择 “**Windows PowerShell（管理员）**”

### 为什么需要管理员权限？

本脚本以下 3 种命令需要管理员权限执行

1. `New/Remove-NetFirewallRule`：创建／移除过滤规则
2. `New/Update/Remove-NetFirewallDynamicKeywordAddress`：创建／更新／移除动态关键字
3. `Set-ItemProperty`：修改注册表

   `Invoke-WebRequest` 命令需要使用 IE 引擎；当 IE 引擎未初始化时会报错停止

   通过修改注册表的方法跳过 IE 引擎的初始化检测，不影响功能

在使用 `nofw` 脚本时，1. 和 2. 并不需要；而 3. 仅在初始配置中，检测到 `Invoke-WebRequest` 命令报错时需要。

因此，`nofw` 脚本不强制要求管理员权限。

## 启用配置

执行

`iex (irm btn-bc.pages.dev)`

依照提示配置过滤规则、启动方式，并按填写 BitComet WebUI 与 BTN 服务器的访问信息即可完成配置

## 清除配置

执行

`iex (irm btn-bc.pages.dev/unset)`

确认清除的项目后按 Enter 键继续

## 可选配置

执行以下命令添加过滤规则

`iex (irm btn-bc.pages.dev/add)`

执行以下配置无过滤规则脚本

`iex (irm btn-bc.pages.dev/nofw)`

执行以下命令重建桌面快捷方式

`iex (irm btn-bc.pages.dev/link)`

执行以下命令重建自启动任务计划

`iex (irm btn-bc.pages.dev/task)`

执行以下命令清理 Windows 防火墙中的冗余规则

`iex (irm btn-bc.pages.dev/clean)`

# 安全提醒

从网络上获取并执行脚本会有较大的风险，特别是给予最高权限的

当网络脚本被恶意修改，或网络地址被挟持到恶意脚本时，会造成严重的后果

如有安全需求，请自行审查代码内容并保存至本地执行
