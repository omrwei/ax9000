#加载新分区MTD22，分区自己确认一下
echo -----------------------------------------------
echo -e "是否使用MTD22分区安装工具?"
echo -e "1：使用并且格式化，适合初次使用"
echo -e "2：使用但不格式化，适合二次使用"
echo -e "3：不安装，直接继续运行工具"
read -p "请输入对应数字 > " num
echo -----------------------------------------------
if [ "$num" = 1 ] || [ "$num" = 2 ]; then
    #格式化
    [ "$num" = 2 ] && echo 跳过格式化 ||  mkfs.ext4 /dev/mtdblock22

    #创建文件夹
    mkdir /mtd22

    #/etc/fstab加一行自动挂载
    echo /dev/mtdblock22 /mtd22 ext4 defaults 0 0 >/etc/fstab

    #挂载新分区
    mount -a

    #验证是否挂载成功，未成功则手动挂载
    /bin/df |/bin/grep mtd22&& echo mtd22_挂载成功 || /bin/mount -t ext4 /dev/mtdblock22 /mtd22

    #下载压缩文件到/MTD22分区
    echo 查找安装文件
    cd  `dirname $0`
    if [ -n "$(echo $0 | grep '/mtd22/')" ]; then
        echo runtool已存在
    else
        cp -f $0 '/mtd22/runtool.sh'
    fi

    [ -n "$(ls | grep 'xxx.tar.gz')" ] && echo 处理XXX文件 || echo XXX文件不存在，无法继续执行。
    [ -n "$(ls | grep 'xxx.tar.gz')" ] && cp -f 'xxx.tar.gz' '/mtd22/xxx.tar.gz' || exit
    [ -n "$(ls | grep 'tmp.tar.gz')" ] && echo 处理TMP文件 || echo TMP文件不存在，无法继续执行。
    [ -n "$(ls | grep 'tmp.tar.gz')" ] && cp -f 'tmp.tar.gz' '/mtd22/tmp.tar.gz' || exit



    #载入压缩文件，尝试解压安装
    [ -n "$(find /mtd22/ -name 'xxx.tar.gz')" ] && echo 开始解压XXX || echo XXX文件不存在，无法继续执行。
    [ -n "$(find /mtd22/ -name 'xxx.tar.gz')" ] && echo ---------- || exit
    [ -n "$(find /userdisk/ -name 'auto_start.sh')" ] && echo xxx已解压 || /bin/tar -zxvf /mtd22/xxx.tar.gz  -C /

    [ -n "$(find /mtd22/ -name 'tmp.tar.gz')" ] && echo 开始解压TMP || echo TMP文件不存在，无法继续执行。
    [ -n "$(find /mtd22/ -name 'tmp.tar.gz')" ] && echo ---------- || exit
    [ -n "$(find /tmp/ -name 'alist')" ] && echo tmp已解压 || /bin/tar -zxvf /mtd22/tmp.tar.gz  -C /tmp
    echo  "MTD22分区设置成功！！！"
    source /etc/profile
elif [ "$num" = 3 ]; then
    echo "跳过，进行下一步"
else
    exit
fi

echo -----------------------------------------------
echo -e "是否启动所有工具?1:启动/0：跳过"
read -p "请输入对应数字 > " num
echo -----------------------------------------------

if [ "$num" = 1 ]; then
    source /etc/profile
    [ -n "$(find /tmp/ -name 'alist')" ] && echo tmp已解压 || /bin/tar -zxvf /mtd22/tmp.tar.gz  -C /tmp

    #链接和提权文件
    ln -sf /tmp/alist /userdisk/alist/alist
    ln -sf /tmp/rttys /userdisk/rttys/rttys
    chmod 777 /tmp/rttys
    chmod 777 /tmp/alist
    chmod 777 /userdisk/* -R
    chmod 777 /etc/vsftpd.conf -R
    chmod 777 /etc/init.d/clash
    chown root:root /etc/vsftpd.conf
    chown root:root /userdisk/* -R
    echo 启动 alist
    pidof alist>/dev/null && echo alist 已开启 || /userdisk/alist/alist restart

    echo 启动 rttys
    pidof rtty>/dev/null && echo rtty 已开启 || rtty -I xiaowei -h localhost -p 5912 -a -D

    echo 启动 rttys
    ln -sf /userdisk/rttys/rttys.db /rttys.db
    ln -sf /userdisk/rttys/rttys.db /root/rttys.db
    pidof rttys>/dev/null && echo rttys 已开启 || sh -c '/userdisk/rttys/rttys > /dev/null 2>&1 &'

    echo 启动zerotier
    pidof zerotier-one >/dev/null && echo zerotier已开启 || zerotier-one -d

    echo 启动clash
    pidof clash >/dev/null && echo clash已开启 || /etc/init.d/clash restart

    echo 启动vsftp
    pidof vsftpd>/dev/null && echo vsftp已开启 || vsftpd /etc/vsftpd.conf

    echo 启动samba
    /bin/netstat -anp |/bin/grep smbd >/dev/null&& echo smb已开启 || /etc/init.d/samba start>/dev/null

    echo 启动webdev
    pidof lighttpd>/dev/null && echo webdev 已开启 || lighttpd -f /etc/lighttpd/lighttpd.conf>/dev/null

    echo 启动 trafficd
    pidof trafficd>/dev/null && echo trafficd 已开启 || /etc/init.d/trafficd start>/dev/null

else
    exit
fi
