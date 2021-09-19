# Домашняя работа по занятию "08.05 Тестирование Roles"

> Установите molecule: `pip3 install "molecule==3.3.4"`

У меня в этой версии Молекулы один неприятный баг проявился: вне зависимости от выбранного сценария, 
если существует файл **default**/requiremets.yml, molecule пытается подгрузить из него зависимости. А в 
контейнере для tox-тестов git'а нету, и всё падает. Я попробовал работать с последней версией Молекулы, 
с ней вроде всё нормально. 
```
py36-ansible210 run-test: commands[0] | molecule test -s alternative --destroy=always
INFO     alternative scenario test matrix: destroy, create, prepare, converge, destroy
INFO     Performing prerun...
WARNING  Failed to locate command: [Errno 2] No such file or directory: 'git': 'git'
INFO     Guessed /opt/kibana_role as project root directory
INFO     Running ansible-galaxy role install --force --roles-path /root/.cache/ansible-lint/293d83/roles -vr molecule/default/requirements.yml
ERROR    No config file found; using defaults
[WARNING]: - elasticsearch_role was NOT installed successfully: could not
find/use git, it is required to continue with installing
https://github.com/Prividen/elasticsearch_role
ERROR! - you can use --ignore-errors to skip failed roles and finish processing the list.

Traceback (most recent call last):
...
```


> Запустите `docker run -it -v <path_to_repo>:/opt/elasticsearch-role -w /opt/elasticsearch-role /bin/bash`, где path_to_repo - путь до корня репозитория с elasticsearch-role на вашей файловой системе.

Мне понравилось сделать такой альясик: `tox() { export R=$(basename $(pwd)); docker run -it --rm -v $(pwd):/opt/$R -w /opt/$R --privileged py-test-env tox $*; }`, 
после чего в директории с ролью можно просто запускать команду tox, как будто она установлена локально: 
```
mak@test-xu20:~/ansible/08-ansible/05-testing/roles/kibana_role$ tox -r -p
✔ OK py39-ansible2latest in 5 minutes, 44.598 seconds
✔ OK py39-ansible210 in 5 minutes, 50.725 seconds
✔ OK py36-ansible210 in 5 minutes, 54.182 seconds
✔ OK py36-ansible2latest in 5 minutes, 55.114 seconds
_____________________________________________________________ summary ______________________________________________________________
  py36-ansible210: commands succeeded
  py36-ansible2latest: commands succeeded
  py39-ansible210: commands succeeded
  py39-ansible2latest: commands succeeded
  congratulations :)
```


> Создайте сценарий внутри любой из своих ролей, который умеет поднимать весь стек при помощи всех ролей.  
> Убедитесь в работоспособности своего стека. Создайте отдельный verify.yml, который будет проверять работоспособность интеграции всех инструментов между ними.

Это реализовано для всех ролей.

---
> Выложите свои roles в репозитории. В ответ приведите ссылки.

(включая свою версию elasticsearch_role, модифицированную под моё тестовое окружение)

| role name          | molecule tests | tox tests |
|--------------------|----------------|-----------|
| elasticsearch_role | https://github.com/Prividen/elasticsearch_role/tree/2.1.2-mk | https://github.com/Prividen/elasticsearch_role/tree/2.1.3-mk |
| kibana_role        | https://github.com/Prividen/kibana_role/tree/1.0.3 | https://github.com/Prividen/kibana_role/tree/1.0.4 |
| logstash_role      | https://github.com/Prividen/logstash_role/tree/1.0.2 | https://github.com/Prividen/logstash_role/tree/1.0.3|
| filebeat_role | https://github.com/Prividen/filebeat_role/tree/1.1.3| https://github.com/Prividen/filebeat_role/tree/1.1.4|
