# Роли для установки ELK-стека
Будем использовать замечательный проект https://github.com/adammck/terraform-inventory, позволяющий использовать terraform states в качестве dynamic inventory для Ансибля.

## Подготовка инфраструктуры:
```
$ export YC_CLOUD_ID=...
$ export YC_FOLDER_ID=...
$ export YC_TOKEN=...
$ terraform init
$ terraform plan
$ terraform apply
...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

## Скачивание ролей и запуск плейбука
```
$ ansible-galaxy install -r requirements.yml  -p roles/
Starting galaxy role install process
- extracting elasticsearch-role to /home/mak/netology/ansible/08-ansible/04-role/roles/elasticsearch-role
- elasticsearch-role (2.0.0) was installed successfully
- extracting logstash-role to /home/mak/netology/ansible/08-ansible/04-role/roles/logstash-role
- logstash-role (1.0.0) was installed successfully
- extracting kibana-role to /home/mak/netology/ansible/08-ansible/04-role/roles/kibana-role
- kibana-role (1.0.1) was installed successfully
- extracting filebeat-role to /home/mak/netology/ansible/08-ansible/04-role/roles/filebeat-role
- filebeat-role (1.1.1) was installed successfully

$ TF_HOSTNAME_KEY_NAME=name TF_STATE=./ ansible-playbook -i inventory/prod/ -i ~/go/bin/terraform-inventory site.yml
...
PLAY RECAP *************************************************************************************************************
app-instance-0             : ok=14   changed=8    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0   
el-instance-0              : ok=13   changed=8    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0   
k-instance-0               : ok=6    changed=4    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```

## Ссылки на роли:
- https://github.com/Prividen/kibana-role
- https://github.com/Prividen/filebeat-role
- https://github.com/Prividen/logstash-role
