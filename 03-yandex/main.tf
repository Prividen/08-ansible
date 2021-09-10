terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gh0k7cb2gn2mh9i1uc"
  folder_id = "b1g200bppkibol684gqj"
  zone      = "ru-central1-a"
}

locals {
  instance_names = toset(["el-instance", "k-instance", "fb-instance"])
}

data "yandex_vpc_subnet" "internal" {
  name = "default-ru-central1-a"
}

data "yandex_compute_image" "centos-latest" {
  family = "centos-8"
}

resource "yandex_compute_instance" "elk-instances" {
  for_each = local.instance_names

  name = each.key
  hostname = each.key

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos-latest.id
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.internal.id
    nat       = true
  }

  metadata = {
    ssh-keys = "cloud-user:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "external_ip_address_elk_instances" {
  value = {
    for k, v in yandex_compute_instance.elk-instances : k => v.network_interface.0.nat_ip_address
  }
}
