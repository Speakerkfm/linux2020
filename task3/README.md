Задание
=============

1-я часть
-------------

А. Создать нескольких пользователей, задать им пароли, домашние директории и шеллы;

Б. Создать группу admin;

В. Включить нескольких из ранее созданных пользователей, а также пользователя root, в группу admin;

Г. Запретить всем пользователям, кроме группы admin, логин в систему по SSH в выходные дни (суббота и воскресенье, без учета праздников);

Д*. С учётом праздничных дней.
(Для упрощения проверки можно разрешить парольную аутентификацию по SSH и использовать ssh user@localhost проверяя логин с этой же машины)

2-я часть
-------------
Установить docker; дать конкретному пользователю:

А. права работать с docker (выполнять команды docker ps и т.п.);

Б*. возможность перезапускать демон docker (systemctl restart docker) не выдавая прав более, чем для этого нужно;

Выполнение
=============

1-я часть
-------------

A. Создадим трех пользователей пользователей

    1. User1
```
$ sudo useradd -d /home/user1 -m -c "Third user for testing" -p test1 -s /bin/bash user1
$ sudo cp -pr /home/vagrant/.ssh /home/user1
$ chown -R user1:user1 /home/user1/
```

    2. User2
```
$ sudo useradd -d /home/user2 -m -c "Third user for testing" -p test2 -s /bin/bash user2
$ sudo cp -pr /home/vagrant/.ssh /home/user2
$ chown -R user2:user2 /home/user2/
```

    3. User3
```
$ sudo useradd -d /home/user3 -m -c "Third user for testing" -p test3 -s /bin/bash user3
$ sudo cp -pr /home/vagrant/.ssh /home/user3
$ chown -R user3:user3 /home/user3/
```

Проверим возможность логина по ssh

```
stud_centos_2 ssh -i .vagrant/machines/default/virtualbox/private_key -p 2222 user3@localhost
[user3@localhost ~]$ ls
[user3@localhost ~]$ pwd
```

/home/user3

Б. Создадим группу admin

`$ groupadd admin`

В. Добавим user1, user2 и root в группу admin

```
$ usermod -a -G admin user1
$ usermod -a -G admin user2
$ usermod -a -G admin root
```

Првоерим для user1

`[user1@localhost ~]$ id`

uid=1002(user1) gid=1002(user1) groups=1002(user1),1005(admin) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023

Г. Запретим всем пользователям, кроме группы admin, логин в систему по SSH в выходные дни (суббота и воскресенье, без учета праздников)

Для начала установим модуль pam_script

`$ dnf install pam_script`

Изменим срипт для account

`$ vi /etc/pam.d/pam_script_acct`

```bash
runscript () {
        script="$1"
        shift

        if groups $PAM_USER | grep admin > /dev/null; then
                return 0
        else
                if [[ $(date +%u) -lt 6 ]] ; then
                        return 0
                else
                        return 1
                fi
        fi

        if [ ! -e "$script" ]; then
                return 0
        fi

        goodperms "$script" || return 1

        /bin/sh "$script" "$@"
        return $?
}
```

PS Скорее всего это костыль и можно сделать как-то по другому. Но как я только не пытался, указать путь к внешнему скрипту не получилось. :(

Далее в добавим проверку в pam.d

`$ vi /etc/pam.d/sshd`

```bash
account    required     pam_script.so
```

И проверим, что все работает

```bash
stud_centos_2 ssh -i .vagrant/machines/default/virtualbox/private_key -p 2222 user2@localhost
Last login: Sun Oct 25 13:19:22 2020 from 10.0.2.2
[user2@localhost ~]$ exit
logout
Connection to localhost closed.
stud_centos_2 ssh -i .vagrant/machines/default/virtualbox/private_key -p 2222 user3@localhost
Connection closed by 127.0.0.1 port 2222
```

2-я часть
-------------

Установим докер по инструкции с сайта и проверим, что все работает

```bash
[user2@localhost ~]$ docker --version
Docker version 20.10.0-beta1, build ac365d7
```

Добавим бинарник докера в группу docker и запретим всем остальным иметь к нему доступ

```
bash-4.4# chgrp docker /usr/bin/docker
bash-4.4# chmod 750 /usr/bin/docker
bash-4.4# ls -la /usr/bin/docker
-rwxr-x---. 1 root docker 71069376 Oct 13 18:17 /usr/bin/docker
```

Проверим, что user2 теперь не имеет доступ к командам докера

```
[user2@localhost ~]$ docker --version
-bash: /usr/bin/docker: Permission denied
```

Добавим user2 в группу docker

```bash-4.4#usermod -a -G docker user2```

Перезайдем в систему от user2 и попробуем снова

```
[user2@localhost ~]$ docker --version
Docker version 20.10.0-beta1, build ac365d7
```

