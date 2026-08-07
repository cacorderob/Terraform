# Intención y Requerimiento Funcional

## Nombre del Caso de Uso

**Reporte de Jobs Activos — IBM i**

---

## Descripción del Requerimiento

Crear un programa RPG IV en IBM i que consulte la vista de sistema `QSYS2.ACTIVE_JOB_INFO`
y genere un **spool reporte** (archivo de impresión) con los jobs activos en el momento de
la ejecución, ordenados por consumo de CPU descendente.

El programa deberá:

1. Abrir un cursor SQL sobre `QSYS2.ACTIVE_JOB_INFO`.
2. Recuperar las columnas requeridas mediante `FETCH` iterativo.
3. Escribir una cabecera y líneas de detalle en un archivo printer DDS (`ACTJOBP`).
4. Cerrar el cursor y terminar normalmente.

---

## Columnas Requeridas en el Reporte

| Columna                  | Descripción                                 |
|--------------------------|---------------------------------------------|
| `JOB_NAME`               | Nombre del job                              |
| `JOB_USER`               | Usuario propietario del job                 |
| `JOB_TYPE`               | Tipo de job (BCI, INT, etc.)                |
| `JOB_STATUS`             | Estado actual (ACTIVE, MSGW, etc.)          |
| `CPU_TIME`               | Tiempo de CPU acumulado (ms)                |
| `ELAPSED_CPU_PERCENTAGE` | Porcentaje de CPU en el período transcurrido |
| `FUNCTION_TYPE`          | Tipo de función en ejecución                |
| `FUNCTION`               | Nombre de la función en ejecución           |

**Ordenamiento:** `CPU_TIME DESC`

---

## Objetivo de Negocio

Proporcionar **visibilidad en tiempo real de la carga del sistema IBM i** a los
administradores de la plataforma. Con este reporte se puede:

- Identificar jobs que consumen excesivamente CPU.
- Detectar jobs bloqueados en espera de mensaje (`MSGW`).
- Hacer diagnóstico de performance sin requerir herramientas adicionales.
- Generar un historial de spools para comparación en el tiempo.

---

## Contexto Técnico

| Elemento              | Valor                                                  |
|-----------------------|--------------------------------------------------------|
| **Servidor**          | PUB400.COM (IBM i público compartido)                  |
| **Librería de usuario** | `CACORDERO1`                                         |
| **Lenguaje principal**| RPG IV free-form (`**free`)                            |
| **Acceso a datos**    | SQL embebido (`EXEC SQL`) sobre `QSYS2.ACTIVE_JOB_INFO`|
| **Salida**            | Spool generado por archivo printer DDS (`ACTJOBP`)     |
| **CL de compilación** | `COMPILDEMO` en librería `CACORDERO1`                  |
| **Programa RPG**      | `ACTJOBR` en librería `CACORDERO1`                     |
| **Archivo printer**   | `ACTJOBP` en librería `CACORDERO1`                     |
| **IFS destino**       | `/home/CACORDERO1/DemoIBM/`                            |

---

## Control de Versiones

El código fuente de este proyecto vive en GitHub bajo el repositorio:

**`cacorderob/Terraform`** — carpeta `DemoIBM/`

Estructura de carpetas de código fuente:

```
DemoIBM/
├── qrpglesrc/
│   └── ACTJOBR.sqlrpgle      ← Programa RPG IV con SQL embebido
├── qddssrc/
│   └── ACTJOBP.prtf          ← DDS del archivo printer
├── qclsrc/
│   └── COMPILDEMO.clle       ← CL de compilación
└── inception/
    ├── 01-intention/README.md
    ├── 02-architecture/README.md
    └── 03-operation/README.md
```

Cualquier cambio en la carpeta `DemoIBM/` activará automáticamente el pipeline de
GitHub Actions `ibmi-deploy-demo.yml`, que sincroniza los fuentes al IFS de IBM i y
ejecuta la compilación remota.

---

*Documento de intención — Sub-Tarea 1 del plan `demo-ibmi-active-jobs-plan.md`*
