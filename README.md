# 前言

楼主是用小马 V5 主机，部署 ESXI 虚拟化，一块 mstat SSD 装虚拟系统和一块 3.5英寸 2T的硬盘做数据盘。

由于没有做冗余，比较担心硬盘挂了不能提前知道，希望利用 HA 的自动化功能来帮我监控硬盘的 smart 数据。

经 **[huex](https://bbs.hassbian.com/?2026)** 大佬点拨，我写了个 shell。

利用 esxcli esxtop smartctl（第三方） 等命令获取 esxi 中的内存 CPU 还有硬盘的 smart 信息，将信息通过 jq 命令生成 json。

最后放入 esxi 的 http 根目录，那么 homeassistant 就可以通过  **[RESTful Sensor](https://www.home-assistant.io/components/sensor.rest/)**  的方式获取 esxi 中的 json 数据，组成 sensor。

# 使用方法

**1. 开启 ESXI 的 SSH 连入。**
**2. 上传 [monitoring-1.0.0-6.x86_64.vib](https://raw.githubusercontent.com/neroxps/esxi_monitor_to_json/master/monitor/build/monitoring-1.0.0-6.x86_64.vib) 至 ESXI 存储内。**
**3. 运行 `esxcli software acceptance set --level=CommunitySupported` 将软件包接受级别改成社区**
**4. 运行 `esxcli software vib install -v /vmfs/volumes/SSD2/monitoring-1.0.0-6.x86_64.vib -f` 安装我做好的软件包，其中 **SSD2** 请修改为自己存储的名字。**
**5. 运行 `ps -c |grep "monitoring_value_to_json.sh" | grep -v grep` 如果回显有返回的话证明程序正常运行。**

```
[root@esxi:~] esxcli software vib install -v /vmfs/volumes/SSD2/monitoring-1.0.0-6.x86_64.vib -f
Installation Result
   Message: Operation finished successfully.
   Reboot Required: false
   VIBs Installed: Neroxps_bootbank_monitoring_1.0.0-6
   VIBs Removed: 
   VIBs Skipped:
[root@esxi:~] ps -c |grep "monitoring_value_to_json.sh" | grep -v grep
2815619  2815619  sh                                   /bin/sh /opt/monitoring-tools/monitoring_value_to_json.sh
```

# 更新

**1. 先用 kill 停止脚本运行。**
**2. 再使用 `esxcli software vib update -v /vmfs/volumes/SSD2/monitoring-1.0.0-6.x86_64.vib -f` 更新插件。**

```
[root@esxi:~] ps -c |grep "monitoring_value_to_json.sh" | grep -v grep | awk '{print $1}'| xargs kill
[root@esxi:~] esxcli software vib update -v /vmfs/volumes/SSD2/monitoring-1.0.0-6.x86_64.vib -f
Installation Result
   Message: Operation finished successfully.
   Reboot Required: false
   VIBs Installed: Neroxps_bootbank_monitoring_1.0.0-6
   VIBs Removed: Neroxps_bootbank_monitoring_1.0.0-5
   VIBs Skipped: 
```

# 卸载

**和更新一样，先 kill 再卸载。**

```
[root@esxi:~] ps -c |grep "monitoring_value_to_json.sh" | grep -v grep | awk '{print $1}'| xargs kill
[root@esxi:~] esxcli software vib remove -n monitoring
Removal Result
   Message: Operation finished successfully.
   Reboot Required: false
   VIBs Installed: 
   VIBs Removed: Neroxps_bootbank_monitoring_1.0.0-6
   VIBs Skipped:
```

# HA 配置

执行完以上安装过程后，你就可以通过  **https://192.168.1.10/value.json** 下载得到监控生成的 json 文件，这时候就可以参考 **[Template Sensor](https://www.home-assistant.io/components/sensor.template/)** 编写 homeassistant 的配置了。

文末我会放上我的 home-assistant 配置作为参考。

# 更新日志

## [1.0.0-7]
### Fixed
 - 固定硬盘容量为GB，取消原来用 df -h 获取后 HA 无法统计曲线的 bug

## [1.0.0-6]
### Added
- 添加 `.Memory.Used_Pct` 字段。

### Fixed
- 将获取内存的方法从 `esxtop` 改为 `vsish -e get /memory/comprehensive` 大大提高内存获取速度。
- 内存获取时间由 15分钟一次改为5秒一次，与 CPU 同步。
- JSON `Memory_Free_MByes` 路径修改为 `Memory.Free_GB`,单位从 `MB` 改为 `GB`
