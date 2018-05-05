#!/bin/sh
# 将esxi各项运行指标写入到 /usr/lib/vmware/hostd/docroot/ 目录，方便HA调用获取数据。
# 本脚本由 /etc/rc.local.d/local.sh 引导自启动 nohup /vmfs/volumes/SSD/monitoring_value_to_json.sh &

# 脚本依赖：
# - jq [jq is a lightweight and flexible command-line JSON processor.](https://stedolan.github.io/jq/)
# - smartctl [Determine TBW from SSDs with S.M.A.R.T Values in ESXi (smartctl)]http://www.virten.net/2016/05/determine-tbw-from-ssds-with-s-m-a-r-t-values-in-esxi-smartctl/

jq='/opt/monitoring-tools/jq'
smartctl='/opt/monitoring-tools/smartctl'
json_file_path='/usr/lib/vmware/hostd/docroot/value.json'
global_sleep_num='5'

# 设置硬盘检查时间，默认 3600 一小时检查一次
gds_sleep_time=3600
gds_run_time=1524997803
# 设置空余内存检查时间，默认 900 十五分钟检查一次
gmf_sleep_time=900
gmf_run_time=1524997803
# 设置硬盘空间检查时间，默认 900 十五分钟检查一次
gss_sleep_time=900
gss_run_time=1524997803

json='{}'
#利用jq处理json
json_update() {
	# json_update key_url value json 
	# example: json_update '.one' '111' '{"one":"abc","tow":"cde"}'

	echo "$3" | $jq --arg update_value "$2" ''$1' = $update_value'
}

# 使用 esxcli storage vmfs extent list 命令历遍所有硬盘，利用 smartctl 程序
get_disk_smart() {
	local disk_urls=$(echo "${disk_list}" | awk '{print $4}' | awk '{print "/dev/disks/" $0}')
	for disk_url in $disk_urls; do
		local disk_smart=$($smartctl -d sat -A ${disk_url} | tail +8)
		local disk_volume_name=$(echo "${disk_list}" | grep "${disk_url##*/}" | awk '{print $1}')
		local line_num=$(echo "${disk_smart}" | wc -l);
		while [[ ${line_num} -gt 0 ]]; do
			local attribute_name=$(echo "${disk_smart}" | awk '{print $2}' | sed -n "${line_num}p" | sed 's/[-,%,<,>,{,}]//g')
			local value=$(echo "${disk_smart}" | awk '{print $10}' | sed -n "${line_num}p")
			local key='.Disks."'${disk_volume_name}'".SMART_Attributes."'${attribute_name}'"'
			json=$(json_update "${key}" "${value}" "${json}")
			let line_num--
		done
	done
	gds_run_time=$(date +%s)
}


# 获取 CPU 1\5\15分钟的负载情况
# esxcli system process stats load get
#    Load1Minute: 0.16
#    Load15Minutes: 0.17
#    Load5Minutes: 0.17
get_cpu_load() {
	local cpu_load=$(esxcli system process stats load get)
	local cpu_load_name=$(echo "${cpu_load}" | awk '{sub(":","",$1);print $1}' )
	for load_name in ${cpu_load_name}; do
		local cpu_load_value=$(echo "${cpu_load}" | grep ${load_name} | awk '{print $2}')
		local key='.PCPU_Load."'${load_name}'"'
		json=$(json_update "${key}" "${cpu_load_value}" "${json}")
	done
}

# 通过 esxtop 获取剩余内存，由于 esxtop 消耗资源比较大，建议将 memory_chack_sleep_time 设置为 900 十五分钟检查一次
get_memory_free(){
	local import_entity_file="/tmp/esxtop_null_entity"
	if [[ ! -f "${import_entity_file}" ]]; then
		touch "${import_entity_file}"
	fi
	local memory_free=$(esxtop -b -n 1 -import-entity "${import_entity_file}"  | awk '{ print $2}' | awk -F',' '{print $26}'| sed ':a;N;s/\n//g;ba' | sed 's/\"//g')
	local key='.Memory_Free_MByes'
	json=$(json_update "${key}" "${memory_free}" "${json}")
	gmf_run_time=$(date +%s)
}

get_storage_space(){
	local disks=$(echo "${disk_list}" | awk '{print $1}')
	local storage_space=$(df -h | awk '{$1="";print}')
	local all_attribute_name=$(echo "${storage_space}" | sed -n '1p' | sed 's/%//g')
	for disk_volume_name in ${disks}; do
		local value_num=1
		while [[ ${value_num} -le 4 ]]; do
			local attribute_name=$(echo "${all_attribute_name}" | awk -v a=${value_num} '{print $a}')
			local key='.Disks."'${disk_volume_name}'".Storage_space."'${attribute_name}'".'
			local value=$(echo "${storage_space}" | grep ${disk_volume_name} | awk -v a=${value_num} '{print $a}' )
			json=$(json_update "${key}" "${value}" "${json}")
			let value_num++
		done
	done
	gss_run_time=$(date +%s)
}



# 获取硬盘名称及卷名称，写在循环外，开机获取，如有热插拔设备可写到 get_disk_smart 函数里面。
# Volume Name  VMFS UUID                            Extent Number  Device Name                                                                 Partition
# -----------  -----------------------------------  -------------  --------------------------------------------------------------------------  ---------
# SSD          5a099852-dafbd298-2284-00e17c6800cc              0  t10.ATA_____LITEONIT_LMT2D128M6M_____________________002306140341________           1
# DATA         5a09a162-e7c3e18c-8767-00e17c6800cc              0  t10.ATA_____WDC_WD30EFRX2D68AX9N0_________________________WD2DWMC1T0693063          1
disk_list=$(esxcli storage vmfs extent list | tail +3)


#main
while true; do
	get_cpu_load
	if  [[ $(expr $(date +%s) - ${gds_run_time} ) -gt ${gds_sleep_time} ]]; then
		get_disk_smart
	fi

	if  [[ $(expr $(date +%s) - ${gmf_run_time} ) -gt ${gmf_sleep_time} ]]; then
		get_memory_free
	fi

	if  [[ $(expr $(date +%s) - ${gss_run_time} ) -gt ${gss_sleep_time} ]]; then
		get_storage_space
	fi

	echo "${json}" > ${json_file_path}
sleep ${global_sleep_num}
done