# DemoIBM — Reporte de Jobs Activos en IBM i

Demo de RPG IV que consulta `QSYS2.ACTIVE_JOB_INFO` y genera un spool con los jobs activos del sistema IBM i ordenados por CPU descendente.

## Descripción

El programa `ACTJOBR` abre un cursor SQL sobre la vista del sistema `QSYS2.ACTIVE_JOB_INFO`, imprime una cabecera con fecha del día y escribe una línea de detalle por cada job activo. El reporte queda disponible en el spool del usuario (`WRKSPLF`).

**Columnas del reporte:**

| Columna       | Fuente SQL                  | Ancho |
|---------------|-----------------------------|-------|
| JOB NAME      | `JOB_NAME`                  | 28    |
| USER          | `JOB_USER`                  | 10    |
| TP            | `JOB_TYPE`                  | 2     |
| STATUS        | `JOB_STATUS`                | 10    |
| CPU TIME      | `CPU_TIME`                  | 12    |
| CPU %         | `ELAPSED_CPU_PERCENTAGE`    | 9     |
| FT            | `FUNCTION_TYPE`             | 2     |
| FUNCTION      | `FUNCTION`                  | 10    |

## Estructura de archivos

| Archivo                              | Tipo          | Descripción                                      |
|--------------------------------------|---------------|--------------------------------------------------|
| `qddssrc/ACTJOBP.prtf`              | DDS PRTF      | Formato del reporte: cabecera, subtítulos, detalle |
| `qrpglesrc/ACTJOBR.sqlrpgle`        | SQL RPG IV    | Programa principal — cursor + spool              |
| `qclsrc/COMPILDEMO.clle`            | CL Program    | Copia fuentes del IFS y compila ACTJOBP → ACTJOBR |
| `inception/01-intention/README.md`  | Documentación | Intención y requerimiento funcional              |
| `inception/02-architecture/README.md` | Documentación | Diagrama de arquitectura y decisiones técnicas  |
| `inception/03-operation/README.md`  | Documentación | Plan operacional y validación                    |

## Compilación manual (primera vez)

Ejecutar en una sesión 5250 como `CACORDERO1`:

```cl
/* 1. Crear el CL de compilación */
CRTCLPGM PGM(CACORDERO1/COMPILDEMO) +
          SRCFILE(CACORDERO1/QCLSRC) +
          SRCMBR(COMPILDEMO) +
          AUT(*EXCLUDE)

/* 2. Copiar fuentes del IFS (si aún no están en el source file) */
/*    El propio COMPILDEMO ya hace esto automáticamente           */

/* 3. Ejecutar el CL de compilación */
CALL PGM(CACORDERO1/COMPILDEMO)
```

> **Nota:** En compilaciones subsiguientes basta con ejecutar `CALL PGM(CACORDERO1/COMPILDEMO)` — el CL limpia los objetos anteriores y recompila en el orden correcto (PRTF primero, RPG después).

## Ejecución

```cl
CALL PGM(CACORDERO1/ACTJOBR)
```

Para ver el spool generado:

```cl
WRKSPLF USER(CACORDERO1)
```

## CI/CD automático

El pipeline de GitHub Actions (Sub-Tarea 3 y 4 del plan) detecta cambios en `DemoIBM/**`, copia los fuentes al IFS de PUB400.COM y ejecuta `COMPILDEMO` automáticamente.

Ver detalles en:
- [`inception/02-architecture/README.md`](inception/02-architecture/README.md) — diagrama del flujo
- [`inception/03-operation/README.md`](inception/03-operation/README.md) — configuración de secrets y validación
- [Plan completo](demo-ibmi-active-jobs-plan.md)
