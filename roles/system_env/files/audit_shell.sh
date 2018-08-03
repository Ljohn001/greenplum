#!/bin/bash
# Author:    Felix-zh
# Date:      07-10-2018
# Function： 本脚用于记录用户登录系统所执行命令

pp=$(grep -r 'PS1=\"\\\[\\e' /etc/bashrc|awk -F'=' '{print $1}')
com=$(grep -r 'export PROMPT_COMMAND=' /etc/bashrc|awk '{print $1}')
his="'{ msg=\$(history 1 | { read x y; echo \$y; });user=\$(whoami); echo [\$(date \"+%F %T\")] \$(who am i) [\$user]:[\$(pwd)]: \$msg; } >> /tmp/\$(hostname).\$(whoami).history'"

sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
# 判断终端颜色
if [[ $pp != "PS1" ]];then
    echo 'PS1="\[\e[37;40m\][\[\e[1;32m\]\u\[\e[1;33m\]@\h \[\e[35;40m\]\w\[\e[0m\]]\\$ "' >> /etc/bashrc 
else
    echo "PS1 内容已存"
fi

# 判断记录命令
if [[ $com != "export" ]];then
    echo "export PROMPT_COMMAND=$his" >> /etc/bashrc
else
    echo "history 内容已存"
fi
