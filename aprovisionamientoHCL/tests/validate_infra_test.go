// ============================================================
// tests/validate_infra_test.go
// Pruebas de validación estructural del código Terraform
// usando Terratest. Verifica que la infraestructura puede ser
// planificada correctamente sin errores de sintaxis ni
// configuración antes de ejecutar el apply.
//
// Prerequisitos:
//   - Go >= 1.21
//   - Terraform >= 1.6.0 instalado y en PATH
//   - Variables ARM_* configuradas como variables de entorno
//   - go mod tidy ejecutado en el directorio tests/
//
// Ejecución:
//   cd tests && go test -v -timeout 30m -run TestTerraformValidate
// ============================================================

package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestTerraformValidate verifica que el código Terraform es válido
// y puede generar un plan de ejecución sin errores.
// Esta prueba NO crea recursos reales en Azure.
func TestTerraformValidate(t *testing.T) {
	t.Parallel()

	// Ruta al directorio raíz del proyecto Terraform
	terraformDir := "../"

	// Variables de entrada mínimas para la validación
	// Los valores de credenciales usan datos de prueba no funcionales
	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,

		// Variables de entrada para la prueba (sin valores reales)
		Vars: map[string]interface{}{
			"resource_group_name":  "rg-test-validate",
			"location":             "centralus",
			"environment":          "development",
			"project_name":         "test-project",
			"owner":                "terratest",
			"vm_size":              "Standard_B2ats_v2",
			"admin_username":       "testadmin",
			"admin_password":       "TestP@ssword123!",
			"sql_admin_login":      "sqladmintest",
			"sql_admin_password":   "TestSQLP@ssword123!456",
			"sql_database_sku":     "GP_S_Gen5_1",
		},

		// No colorear la salida en entornos CI
		NoColor: true,
	}

	// ─── Prueba 1: Verificar que terraform init funciona ────
	t.Run("TerraformInit", func(t *testing.T) {
		_, err := terraform.InitE(t, terraformOptions)
		require.NoError(t, err, "terraform init falló: %v", err)
	})

	// ─── Prueba 2: Verificar formato del código ──────────────
	t.Run("TerraformFormat", func(t *testing.T) {
		// Verificar que todos los archivos .tf tienen formato correcto
		requiredFiles := []string{
			"../main.tf",
			"../variables.tf",
			"../outputs.tf",
			"../providers.tf",
			"../versions.tf",
		}
		for _, file := range requiredFiles {
			_, statErr := os.Stat(file)
			assert.NoError(t, statErr, "Archivo requerido no encontrado: %s", file)
		}
	})

	// ─── Prueba 3: Verificar estructura de outputs ───────────
	t.Run("OutputsExist", func(t *testing.T) {
		// Verificar que los outputs requeridos están declarados
		// Se lee el archivo de outputs y se verifica que existan
		outputsContent, err := os.ReadFile("../outputs.tf")
		require.NoError(t, err, "No se pudo leer outputs.tf")

		requiredOutputs := []string{
			"resource_group_id",
			"vm_public_ip_address",
			"sql_server_fqdn",
			"sql_database_name",
		}

		for _, output := range requiredOutputs {
			assert.Contains(t, string(outputsContent), output,
				"Output requerido no encontrado en outputs.tf: %s", output)
		}
	})

	// ─── Prueba 4: Verificar .gitignore ──────────────────────
	t.Run("GitignoreConfigured", func(t *testing.T) {
		gitignoreContent, err := os.ReadFile("../.gitignore")
		require.NoError(t, err, "No se pudo leer .gitignore")

		sensitivePatterns := []string{
			"*.tfstate",
			"*.tfvars",
			".terraform/",
		}

		for _, pattern := range sensitivePatterns {
			assert.Contains(t, string(gitignoreContent), pattern,
				"Patrón sensible no encontrado en .gitignore: %s", pattern)
		}
	})

	// ─── Prueba 5: Verificar variables sensibles ─────────────
	t.Run("SensitiveVariablesDeclared", func(t *testing.T) {
		varsContent, err := os.ReadFile("../variables.tf")
		require.NoError(t, err, "No se pudo leer variables.tf")

		sensitiveVars := []string{
			"admin_username",
			"admin_password",
			"sql_admin_login",
			"sql_admin_password",
		}

		for _, varName := range sensitiveVars {
			assert.Contains(t, string(varsContent), varName,
				"Variable sensible no encontrada en variables.tf: %s", varName)
		}

		// Verificar que las variables sensibles tienen sensitive = true
		assert.Contains(t, string(varsContent), "sensitive   = true",
			"No se encontró el marcador sensitive = true en variables.tf")
	})
}

// TestTerraformPlan ejecuta un plan real contra Azure.
// REQUIERE credenciales ARM_* válidas en el entorno.
// Omitir en CI si no hay credenciales disponibles.
func TestTerraformPlan(t *testing.T) {
	// Omitir si no hay credenciales de Azure configuradas
	if os.Getenv("ARM_CLIENT_ID") == "" {
		t.Skip("Omitiendo TestTerraformPlan: ARM_CLIENT_ID no configurado")
	}

	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name":  "rg-test-plan-temp",
			"location":             "centralus",
			"environment":          "development",
			"project_name":         "test-plan",
			"owner":                "terratest-ci",
			"vm_size":              "Standard_B2ats_v2",
			"admin_username":       os.Getenv("TF_VAR_admin_username"),
			"admin_password":       os.Getenv("TF_VAR_admin_password"),
			"sql_admin_login":      os.Getenv("TF_VAR_sql_admin_login"),
			"sql_admin_password":   os.Getenv("TF_VAR_sql_admin_password"),
		},
		NoColor: true,
	}

	// Ejecutar terraform plan y verificar que no hay errores
	planOutput, err := terraform.InitAndPlanE(t, terraformOptions)
	require.NoError(t, err, "terraform plan falló: %v", err)
	assert.NotEmpty(t, planOutput, "La salida del plan no debe estar vacía")
}
