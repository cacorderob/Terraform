output "url_app" {
  description = "URL para ver tu app"
  value       = "http://localhost:${var.nginx_port}"
}

output "nombre_contenedor" {
  description = "Nombre real del contenedor en Docker"
  value       = docker_container.web.name
}

output "ambiente" {
  description = "Ambiente desplegado"
  value       = var.environment
}