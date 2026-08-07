# Plan: DemoIBM — Reporte de Jobs Activos con CI/CD hacia IBM i (PUB400.COM)

## Visión General

**Objetivo:** Crear un programa RPG IV en IBM i (PUB400.COM / `CACORDERO1`) que lea
`QSYS2.ACTIVE_JOB_INFO` y genere un spool (reporte impreso) con los jobs activos
ordenados por CPU descendente. El código fuente vivirá en el repositorio GitHub
`cacorderob/Terraform` (carpeta `DemoIBM`) con control de versiones y un pipeline de
GitHub Actions que, ante cualquier cambio en `DemoIBM/`, copia los fuentes al IFS del
IBM i y ejecuta la compilación automáticamente.

**Alcance:**
- Estructura local `c:\Projects\DemoIBM\` con subcarpetas de documentación Inception.
- Código fuente RPG: `ACTJOBR.sqlrpgle` + CL de compilación: `COMPILDEMO.clle`.
- Repositorio GitHub `cacorderob/Terraform` → carpeta `DemoIBM/`.
- GitHub Actions workflow: push a `DemoIBM/` → SFTP al IFS → compilar en IBM i.
- Guía de configuración de secrets SSH en GitHub.

**No incluye:** cambios al proyecto `IBMi/` existente, modificar jobs existentes de Terraform.

---

## Sub-Tarea 1 — Inception: Estructura de documentación local

**Intent:** Crear la carpeta `DemoIBM/` en `c:\Projects` con las 3 subcarpetas Inception
documentando la intención, arquitectura y plan de ejecución del proyecto.

**Expected Outcomes:**
- `c:\Projects\DemoIBM\inception\01-intention\README.md` — Intención y requerimiento funcional.
- `c:\Projects\DemoIBM\inception\02-architecture\README.md` — Diagrama de arquitectura (texto/ASCII) y decisiones técnicas.
- `c:\Projects\DemoIBM\inception\03-operation\README.md` — Plan de ejecución y validación operacional.

**Todo List:**
1. Crear carpeta `DemoIBM/inception/01-intention/` y escribir `README.md` con el requerimiento funcional y contexto del caso de uso.
2. Crear carpeta `DemoIBM/inception/02-architecture/` y escribir `README.md` con diagrama ASCII del flujo: GitHub → GitHub Actions → IFS IBM i → CL Compilación → Objeto `ACTJOBR`.
3. Crear carpeta `DemoIBM/inception/03-operation/` y escribir `README.md` con checklist de validación, comandos de verificación en IBM i y plan de ejecución manual de contingencia.

**Relevant Context:**
- Convenciones del proyecto en [`IBMi/AGENTS.md`](../IBMi/AGENTS.md).
- Librería destino: `CACORDERO1` en PUB400.COM.

**Status:** `[x] done`

---

## Sub-Tarea 2 — Construcción: Código fuente RPG y CL

**Intent:** Escribir el programa RPG IV `ACTJOBR` que consulta `QSYS2.ACTIVE_JOB_INFO`
con las columnas clave y produce un spool formateado. Incluir el CL de compilación
`COMPILDEMO` que compila solo los fuentes de este demo.

**Expected Outcomes:**
- `DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle` — Programa RPG IV free-form que:
  - Abre un archivo de spool con `OVRPRTF`/cabeceras vía `QSYS2.ACTIVE_JOB_INFO`.
  - Itera con cursor SQL sobre `QSYS2.ACTIVE_JOB_INFO` seleccionando: `JOB_NAME`, `JOB_USER`, `JOB_TYPE`, `JOB_STATUS`, `CPU_TIME`, `ELAPSED_CPU_PERCENTAGE`, `FUNCTION_TYPE`, `FUNCTION` ordenados por `CPU_TIME DESC`.
  - Imprime cabecera y líneas de detalle usando archivo printer `ACTJOBP`.
- `DemoIBM/qddssrc/ACTJOBP.prtf` — DDS de archivo printer con el formato del reporte.
- `DemoIBM/qclsrc/COMPILDEMO.clle` — CL que compila: `ACTJOBP` (CRTPRTF) → `ACTJOBR` (CRTSQLRPGI).

**Todo List:**
1. Crear `DemoIBM/qddssrc/ACTJOBP.prtf` con DDS de printer file: cabecera con título/fecha, formato de detalle con los 8 campos clave.
2. Crear `DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle` siguiendo las convenciones de [`IBMi/AGENTS.md`](../IBMi/AGENTS.md): `**free`, `ctl-opt`, cursor SQL con `FETCH`, escritura al printer file, cierre correcto.
3. Crear `DemoIBM/qclsrc/COMPILDEMO.clle` con secuencia: `ADDLIBLE CACORDERO1`, `DLTOBJ` + `MONMSG` para limpiar objetos anteriores, `CRTPRTF` para `ACTJOBP`, `CRTSQLRPGI` para `ACTJOBR`.
4. Crear `DemoIBM/README.md` con instrucciones del demo.

**Relevant Context:**
- Patrón de cursor SQL: usar `DECLARE c1 CURSOR`, `OPEN c1`, `FETCH c1 INTO :vars`, loop con `SQLCODE = 0`, `CLOSE c1`.
- Printer file en RPG: `dcl-f ACTJOBP printer oflind(*in01)`.
- Convenciones de compilación: DDS primero, luego RPG — igual que [`IBMi/qclsrc/COMPILAR.clle`](../IBMi/qclsrc/COMPILAR.clle).
- Tabla fuente: `QSYS2.ACTIVE_JOB_INFO` (vista del sistema, no requiere librería de usuario).
- Columnas requeridas: `JOB_NAME`, `JOB_USER`, `JOB_TYPE`, `JOB_STATUS`, `CPU_TIME`, `ELAPSED_CPU_PERCENTAGE`, `FUNCTION_TYPE`, `FUNCTION`.

**Status:** `[x] done`

---

## Sub-Tarea 3 — Repositorio GitHub: Preparar estructura en `cacorderob/Terraform`

**Intent:** Estructurar la carpeta `DemoIBM/` dentro del repositorio GitHub
`cacorderob/Terraform` de manera que el workflow de CI/CD pueda detectar cambios y
sincronizar correctamente con el IBM i.

**Expected Outcomes:**
- El repositorio `cacorderob/Terraform` contiene la carpeta `DemoIBM/` con todos los fuentes de las sub-tareas 1 y 2.
- Archivo `.github/workflows/ibmi-deploy-demo.yml` creado en el repositorio con el pipeline de despliegue.
- La estructura local en `c:\Projects\DemoIBM\` replica exactamente lo que estará en GitHub.

**Todo List:**
1. Verificar que la carpeta `c:\Projects\Terraform` tiene el remote apuntando a `cacorderob/Terraform` (leer `.git/config`).
2. Copiar/enlazar la estructura `DemoIBM/` al interior de `c:\Projects\Terraform\DemoIBM\` para que quede bajo el control de versiones del repositorio Terraform.
3. Crear el archivo `c:\Projects\Terraform\.github\workflows\ibmi-deploy-demo.yml` con el pipeline descrito en Sub-Tarea 4.
4. Documentar en `DemoIBM/inception/03-operation/README.md` el proceso de commit y push para activar el pipeline.

**Relevant Context:**
- Repositorio Terraform ya tiene `.github/workflows/` con `terraform-ci.yml` como referencia de estructura de workflows.
- El workflow nuevo debe filtrar `paths: ["DemoIBM/**"]` para no interferir con los workflows de Terraform existentes.

**Status:** `[x] done`

---

## Sub-Tarea 4 — CI/CD: GitHub Actions workflow de despliegue a IBM i

**Intent:** Crear el workflow de GitHub Actions que, cuando se haga push a `main` con
cambios en `DemoIBM/`, copie los fuentes al IFS de PUB400.COM vía SFTP/SSH y ejecute
el CL de compilación `COMPILDEMO` remotamente.

**Expected Outcomes:**
- Workflow `ibmi-deploy-demo.yml` que:
  1. Se dispara en `push` a `main` con `paths: DemoIBM/**`.
  2. Copia los 3 directorios de fuentes (`qrpglesrc/`, `qddssrc/`, `qclsrc/`) al IFS: `/home/CACORDERO1/DemoIBM/`.
  3. Ejecuta via SSH: `SBMJOB CMD(CALL PGM(CACORDERO1/COMPILDEMO)) ...` o equivalente CL.
  4. Reporta resultado en el summary del workflow.
- Secretos requeridos documentados: `IBMI_HOST`, `IBMI_USER`, `IBMI_SSH_PRIVATE_KEY`.

**Todo List:**
1. Crear `c:\Projects\Terraform\.github\workflows\ibmi-deploy-demo.yml` con:
   - Trigger: `push` a `main`, `paths: ["DemoIBM/**"]` + `workflow_dispatch`.
   - Job `deploy`: checkout → setup SSH key desde secret → `rsync` o `sftp` batch para copiar fuentes al IFS → SSH para ejecutar CL de compilación.
2. Agregar comentario en el workflow documentando los 3 secrets necesarios y cómo configurarlos.
3. Actualizar `DemoIBM/inception/03-operation/README.md` con instrucciones paso a paso para configurar los secrets en GitHub (`Settings → Secrets and variables → Actions`).

**Relevant Context:**
- Usar `appleboy/ssh-action` (acción community popular para SSH a IBM i/Linux).
- El IFS path de destino: `/home/CACORDERO1/DemoIBM/{qrpglesrc,qddssrc,qclsrc}/`.
- El CL `COMPILDEMO` copiará fuentes del IFS a la librería usando `CPYFRMSTMF` antes de compilar, o alternativamente el workflow llama `CPYFRMSTMF` directamente via SSH.
- Secrets requeridos:
  - `IBMI_HOST` → `pub400.com`
  - `IBMI_USER` → `CACORDERO1`
  - `IBMI_SSH_PRIVATE_KEY` → clave privada RSA/ED25519
- Guía para generar el par de claves: `ssh-keygen -t ed25519 -C "github-actions-demo"`.

**Status:** `[x] done`

---

## Sub-Tarea 5 — Operación: Validación en PUB400.COM

**Intent:** Validar que el programa compilado existe en `CACORDERO1`, se puede ejecutar
con `CALL PGM(CACORDERO1/ACTJOBR)` y genera el spool correctamente, y que el pipeline
end-to-end funciona ante un cambio en el repositorio.

**Expected Outcomes:**
- El programa `ACTJOBR` existe en `CACORDERO1` (`WRKOBJ CACORDERO1/ACTJOBR`).
- `CALL PGM(CACORDERO1/ACTJOBR)` genera un spool visible en `WRKSPLF`.
- El spool contiene las 8 columnas requeridas con datos reales de jobs activos.
- Un cambio en el código → commit → push → el workflow se ejecuta → objeto se actualiza en IBM i.

**Todo List:**
1. Documentar en `DemoIBM/inception/03-operation/README.md` los comandos de verificación:
   - `WRKOBJ OBJ(CACORDERO1/ACTJOBR) OBJTYPE(*PGM)` — verificar existencia.
   - `CALL PGM(CACORDERO1/ACTJOBR)` — ejecutar el reporte.
   - `WRKSPLF` — ver el spool generado.
   - `WRKJOBLOG` — revisar si hubo errores durante la ejecución.
2. Documentar el test de ciclo completo: modificar un comentario en `ACTJOBR.sqlrpgle` → commit → push → observar GitHub Actions → verificar objeto actualizado.
3. Agregar sección de troubleshooting: qué hacer si SSH falla, si la compilación falla, si el spool no aparece.

**Relevant Context:**
- PUB400.COM usa autenticación por clave pública SSH en el puerto 22.
- El usuario es `CACORDERO1` (mismo nombre que la librería).
- Los spools en IBM i se ven con `WRKSPLF USER(CACORDERO1)`.
- Si `CRTSQLRPGI` falla, revisar `WRKMSGQ CACORDERO1` o el joblog del job de compilación.

**Status:** `[x] done`

---

## Diagrama de Flujo (referencia)

```
Developer
   │
   ▼ git push → main (DemoIBM/**)
GitHub Repository: cacorderob/Terraform
   │
   ▼ trigger: ibmi-deploy-demo.yml
GitHub Actions Runner
   │
   ├─ sftp/rsync ──────────────────────────────────────▶ PUB400.COM IFS
   │                                                      /home/CACORDERO1/DemoIBM/
   │                                                        qrpglesrc/ACTJOBR.sqlrpgle
   │                                                        qddssrc/ACTJOBP.prtf
   │                                                        qclsrc/COMPILDEMO.clle
   │
   └─ ssh cmd: CALL CACORDERO1/COMPILDEMO ─────────────▶ IBM i CACORDERO1
                                                           CRTPRTF  → ACTJOBP (*FILE)
                                                           CRTSQLRPGI → ACTJOBR (*PGM)

End User
   │
   ▼ CALL PGM(CACORDERO1/ACTJOBR)
   └─ Genera spool ACTJOBR en WRKSPLF
      Columnas: JOB_NAME, JOB_USER, JOB_TYPE, JOB_STATUS,
                CPU_TIME, ELAPSED_CPU_PCT, FUNCTION_TYPE, FUNCTION
      Orden: CPU_TIME DESC
```

---

## Secrets de GitHub requeridos

| Secret | Valor | Dónde configurar |
|---|---|---|
| `IBMI_HOST` | `pub400.com` | GitHub → Settings → Secrets → Actions |
| `IBMI_USER` | `CACORDERO1` | GitHub → Settings → Secrets → Actions |
| `IBMI_SSH_PRIVATE_KEY` | Clave privada ed25519 | GitHub → Settings → Secrets → Actions |

**Generar el par de claves:**
```bash
ssh-keygen -t ed25519 -C "github-actions-demo" -f ~/.ssh/ibmi_github_demo
# Copiar ~/.ssh/ibmi_github_demo.pub al authorized_keys de PUB400.COM
# Pegar contenido de ~/.ssh/ibmi_github_demo como secret IBMI_SSH_PRIVATE_KEY
```
