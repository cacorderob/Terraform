# Arquitectura y Decisiones Técnicas

## Diagrama de Flujo — CI/CD End-to-End

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DEVELOPER (local)                                                          │
│                                                                             │
│   Edita fuente:                                                             │
│     DemoIBM/qrpglesrc/ACTJOBR.sqlrpgle                                     │
│     DemoIBM/qddssrc/ACTJOBP.prtf                                           │
│     DemoIBM/qclsrc/COMPILDEMO.clle                                         │
│                                                                             │
│   git commit && git push → main                                             │
└───────────────────────┬─────────────────────────────────────────────────────┘
                        │  push event (paths: DemoIBM/**)
                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GITHUB REPOSITORY: cacorderob/Terraform                                    │
│                                                                             │
│  Trigger: .github/workflows/ibmi-deploy-demo.yml                           │
└───────────────────────┬─────────────────────────────────────────────────────┘
                        │  GitHub Actions Runner
                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GITHUB ACTIONS RUNNER                                                      │
│                                                                             │
│  1. actions/checkout@v4                                                     │
│  2. Cargar IBMI_SSH_PRIVATE_KEY desde Secrets                               │
│  3. SFTP → copia fuentes al IFS de PUB400.COM                              │
│  4. SSH → ejecuta CL de compilación remota                                 │
└──────────────┬──────────────────────────────┬───────────────────────────────┘
               │ SFTP                          │ SSH
               ▼                              ▼
┌──────────────────────────┐    ┌─────────────────────────────────────────────┐
│  PUB400.COM — IFS        │    │  IBM i — CACORDERO1 (QSYS)                  │
│                          │    │                                             │
│  /home/CACORDERO1/       │    │  CALL PGM(CACORDERO1/COMPILDEMO)            │
│    DemoIBM/              │    │    │                                        │
│      qrpglesrc/          │    │    ├─ CPYFRMSTMF → QRPGLESRC/ACTJOBR       │
│        ACTJOBR.sqlrpgle  │    │    ├─ CPYFRMSTMF → QDDSSRC/ACTJOBP         │
│      qddssrc/            │    │    ├─ CPYFRMSTMF → QCLSRC/COMPILDEMO        │
│        ACTJOBP.prtf      │    │    ├─ CRTPRTF  → CACORDERO1/ACTJOBP (*FILE)│
│      qclsrc/             │    │    └─ CRTSQLRPGI → CACORDERO1/ACTJOBR(*PGM)│
│        COMPILDEMO.clle   │    └─────────────────────────────────────────────┘
└──────────────────────────┘
                                             │
                                             │  (compilación exitosa)
                                             ▼
                              ┌──────────────────────────────┐
                              │  USUARIO FINAL — IBM i       │
                              │                              │
                              │  CALL PGM(CACORDERO1/ACTJOBR)│
                              │          │                   │
                              │          ▼                   │
                              │  Genera spool ACTJOBR        │
                              │  visible en WRKSPLF          │
                              │                              │
                              │  Columnas del reporte:       │
                              │   JOB_NAME                   │
                              │   JOB_USER                   │
                              │   JOB_TYPE                   │
                              │   JOB_STATUS                 │
                              │   CPU_TIME                   │
                              │   ELAPSED_CPU_PERCENTAGE     │
                              │   FUNCTION_TYPE              │
                              │   FUNCTION                   │
                              │  Orden: CPU_TIME DESC        │
                              └──────────────────────────────┘
```

---

## Decisiones de Diseño

### ¿Por qué RPG IV free-form (`**free`)?

- Sintaxis moderna sin limitaciones de columnas (elimina columnas 6-80).
- Soporte nativo de `EXEC SQL` (SQL embebido) con `CRTSQLRPGI`.
- Alineado con las convenciones del proyecto existente en `IBMi/AGENTS.md`.
- Más legible y mantenible que OPM o RPG III para desarrolladores nuevos en la plataforma.

### ¿Por qué cursor SQL sobre `QSYS2.ACTIVE_JOB_INFO`?

- `QSYS2.ACTIVE_JOB_INFO` es una **tabla de función de tabla (UDTF)** del sistema que
  retorna los jobs activos en tiempo real sin requerir permisos especiales adicionales.
- El patrón `DECLARE → OPEN → FETCH → CLOSE` permite iterar fila a fila con control
  total del flujo en RPG, evitando cursores implícitos o estructuras de host array.
- Permite `ORDER BY CPU_TIME DESC` directamente en SQL, sin ordenamiento manual en RPG.

### ¿Por qué printer file DDS (`ACTJOBP`) para el spool?

- El **printer file DDS** es el mecanismo estándar de IBM i para generar spools con formato.
- Permite definir cabeceras, formatos de detalle y control de overflow (`INDARA`, `OFLIND`)
  de forma declarativa, sin hardcodear posiciones en el programa RPG.
- El spool resultante es archivable y consultable con `WRKSPLF`, integrado con el sistema
  de colas de salida de IBM i.
- Alternativas (QSYS2/QPRTJOB, IFS stream file) son más complejas para un demo ilustrativo.

---

## Stack Tecnológico

| Capa                  | Tecnología                          | Versión / Notas              |
|-----------------------|-------------------------------------|------------------------------|
| Lenguaje principal    | RPG IV free-form                    | `**free`, `ctl-opt`          |
| Acceso a datos        | SQL embebido (`EXEC SQL`)           | Cursor `DECLARE / OPEN / FETCH / CLOSE` |
| Salida del reporte    | DDS Printer File                    | `CRTPRTF`                    |
| Script de compilación | CL (Control Language)               | `COMPILDEMO.clle`            |
| Fuente de datos       | `QSYS2.ACTIVE_JOB_INFO`             | Vista de sistema, sin librería de usuario |
| Control de versiones  | Git / GitHub                        | Repo `cacorderob/Terraform`  |
| CI/CD                 | GitHub Actions                      | `ibmi-deploy-demo.yml`       |
| Transferencia         | SFTP                                | GitHub Runner → IFS IBM i    |
| Ejecución remota      | SSH                                 | `appleboy/ssh-action`        |
| Servidor IBM i        | PUB400.COM                          | Puerto 22, auth clave pública |

---

## Estructura de Archivos del Proyecto

```
DemoIBM/
│
├── README.md                          ← Instrucciones generales del demo
│
├── qrpglesrc/
│   └── ACTJOBR.sqlrpgle               ← Programa RPG IV con SQL embebido
│                                          Lógica: cursor sobre ACTIVE_JOB_INFO
│                                          Salida: escritura a ACTJOBP (printer)
│
├── qddssrc/
│   └── ACTJOBP.prtf                   ← DDS del archivo printer
│                                          Formato cabecera + detalle (8 campos)
│
├── qclsrc/
│   └── COMPILDEMO.clle                ← CL de compilación
│                                          Secuencia: CRTPRTF → CRTSQLRPGI
│
└── inception/
    ├── 01-intention/
    │   └── README.md                  ← Intención y requerimiento funcional
    ├── 02-architecture/
    │   └── README.md                  ← Este documento
    └── 03-operation/
        └── README.md                  ← Plan de ejecución y validación
```

---

*Documento de arquitectura — Sub-Tarea 1 del plan `demo-ibmi-active-jobs-plan.md`*
