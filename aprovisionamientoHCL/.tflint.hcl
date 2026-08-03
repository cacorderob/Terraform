# ============================================================
# .tflint.hcl
# Configuración de TFLint para análisis estático del código
# Terraform. Detecta errores de tipo, configuraciones
# incorrectas y vulnerabilidades de seguridad.
# ============================================================

config {
  # Instala automáticamente los plugins declarados
  plugin_dir = ".tflint.d/plugins"

  call_module_type    = "local"
  force               = false
  disabled_by_default = false
}

# Plugin oficial para Azure: valida tipos y valores de recursos AzureRM
plugin "azurerm" {
  enabled = true
  version = "0.26.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# ─── Reglas generales de buenas prácticas ───────────────────

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}
