variable "app_name" {
  description = "Nombre base de la aplicación"
  type        = string
  default     = "Grupo_Colono-pagina"
}

variable "environment" {
  description = "Ambiente del despliegue"
  type        = string
  default     = "dev"
}

variable "nginx_version" {
  description = "Versión de la imagen nginx"
  type        = string
  default     = "1.25.3"

  validation {
    condition     = length(var.nginx_version) > 0
    error_message = "La versión de nginx no puede estar vacía."
  }
}

variable "nginx_port" {
  description = "Puerto externo para acceder a la app"
  type        = number
  default     = 8080

  validation {
    condition     = var.nginx_port >= 1024 && var.nginx_port <= 65535
    error_message = "El puerto debe estar entre 1024 y 65535."
  }
}
