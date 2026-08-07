# Plan de Ejecución y Validación Operacional

## Prerrequisitos

### 1. Acceso a PUB400.COM

- Cuenta activa en [PUB400.COM](https://pub400.com) con usuario `CACORDERO1`.
- Librería `CACORDERO1` existente en el sistema.
- Autenticación configurada: **clave pública SSH** (ver sección siguiente).

### 2. Configuración del par de claves SSH (ed25519)

Ejecutar en la máquina local (o en el runner de GitHub Actions no es necesario — el secret ya la contiene):

```bash
# Generar el par de claves
ssh-keygen -t ed25519 -C "github-actions-demo" -f ~/.ssh/ibmi_github_demo

# Resultado:
#   ~/.ssh/ibmi_github_demo       ← clave PRIVADA (va al secret de GitHub)
#   ~/.ssh/ibmi_github_demo.pub   ← clave PÚBLICA (va al authorized_keys de IBM i)
```

**Registrar la clave pública en PUB400.COM:**

```bash
# Opción A: ssh-copy-id
ssh-copy-id -i ~/.ssh/ibmi_github_demo.pub CACORDERO1@pub400.com

# Opción B: manual — conectarse y agregar la línea al archivo
ssh CACORDERO1@pub400.com
> mkdir -p ~/.ssh && chmod 700 ~/.ssh
> echo "$(cat ~/.ssh/ibmi_github_demo.pub)" >> ~/.ssh/authorized_keys
> chmod 600 ~/.ssh/authorized_keys
```

**Verificar la conexión:**

```bash
ssh -i ~/.ssh/ibmi_github_demo CACORDERO1@pub400.com "system 'WRKUSRPRF USRPRF(CACORDERO1)'"
```

### 3. Secrets de GitHub

En el repositorio `cacorderob/Terraform`:

`Settings → Secrets and variables → Actions → New repository secret`

| Secret                  | Valor                                          |
|-------------------------|------------------------------------------------|
| `IBMI_HOST`             | `pub400.com`                                   |
| `IBMI_USER`             | `CACORDERO1`                                   |
| `IBMI_SSH_PRIVATE_KEY`  | Contenido completo de `~/.ssh/ibmi_github_demo` |

> **Importante:** Pegar la clave privada **incluyendo** las líneas
> `-----BEGIN OPENSSH PRIVATE KEY-----` y `-----END OPENSSH PRIVATE KEY-----`.

---

## Primera Ejecución Manual (antes del CI/CD)

Antes de depender del pipeline automático, se recomienda compilar manualmente para
verificar que el entorno está correcto.

### Paso 1 — Conectarse a PUB400.COM

```bash
ssh -i ~/.ssh/ibmi_github_demo CACORDERO1@pub400.com
```

### Paso 2 — Crear directorios en el IFS

```
MKDIR DIR('/home/CACORDERO1/DemoIBM')
MKDIR DIR('/home/CACORDERO1/DemoIBM/qrpglesrc')
MKDIR DIR('/home/CACORDERO1/DemoIBM/qddssrc')
MKDIR DIR('/home/CACORDERO1/DemoIBM/qclsrc')
```

O desde bash PASE:

```bash
mkdir -p /home/CACORDERO1/DemoIBM/{qrpglesrc,qddssrc,qclsrc}
```

### Paso 3 — Copiar fuentes al IFS (desde la máquina local)

```bash
sftp -i ~/.ssh/ibmi_github_demo CACORDERO1@pub400.com <<EOF
put DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle  /home/CACORDERO1/DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle
put DemoIBM/qddssrc/ACTJOBP.prtf        /home/CACORDERO1/DemoIBM/qddssrc/ACTJOBP.prtf
put DemoIBM/qclsrc/COMPILDEMO.clle      /home/CACORDERO1/DemoIBM/qclsrc/COMPILDEMO.clle
EOF
```

### Paso 4 — Verificar que los archivos llegaron

```bash
ssh -i ~/.ssh/ibmi_github_demo CACORDERO1@pub400.com \
  "ls -la /home/CACORDERO1/DemoIBM/qrpglesrc/ /home/CACORDERO1/DemoIBM/qddssrc/ /home/CACORDERO1/DemoIBM/qclsrc/"
```

### Paso 5 — Ejecutar compilación remota

```bash
ssh -i ~/.ssh/ibmi_github_demo CACORDERO1@pub400.com \
  "system 'CALL PGM(CACORDERO1/COMPILDEMO)'"
```

---

## Comandos de Verificación en IBM i

### Verificar existencia de objetos

```
WRKOBJ OBJ(CACORDERO1/ACTJOBR)  OBJTYPE(*PGM)
WRKOBJ OBJ(CACORDERO1/ACTJOBP)  OBJTYPE(*FILE)
```

### Ejecutar el reporte

```
CALL PGM(CACORDERO1/ACTJOBR)
```

### Ver el spool generado

```
WRKSPLF USER(CACORDERO1)
```

Buscar la entrada con nombre `ACTJOBR` o `ACTJOBP`. Presionar **5** para ver el contenido.

### Revisar el job log por errores

```
WRKJOBLOG
```

O para el job actual:

```
DSPJOBLOG
```

### Ver mensajes del usuario

```
WRKMSGQ MSGQ(CACORDERO1)
```

---

## Ciclo de Actualización vía GitHub (CI/CD)

```
1. Modificar fuente local
   └─ p.ej. editar DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle

2. Commit y push
   git add DemoIBM/
   git commit -m "feat: mejora en formato de reporte ACTJOBR"
   git push origin main

3. Observar GitHub Actions
   └─ https://github.com/cacorderob/Terraform/actions
   └─ Workflow: "IBM i Deploy Demo"
   └─ Verificar que los pasos SFTP y SSH terminan en verde ✓

4. Verificar en IBM i
   WRKOBJ OBJ(CACORDERO1/ACTJOBR) OBJTYPE(*PGM)
   └─ Revisar la fecha/hora de creación del objeto — debe ser reciente

5. Ejecutar y validar
   CALL PGM(CACORDERO1/ACTJOBR)
   WRKSPLF USER(CACORDERO1)
   └─ El nuevo spool debe reflejar los cambios realizados
```

---

## Troubleshooting

### SSH falla al conectar

**Síntoma:** `Permission denied (publickey)` o `Connection refused`

| Causa probable                     | Solución                                                    |
|------------------------------------|-------------------------------------------------------------|
| Clave pública no registrada en IBM i | Agregar `~/.ssh/ibmi_github_demo.pub` al `authorized_keys` de `CACORDERO1@pub400.com` |
| Secret `IBMI_SSH_PRIVATE_KEY` incorrecto | Verificar que incluye el bloque completo `BEGIN/END OPENSSH PRIVATE KEY` |
| Puerto 22 bloqueado                | Confirmar con `telnet pub400.com 22`; PUB400 usa puerto 22 estándar |
| Permisos del directorio `.ssh`     | Ejecutar: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys` en IBM i |

### Compilación falla (`CRTSQLRPGI` o `CRTPRTF`)

**Síntoma:** El workflow SSH termina con código de error o el objeto no aparece en `WRKOBJ`

| Causa probable                     | Solución                                                    |
|------------------------------------|-------------------------------------------------------------|
| Fuente no llegó al IFS             | Verificar con `ls /home/CACORDERO1/DemoIBM/qrpglesrc/`     |
| `CPYFRMSTMF` falla (encoding)      | Revisar que el archivo en IFS usa CCSID 37 (ASCII→EBCDIC); especificar `TOCCSID(37)` |
| Error de sintaxis en el fuente RPG | Revisar `WRKMSGQ CACORDERO1` o el joblog del job de compilación: `WRKSBMJOB` |
| Librería `CACORDERO1` no en LIBL  | Verificar que `COMPILDEMO.clle` incluye `ADDLIBLE CACORDERO1` |
| Objeto anterior bloqueado          | `DLTOBJ OBJ(CACORDERO1/ACTJOBR) OBJTYPE(*PGM)` + `MONMSG` |

### Spool no aparece en `WRKSPLF`

**Síntoma:** `CALL PGM(CACORDERO1/ACTJOBR)` termina sin error pero no hay spool nuevo

| Causa probable                     | Solución                                                    |
|------------------------------------|-------------------------------------------------------------|
| Spool en cola diferente            | `WRKSPLF USER(*ALL)` para ver todos los usuarios           |
| `QSYS2.ACTIVE_JOB_INFO` sin datos  | La vista siempre retorna filas; verificar con `STRSQL` → `SELECT * FROM QSYS2.ACTIVE_JOB_INFO FETCH FIRST 5 ROWS ONLY` |
| Printer file `ACTJOBP` no existe   | `WRKOBJ OBJ(CACORDERO1/ACTJOBP) OBJTYPE(*FILE)` — si no existe, recompilar con `COMPILDEMO` |
| Error en ejecución sin MONMSG      | `DSPJOBLOG` para ver el error específico del job           |

---

*Documento operacional — Sub-Tarea 1 del plan `demo-ibmi-active-jobs-plan.md`*
