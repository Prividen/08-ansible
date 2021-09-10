# Установка ELK-стека

Так хотелось сделать домашку, что аж не смог дождаться яндексовского промокода! 
Сделал в контейнерах, с созданием их же в том же плейбуке. 

Так как мы в ходе установки запускаем сервисы, 
нам нужны специальные контейнеры с systemd внутри, воспользуемся образом [jrei/systemd-centos:8](https://hub.docker.com/r/jrei/systemd-centos).
К сожалению, в этом образе не стоит `sudo`, поэтому в инвентори в vars пропишем `ansible_become_method: su` 
(не то, чтобы нам это become вообще было нужно для контейнеров, но вдруг мы потом захотим на виртуалки от яндекса перейти!)

Так же, имена контейнеров `el-instance`, `k-instance`, `fb-instance` не должны быть заняты, и для elasticsearch'а понадобится
на хосте сказать `sysctl -w vm.max_map_count=262144`.

Разберём плейбук по плеям и по таскам:
## 1. Deploy docker containers for ELK stack
Выполняется на localhost.   
Создание контейнеров я решил оформить как pre_tasks, т.к. налицо подготовительные работы, 
возможно когда-нибудь потом захотящие своих хандлеров. Запускаются три контейнера, с нужными портами. 
Имена прибиты гвоздями, по хорошему брать бы их из инвентрори, а настройки контейнеров из group_vars, 
но я пока не придумал, как. Привелегированный режим и монтирование cgroups нужно для systemd внутри.

## 2. Prepare hosts for installation
Выполняется на всех хостах.  
Настраиваем репозитарий elastic.co. Установка пакетов через репозитарий - кажется мне наиболее правильной
идеологически, и кроме того, это проходит `--check`-проверки и таски по установке пакетов выполняются весьма стремительно 
при последующих прогонах плейбуки, когда уже нет changed. Тоже своего рода подготовительный этап, поэтому pre_tasks.

## 3. Install Elasticsearch
Выполняется на группе хостов `elasticsearch`
### Install Elasticsearch
Устанавливаем пакет из репозитария, требуемой версии. Если что-то действительно установилось, и таска changed, 
оповестим специально обученный хендлер по (пере)запуску сервиса ("restart Elasticsearch").
### Set Java memory limit
Ява любит выжирать всю память, которую только находит (ну ок, половину, но от этого не легче), поэтому стоит слегка ограничить 
её аппетиты (2Gb heap). Еластик при запуске берёт опции Явы из `/etc/elasticsearch/jvm.options.d/`, так что подсунем туда 
наш конфиг.
### Configure Elasticsearch
Подсовываем еластику теймплейт его конфига. При изменении, оповещаем хандлер перезапуска сервиса.

## 4. Install Kibana
Выполняется на группе хостов `kibana`  
Всё очень простенькое, установка RPM-пакета, шаблон конфига, дёргаем хандлер сервиса.

## 5. Install Filebeat
Выполняется на группе хостов `filebeat`  
Начинается всё тоже очень простенько, установка RPM-пакета / шаблон конфига.

### Check if system module was already enabled
У filebeat конфиги модулей лежат в `/etc/filebeat/modules.d/`, если с постфиксом .disabled (по умолчанию) - значит, не активные.
В этой таске мы проверяем, есть ли у нас файл `/etc/filebeat/modules.d/system.yml`, т.е. был ли включен модуль `system`. Это
нужно для следующей таски:
### Custom system module path
Модуль `system` хочет читать файлы логов syslog. А его там в CentOS8 нету, там journald, а для него другой модуль нужен. 
Чтобы получить какие-нибудь логи, пропишем кастомные пути к паре настоящих лог-файлов. А чтобы не запутаться в включенном-выключенном 
модуле и в какой конфиг писать, мы будем пытаться создавать этот конфиг только если модуль `system` ещё не включен.
### Wait for Elasticsearch (Kibana) port is up
Дальнейшие таски будут нуждаться в работающих elasticsearch и kibana. Kibana поднимает порт сильно не сразу после запуска, и, 
хотя она скорее всего успеет подняться, пока мы устанавливаем filebeat, не будем рисковать. Дождёмся портов этих сервисов. 

А дальше у нас уже дополнительная конфигурация стека, напрашивается использование post_tasks.
### Enable filebeat system module
Включаем модуль `system`. Так как эта операция создаёт файл `/etc/filebeat/modules.d/system.yml`, будем использовать 
это условие для обеспечения идемпотентности. Т.к. меняются конфиги, логично оповестить хандлер сервиса.
### Check if filebeat dashboards was already configured
Чтобы обыдемпотентить следующую таску по конфигурации дашбоардов, нам нужно как-то проверить, были ли они уже сконфигурированы. 
Ничего умнее, чем поискать в еластике слово "filebeat", я не придумал. Так как какой-то ответ от эластика возвращается в любом 
случае, а парсить JSON'ы я не осилил, будем просто проверять длину ответа. Она там полторы сотни байт в случае отрицательного 
результата, и килобайты при положительном запросе, так что сравниние с 1000 работает нормально. 
### Load Kibana dashboard
Настройка кибановских дашбоардов. Если поискать syslog, можно даже увидеть какие-то живые данные. Эта таска тоже рестартит 
сервис filebeat, но я не уверен, что это нужно. Настраиваются-то по существу другие сервисы...

---
Идемпотентность плейбука достигнута, линт-проверки проходит без ошибок.  
На таски развешаны соответствующие теги (`elasticsearch`, `kibana`, `filebeat`).

---
# Yandex-облако
Ну, и чтобы не удаляться далеко от заявленной темы занятия, поработаем с Яндекс-облаком с помощью cli-клиента и [Терраформа](main.tf):
```yaml
mak@test-xu20:~$ yc compute instance create --name my-yc-instance1 --ssh-key ~/.ssh/id_rsa.pub
done (23s)
id: fhmtthakdctivoiv1c4d
folder_id: b1g200bppkibol684gqj
created_at: "2021-09-09T20:39:03Z"
name: my-yc-instance1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "2147483648"
  cores: "2"
  core_fraction: "100"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: fhm6jg3o8jmgjogtkmbl
  auto_delete: true
  disk_id: fhm6jg3o8jmgjogtkmbl
network_interfaces:
- index: "0"
  mac_address: d0:0d:1d:ec:55:46
  subnet_id: e9baom1v9g6ete60l0qe
  primary_v4_address:
    address: 10.128.0.30
fqdn: fhmtthakdctivoiv1c4d.auto.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}

mak@test-xu20:~$ yc compute instance add-one-to-one-nat --network-interface-index 0  fhmtthakdctivoiv1c4d
done (5s)
id: fhmtthakdctivoiv1c4d
folder_id: b1g200bppkibol684gqj
created_at: "2021-09-09T20:39:03Z"
name: my-yc-instance1
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "2147483648"
  cores: "2"
  core_fraction: "100"
status: RUNNING
boot_disk:
  mode: READ_WRITE
  device_name: fhm6jg3o8jmgjogtkmbl
  auto_delete: true
  disk_id: fhm6jg3o8jmgjogtkmbl
network_interfaces:
- index: "0"
  mac_address: d0:0d:1d:ec:55:46
  subnet_id: e9baom1v9g6ete60l0qe
  primary_v4_address:
    address: 10.128.0.30
    one_to_one_nat:
      address: 62.84.113.14
      ip_version: IPV4
fqdn: fhmtthakdctivoiv1c4d.auto.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}
```
```shell
mak@test-xu20:~$ terraform apply -auto-approve
...
yandex_compute_instance.elk-instances["k-instance"]: Creating...
yandex_compute_instance.elk-instances["fb-instance"]: Creating...
yandex_compute_instance.elk-instances["el-instance"]: Creating...
yandex_compute_instance.elk-instances["k-instance"]: Still creating... [10s elapsed]
yandex_compute_instance.elk-instances["fb-instance"]: Still creating... [10s elapsed]
yandex_compute_instance.elk-instances["el-instance"]: Still creating... [10s elapsed]
yandex_compute_instance.elk-instances["el-instance"]: Creation complete after 20s [id=fhm2o133pv0c3kn68691]
yandex_compute_instance.elk-instances["k-instance"]: Still creating... [20s elapsed]
yandex_compute_instance.elk-instances["fb-instance"]: Still creating... [20s elapsed]
yandex_compute_instance.elk-instances["fb-instance"]: Creation complete after 20s [id=fhmnj3abnaet9ikecl66]
yandex_compute_instance.elk-instances["k-instance"]: Creation complete after 20s [id=fhm4b6c9gtgbbbtk3lr9]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_elk_instances = {
  "el-instance" = "62.84.113.235"
  "fb-instance" = "62.84.114.208"
  "k-instance" = "62.84.114.226"
}
```

Интересно, как бы эти Outputs терраформа запихнуть в ансиблево инвентори?..