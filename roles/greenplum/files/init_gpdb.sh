#!/bin/bash
export MASTER_DATA_DIRECTORY=/greenplum/data/gpmaster/gpseg-1
source /greenplum/soft/greenplum-db/greenplum_path.sh
source /greenplum/soft/greenplum-cc-web/gpcc_path.sh
/greenplum/soft/greenplum-db/bin/gpinitsystem -a -c /home/gpadmin/gpinitsystem_config

# install web_ui
if [ ! -f "install_web.sh" ];then
    echo "host     all         gpmon         0.0.0.0/0    md5" >> $MASTER_DATA_DIRECTORY/pg_hba.conf
    echo "#!/bin/bash" >> install_web.sh
    echo "/greenplum/soft/greenplum-db/bin/gpperfmon_install --enable --password gpmon --port 5432" >> install_web.sh
    echo "gpstop -afr" >> install_web.sh
    echo "gpcc start" >> install_web.sh
    /bin/bash install_web.sh
    echo "正在安装web监控。。。"
else
    echo "文件已存在"
    /bin/bash install_web.sh
    echo "安装web监控。。。"
fi

sed -i 's/log_statement=all/log_statement=ddl/g' $MASTER_DATA_DIRECTORY/postgresql.conf
