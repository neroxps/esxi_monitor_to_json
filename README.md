# 前言

楼主是用小马 V5 主机，部署 ESXI 虚拟化，一块 mstat SSD 装虚拟系统和一块 3.5英寸 2T的硬盘做数据盘。

由于没有做冗余，比较担心硬盘挂了不能提前知道，希望利用 HA 的自动化功能来帮我监控硬盘的 smart 数据。

经 **[huex](https://bbs.hassbian.com/?2026)** 大佬点拨，我写了个 shell。

利用 esxcli esxtop smartctl（第三方） 等命令获取 esxi 中的内存 CPU 还有硬盘的 smart 信息，将信息通过 jq 命令生成 json。

最后放入 esxi 的 http 根目录，那么 homeassistant 就可以通过  **[Template Sensor](https://www.home-assistant.io/components/sensor.template/)**  的方式获取 esxi 中的 json 数据，组成 sensor。

# 使用方法

1. 开启 ESXI 的 SSH 连入。
2. 上传 **[monitoring-1.0.0-5.x86_64.vib](https://raw.githubusercontent.com/neroxps/esxi_monitor_to_json/master/monitor/build/monitoring-1.0.0-5.x86_64.vib)** 至 ESXI 存储内。
3. 运行 `esxcli software acceptance set --level=CommunitySupported` 将软件包接受级别改成社区
4. 运行 `esxcli software vib install -v /vmfs/volumes/SSD2/monitoring-1.0.0-5.x86_64.vib -f` 安装我做好的软件包，其中 **SSD2** 请修改为自己存储的名字。
5. 运行 `ps -c | grep monitoring | grep -v grep` 如果回显有返回的话证明程序正常运行。

# HA 配置

执行完以上安装过程后，你就可以通过  **https://192.168.1.10/value.json** 下载得到监控生成的 json 文件，这时候就可以参考 **[Template Sensor](https://www.home-assistant.io/components/sensor.template/)** 编写 homeassistant 的配置了。

文末我会放上我的 home-assistant 配置作为参考。
