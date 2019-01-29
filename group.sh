#/bin/bash
# 导入配置文件
source /root/mysql.conf
source /root/$1.txt
#参数$2=1时，创建新镜像
    # 当参数$3=1时，在新建的mysql里创建$4 数据库
    # 当参数$3=2时，在新建的mysql里创建bugfeel数据库并导入bugfeel_$4.sql数据库文件
# 参数$2=2的时候，创建新mysql数据库并自动导入指定版本的bugfeel_$3.sql，导入方式为建立映射使用docker自动导入
# 参数$2=3的时候，创建一个以$docker_name存储卷为基础的空MySQL镜像，在镜像中登录原mysql数据库并导出数据库，更新数据库文件bugfeel.sql，并生成数据库版本文件bugfeel_$3.sql
if [ "create" == $2 ]
then
    rm -rf /date/*
    docker rm -f $docker_name
    docker volume rm $docker_name
    docker run -d -p $port:3306 --name=$docker_name -e MYSQL_ROOT_PASSWORD=$password -v $docker_name:/var/lib/mysql/ -v /date:/docker-entrypoint-initdb.d $mysql_v

    # mysql启动中，倒计时
    echo "mysql初始化中......"
    seconds_left=20
    echo "请等待${seconds_left}秒……"
    while [ $seconds_left -gt 0 ];do
      echo -n $seconds_left
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -ne "\r     \r" #清除本行文字
    done
    echo "启动mysql镜像$docker_name 成功,端口为$port,密码为$password"
    
    # 创建数据库$3 过程
    if [ 1 == $3 ]
    then
	# mysql创建
	# mysql -h${hostname} -P${port} -uroot -p${password}  -e "create database $3;"
        docker exec -it $docker_name bash -c "mysql -uroot -p$password -e \"create database $4;\""
        echo "创建$4 数据库成功"

    # 导入数据库$2 过程
    elif [ 2 == $3 ]
    then
	docker exec -it $docker_name bash -c "mysql -uroot -p$password -e \"create database bugfeel;\""
	echo "创建数据库bugfeel成功"
	cp /backupdata/bugfeel_$4.sql /date/bugfeel_$4.sql
	docker exec -it $docker_name bash -c "mysql -uroot -p$password bugfeel -e \"source /docker-entrypoint-initdb.d/bugfeel_$4.sql;\""
        #mysql导入
	#mysql -h$[hostname} -P${port} -uroot -p${password} -e "create database bugfeel"
	#mysql -h${hostname} -P${port} -uroot -p${password} -e "source /date/bugfeel_$3.sql"
	echo "导入数据表bugfeel_$4.sql成功"
    else
        echo "参数2错误"
    fi

# 重新创建导入数据库,docker自动导入
elif [ "import" == $2 ] #导入数据库文件 $2为sql文件名 
then
    rm -rf /date/*
    #cp $3 /date/$3
    docker rm -f $docker_name
    docker volume rm $docker_name
    cp /backupdata/bugfeel_$3.sql /date/bugfeel_$3.sql
    docker run -d -p $port:3306 --name=$docker_name -e MYSQL_ROOT_PASSWORD=$password -v $docker_name:/var/lib/mysql/ -v /date:/docker-entrypoint-initdb.d $mysql_v
    
    
    echo "导入数据库文件 bugfeel_$3.sql 成功,端口为$port,数据库密码为$password"

# 导出数据库，生成版本文件过程
elif [ "export" == $2 ]  #导出数据   $3为数据库版本
then
    #mysqldump -h$hostname -P$port -uroot -p$password --databases bugfeel > /backup/bugfeel.sql
    docker run --rm --volumes-from $docker_name -v /backup:/backup $mysql_v bash -c "mysqldump -h$hostname -P$port -uroot -p$password --databases bugfeel> /backup/bugfeel.sql"
    cp /backup/bugfeel.sql /backupdata/bugfeel_$3.sql
    echo "导出数据库bugfeel成功,生成版本文件 bugfeel_$3.sql"
elif [ "help" == $2 ]
then
	echo -e " 参数$2=1时，创建新镜像\n     当参数$3=1时，在新建的mysql里创建$4 数据库\n     当参数$3=2时，在新建的mysql里创建bugfeel数据库并导入bugfeel_$4.sql数据库文件\n 参数$2=2的时候，创建新mysql数据库并自动导入指定版本的bugfeel_$3.sql，导入方式为建立映射使用docker自动导入\n 参数$2=3的时候，创建一个以$docker_name 存储卷为基础的空MySQL镜像，在镜像中登录原mysql数据库并导出数据库，更新数据库文件bugfeel.sql，并生成数据库版本文件bugfeel_$3.sql"

else
    echo "参数错误"
fi

