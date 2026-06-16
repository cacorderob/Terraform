# ── Recurso 1: Imagen Docker ─────────────────────────────────────────────────────────​

resource "docker_image" "nginx" {

  name = "nginx:${var.nginx_version}" # nginx:latest​

  keep_locally = false # eliminar imagen al hacer destroy​

}

# ── Recurso 2: Contenedor Docker ─────────────────────────────────────────────────────​

resource "docker_container" "web" {

  name = "${var.app_name}-${var.environment}" # colono-web-dev​

  image = docker_image.nginx.image_id # referencia al recurso anterior​

  # Mapeo de puertos: host:contenedor​

  ports {

    internal = 80 # nginx escucha en el puerto 80 dentro del contenedor​

    external = var.nginx_port # accesible desde localhost:8080​

  }

  # Esto reemplaza el index.html por defecto de nginx​

  volumes {
    host_path      = abspath(path.module)
    container_path = "/usr/share/nginx/html"
  }

  # Etiquetas para identificar el contenedor​

  labels {

    label = "environment"

    value = var.environment

  }

  labels {

    label = "managed_by"

    value = "Terraform"

  }

  labels {

    label = "project"

    value = var.app_name

  }

}