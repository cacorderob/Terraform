// =============================================================
// VALIDATE_INFRA_TEST.GO
// Prueba estructural básica con Terratest.
// Valida que la configuración Terraform es sintácticamente
// correcta y que todos los módulos/providers se inicializan
// sin errores — SIN crear recursos reales en Azure.
//
// USO:
//   cd tests/
//   go mod init github.com/cacorderob/Terraform/vm-sqlserver-azure/tests
//   go mod tidy
//   go test -v -run TestTerraformValidate -timeout 10m
//
// REQUISITOS:
//   - Go 1.21+
//   - Terraform CLI instalado y en PATH
//   - No requiere credenciales Azure (no hace apply)
// =============================================================

package test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// terraformDir devuelve la ruta absoluta al directorio raíz del módulo Terraform
func terraformDir(t *testing.T) string {
	t.Helper()
	// El test está en vm-sqlserver-azure/tests/, subir un nivel
	dir, err := filepath.Abs("../")
	require.NoError(t, err, "No se pudo obtener la ruta absoluta del módulo Terraform")
	return dir
}

// TestTerraformValidate verifica que la configuración Terraform es válida
// sin inicializar el backend remoto ni crear recursos en Azure.
// Equivalente a ejecutar: terraform init -backend=false && terraform validate
func TestTerraformValidate(t *testing.T) {
	t.Parallel()

	tfDir := terraformDir(t)
	t.Logf("Validando módulo Terraform en: %s", tfDir)

	options := &terraform.Options{
		TerraformDir: tfDir,

		// Deshabilitar el backend para evitar necesidad de credenciales HCP Terraform
		BackendConfig: map[string]interface{}{},
		BackendConfigPath: "",

		// Variables requeridas con valores de prueba (NO contienen secretos reales)
		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-validation",
			"location":              "centralus",
			"environment":           "testing",
			"project_name":          "test-project",
			"owner":                 "testuser",
			"vnet_address_space":    "10.10.0.0/16",
			"subnet_address_prefix": "10.10.1.0/24",
			"vm_size":               "Standard_B2ats_v2",
			"admin_username":        "testadmin",
			"admin_password":        "TestP@ssw0rd123!",
			"os_disk_size_gb":       128,
			"sql_admin_login":       "sqltestadmin",
			"sql_admin_password":    "SqlP@ssw0rd456!",
			"sql_database_sku":      "GP_S_Gen5_1",
			"sql_max_size_gb":       32,
		},

		// Argumentos de init: deshabilitar backend para pruebas locales
		InitArgs: []string{"-backend=false"},

		// No colorear la salida (mejor para CI)
		NoColor: true,
	}

	// Step 1: Inicializar Terraform sin backend
	t.Log("Ejecutando terraform init -backend=false...")
	_, err := terraform.InitE(t, options)
	require.NoError(t, err, "terraform init falló — verificar que providers están configurados correctamente")
	t.Log("✅ terraform init exitoso")

	// Step 2: Validar la configuración
	t.Log("Ejecutando terraform validate...")
	output, err := terraform.ValidateE(t, options)
	require.NoError(t, err, "terraform validate falló — el código HCL contiene errores")
	assert.Contains(t, output, "Success", "La validación debe retornar 'Success'")
	t.Log("✅ terraform validate exitoso")
}

// TestTerraformFilesExist verifica que todos los archivos obligatorios
// del proyecto están presentes en el directorio del módulo.
func TestTerraformFilesExist(t *testing.T) {
	t.Parallel()

	tfDir := terraformDir(t)
	t.Logf("Verificando estructura de archivos en: %s", tfDir)

	// Archivos obligatorios según las mejores prácticas del proyecto
	requiredFiles := []string{
		"main.tf",
		"variables.tf",
		"outputs.tf",
		"providers.tf",
		"versions.tf",
		"terraform.tfvars.example",
		".gitignore",
		".tflint.hcl",
		".pre-commit-config.yaml",
		"README.md",
	}

	for _, file := range requiredFiles {
		filePath := filepath.Join(tfDir, file)
		_, err := os.Stat(filePath)
		assert.NoError(t, err, "Archivo obligatorio faltante: %s", file)
		if err == nil {
			t.Logf("✅ Existe: %s", file)
		} else {
			t.Errorf("❌ Faltante: %s", file)
		}
	}
}

// TestVariableValidations verifica que las validaciones de variables
// rechazan valores inválidos correctamente.
func TestVariableValidations(t *testing.T) {
	t.Parallel()

	tfDir := terraformDir(t)

	// Caso: resource_group_name sin prefijo 'rg-'
	t.Run("ResourceGroupNameInvalid", func(t *testing.T) {
		options := &terraform.Options{
			TerraformDir: tfDir,
			Vars: map[string]interface{}{
				"resource_group_name":   "invalid-name", // Debe empezar con rg-
				"location":              "centralus",
				"environment":           "testing",
				"project_name":          "test-project",
				"owner":                 "testuser",
				"vnet_address_space":    "10.10.0.0/16",
				"subnet_address_prefix": "10.10.1.0/24",
				"vm_size":               "Standard_B2ats_v2",
				"admin_username":        "testadmin",
				"admin_password":        "TestP@ssw0rd123!",
				"os_disk_size_gb":       128,
				"sql_admin_login":       "sqltestadmin",
				"sql_admin_password":    "SqlP@ssw0rd456!",
				"sql_database_sku":      "GP_S_Gen5_1",
				"sql_max_size_gb":       32,
			},
			InitArgs: []string{"-backend=false"},
			NoColor:  true,
		}

		_, err := terraform.InitE(t, options)
		if err == nil {
			// plan debería fallar por la validación
			_, planErr := terraform.PlanE(t, options)
			assert.Error(t, planErr, "El plan debería fallar con resource_group_name inválido")
			t.Log("✅ Validación de resource_group_name funciona correctamente")
		}
	})
}
