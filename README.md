# 介绍

针对 [BitComet](https://www.bitcomet.com/en/archive) 的 BTN 兼容客户端，遵循 [BTN-Spec](https://github.com/PBH-BTN/BTN-Spec)

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

可选择不使用动态关键字的 `nofw` 版本，但不提供过滤功能

**所有脚本及命令默认在 PowerShell 下以管理员权限执行**

按下 **Win + X 键**，Windows 11 选择 “**终端管理员**”，Windows 10 选择 “**Windows PowerShell（管理员）**”

## 自动配置

### 启用配置

执行

`iex (irm btn-bc.pages.dev)`

选择需要启用过滤的 BT 应用程序文件，并按提示填写 BitComet WebUI 与 BTN 服务器的访问信息即可完成配置

### 清除配置

执行

`iex (irm bt-ban.pages.dev/unset)`

确认清除的项目后按 Enter 键继续

# 安全提醒

从网络上获取并执行脚本会有较大的风险，特别是给予最高权限的

当网络脚本被恶意修改，或网络地址被挟持到恶意脚本时，会造成严重的后果

如有安全需求，请自行审查代码内容并保存至本地执行
