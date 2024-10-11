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

支持 IP 形式的封禁规则，使用 Windows 防火墙配合 [动态关键字](https://learn.microsoft.com/windows/security/operating-system-security/network-security/windows-firewall/dynamic-keywords) 以实现封禁。

自动订阅 IP 黑名单（[combine/all.txt](https://github.com/PBH-BTN/BTN-Collected-Rules/blob/main/combine/all.txt)）

　

**[PeerBanHelper](https://github.com/PBH-BTN/PeerBanHelper) 已适配 [BitComet 2.10](https://download.bitcomet.com/archive/BitComet_2.10_setup.exe)，建议升级**

# 系统要求

动态关键字至少要求 Windows 10 21H2（更早的版本 [未确认](https://github.com/MicrosoftDocs/windows-powershell-docs/blob/main/docset/winserver2022-ps/netsecurity/New-NetFirewallDynamicKeywordAddress.md)）

可选择不使用动态关键字的 `nofw` 脚本，但不提供过滤功能

**所有命令及脚本默认在 Windows PowerShell 下以管理员权限执行**

## 为什么需要管理员权限？

以下 Windows 防火墙命令需要管理员权限执行

1. `New/Remove-NetFirewallRule`：创建／移除过滤规则
2. `New/Update/Remove-NetFirewallDynamicKeywordAddress`：创建／更新／移除动态关键字

`nofw` 脚本仅提交 Peers 快照，不使用 Windows 防火墙，因此不需要管理员权限。

### 风险提示

从网络上获取并执行脚本会有较大的风险，特别是给予管理员权限的。

当网络脚本被恶意修改，或网络地址被挟持到恶意脚本时，会造成严重的后果。

如有安全需求，请自行审查代码内容并保存至本地执行。

# 使用方法

## 准备工作

从以下链接创建 BTN 用户应用程序，记下 AppId 与 AppSecret

https://btn-prod.ghostchu-services.top/

---

打开 BitComet 的 工具--选项--高级设置--远程下载，勾上 “启用网页版远程下载”，填写并记下用户名与密码

可复制网页地址，也可在配置时手动输入地址与端口（通常使用 192.168.x.x 局域网地址或 127.0.0.1 回环地址）

![BitComet_Setting](https://github.com/user-attachments/assets/7a71e244-eeca-4ee4-a6a1-6465f0d40e10)

---

建议使用 BitComet 2.10 以上的版本，并开启 “在全局速度限制中忽略远程访问连接”

![BitComet_Adv](https://github.com/user-attachments/assets/3e593bec-41aa-4b93-9d94-dee43344a04c)


## 启用配置

按下 **Win + X 键**，Windows 11 选择 “**终端管理员**”，Windows 10 选择 “**Windows PowerShell（管理员）**”

执行

`iex (irm btn-bc.pages.dev)`

按照提示配置过滤规则、启动方式，并填写 BitComet WebUI 与 BTN 服务器的访问信息即可完成配置

## 清除配置

执行

`iex (irm btn-bc.pages.dev/unset)`

确认清除的项目后按 Enter 键继续

## 可选配置

执行以下命令添加过滤规则

`iex (irm btn-bc.pages.dev/add)`

执行以下命令配置无过滤功能脚本

`iex (irm btn-bc.pages.dev/nofw)`

执行以下命令重建桌面快捷方式

`iex (irm btn-bc.pages.dev/link)`

执行以下命令重建自启动任务计划

`iex (irm btn-bc.pages.dev/task)`

执行以下命令清理 Windows 防火墙中的冗余规则

`iex (irm btn-bc.pages.dev/clean)`
