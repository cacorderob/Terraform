# =============================================================
# .TFLINT.HCL
# Configuración de TFLint — linter estático para Terraform.
# Detecta errores, mejores prácticas y problemas de seguridad
# antes de ejecutar terraform plan/apply.
#
# Documentación: https://github.com/terraform-linters/tflint
# =============================================================

config {
  # Activar el modo de plugins (descarga plugins al ejecutar tflint --init)
  plugin_dir = "~/.tflint.d/plugins"

  # Llamar la validación del módulo actual
  call_module_type = "local"

  # Deshabilitar la regla de versiones de módulos remotos
  # (no aplica para módulos de un solo directorio)
  force = false

  # Deshabilitar colores si se ejecuta en CI
  disabled_by_default = false
}

# -------------------------------------------------------
# PLUGIN: terraform (reglas nativas de Terraform)
# Incluye validaciones de mejores prácticas generales
# -------------------------------------------------------
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# -------------------------------------------------------
# PLUGIN: azurerm (reglas específicas de Azure)
# Valida tipos de recursos, SKUs válidos y configuraciones
# específicas del provider azurerm
# -------------------------------------------------------
plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# -------------------------------------------------------
# REGLAS HABILITADAS
# -------------------------------------------------------

# Advertir sobre tipos de datos incorrectos en variables
rule "terraform_typed_variables" {
  enabled = true
}

# Requerir descripción en todos los outputs
rule "terraform_documented_outputs" {
  enabled = true
}

# Requerir descripción en todas las variables
rule "terraform_documented_variables" {
  enabled = true
}

# Detectar módulos que no especifican versión
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

# Seguir las convenciones de nomenclatura de Terraform
rule "terraform_naming_convention" {
  enabled = true
}

# Requerir que los providers usen versiones fijas
rule "terraform_required_providers" {
  enabled = true
}

# Verificar la versión requerida de Terraform
rule "terraform_required_version" {
  enabled = true
}
