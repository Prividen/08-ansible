terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}

provider "yandex" {
  zone      = "ru-central1-a"
}


data "yandex_vpc_subnet" "default-subnet" {
  name = "default-ru-central1-a"
}

data "yandex_compute_image" "centos7" {
  family = "centos-7"
}

data "yandex_compute_image" "centos8" {
  family = "centos-8"
}

data "yandex_compute_image" "ubuntu-latest" {
  family = "ubuntu-2004-lts"
}


resource "yandex_compute_instance" "elasticsearch" {
  count = 1
  name = "el-instance-${count.index}"
  hostname = "el-instance-${count.index}"

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos7.id
      type = "network-ssd-nonreplicated"
      size = 93
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-subnet.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "kibana" {
  count = 1
  name = "k-instance-${count.index}"
  hostname = "k-instance-${count.index}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-latest.id
      type = "network-ssd"
      size = 8
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-subnet.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "filebeat" {
  count = 1
  name = "app-instance-${count.index}"
  hostname = "app-instance-${count.index}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos8.id
      type = "network-ssd"
      size = 10
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-subnet.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}


output "external_ip_address_elasticsearch" {
  value = yandex_compute_instance.elasticsearch.*.network_interface.0.nat_ip_address
}

output "external_ip_address_kibana" {
  value = yandex_compute_instance.kibana.*.network_interface.0.nat_ip_address
}

output "external_ip_address_filebeat" {
  value = yandex_compute_instance.filebeat.*.network_interface.0.nat_ip_address
}
