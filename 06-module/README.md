# Домашняя работа по занятию "08.06 Создание собственных modules"

Установим получившуюся коллекцию (https://github.com/Prividen/yandex_cloud_elk):
```
[mak@mak-ws ansible-collection]$ cat > requirements.yml
---
collections:
  - name: https://github.com/Prividen/yandex_cloud_elk
    version: 1.0.0
    type: git

[mak@mak-ws ansible-collection]$ ansible-galaxy collection install -r requirements.yml -p collections
...
Created collection for prividen.yandex_cloud_elk:1.0.0 at /home/mak/ansible-collection/collections/ansible_collections/prividen/yandex_cloud_elk
prividen.yandex_cloud_elk:1.0.0 was installed successfully
```

В [документации](https://docs.ansible.com/ansible/devel/dev_guide/developing_collections_structure.html#playbooks-directory) обещают, 
что начиная с версии 2.11 можно будет обращаться к плейбукам по их FQDN 
("In ansible-core 2.11 and later, you can use the FQCN, namespace.collection.playbook (with or without extension), to reference the playbooks from the command line or from import_playbook.")

Но у меня с моей версией так пока не получилось, приходится копировать плейбуки и групварсы в локальный каталог:
```
[mak@mak-ws ansible-collection]$ cp -r collections/ansible_collections/prividen/yandex_cloud_elk/playbooks/* ./
```

## Создание текстового файла
Проверим плейбук/роль/модуль для создания текстового файла с содержимым:
```
[mak@mak-ws ansible-collection]$ ansible-playbook create_text_file.yml
...
TASK [prividen.yandex_cloud_elk.create_text_file : Create file with content] *******************************************
changed: [localhost]

PLAY RECAP *************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[mak@mak-ws ansible-collection]$ ansible-playbook create_text_file.yml
...
TASK [prividen.yandex_cloud_elk.create_text_file : Create file with content] *******************************************
ok: [localhost]

PLAY RECAP *************************************************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[mak@mak-ws ansible-collection]$ cat my_file.txt 
write this content
```

## Деплой ELK
Проверим плейбуки/роли/модуль для деплоя ELK стека:
```
[mak@mak-ws ansible-collection]$ ansible-playbook site.yml
...
TASK [Show hosts access info] ******************************************************************************************
ok: [localhost] => (item=) => {
    "msg": "elasticsearch-0: yc-user@62.84.118.51"
}
ok: [localhost] => (item=) => {
    "msg": "kibana-0: yc-user@62.84.118.156"
}
ok: [localhost] => (item=) => {
    "msg": "filebeat-0: yc-user@62.84.117.199"
}

PLAY RECAP *************************************************************************************************************
elasticsearch-0            : ok=17   changed=10   unreachable=0    failed=0    skipped=4    rescued=0    ignored=0   
filebeat-0                 : ok=14   changed=8    unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
kibana-0                   : ok=7    changed=4    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
localhost                  : ok=14   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[mak@mak-ws ansible-collection]$ ansible-playbook site.yml
...
PLAY RECAP *************************************************************************************************************
elasticsearch-0            : ok=15   changed=0    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0   
filebeat-0                 : ok=11   changed=0    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   
kibana-0                   : ok=6    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
localhost                  : ok=14   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
Идемпотентненько.

