**free
// =====================================================================
// PROGRAMA : ACTJOBR
// TIPO     : SQL RPG IV Free-Form (*PGM)
// LIBRERIA : CACORDERO1
// DESC     : Reporte de Jobs Activos — lee QSYS2.ACTIVE_JOB_INFO
//            y genera spool con jobs ordenados por CPU_TIME DESC
// AUTOR    : CACORDERO
// =====================================================================
ctl-opt dftactgrp(*no) actgrp(*caller)
        datfmt(*iso) timfmt(*iso)
        option(*srcstmt : *nodebugio)
        main(ACTJOBR);

// ---------------------------------------------------------------------
// Declaracion de archivo printer (oflind = indicador de overflow)
// ---------------------------------------------------------------------
dcl-f ACTJOBP printer oflind(*in01);

// =====================================================================
// Programa principal
// =====================================================================
dcl-proc ACTJOBR;

  // --- Variables locales (prefijo w) ----------------------------------
  dcl-s wJobNam  char(28);         // JOB_NAME
  dcl-s wJobUsr  char(10);         // JOB_USER
  dcl-s wJobTyp  char(2);          // JOB_TYPE
  dcl-s wJobSts  char(10);         // JOB_STATUS
  dcl-s wCpuTim  packed(12:0);     // CPU_TIME
  dcl-s wCpuPct  packed(9:2);      // ELAPSED_CPU_PERCENTAGE
  dcl-s wFncTyp  char(2);          // FUNCTION_TYPE
  dcl-s wFnc     char(10);         // FUNCTION

  // --- Declaracion del cursor SQL ------------------------------------
  exec sql
    DECLARE C_ACTJOB CURSOR FOR
      SELECT JOB_NAME,
             JOB_USER,
             JOB_TYPE,
             JOB_STATUS,
             CPU_TIME,
             ELAPSED_CPU_PERCENTAGE,
             COALESCE(FUNCTION_TYPE, '  '),
             COALESCE(FUNCTION, '          ')
        FROM QSYS2.ACTIVE_JOB_INFO
       ORDER BY CPU_TIME DESC;

  // --- Abrir cursor ---------------------------------------------------
  exec sql OPEN C_ACTJOB;

  if SQLCODE <> 0;
    // Error al abrir — escribir cabecera y mensaje en spool
    RFECHA = %date();
    write CABECERA;
    write SUBTIT;
    RJNAME = 'ERROR: No se pudo abrir cursor.';
    RJUSER = *blanks;
    RJTYPE = *blanks;
    RJSTAT = *blanks;
    RCPUT  = 0;
    RCPUPC = 0;
    RFTYPE = *blanks;
    RFUNC  = *blanks;
    write DETALLE;
    return;
  endif;

  // --- Escribir cabecera y subtitulos --------------------------------
  RFECHA = %date();
  write CABECERA;
  write SUBTIT;

  // --- Loop de fetch --------------------------------------------------
  exec sql FETCH C_ACTJOB
    INTO :wJobNam, :wJobUsr, :wJobTyp, :wJobSts,
         :wCpuTim, :wCpuPct, :wFncTyp, :wFnc;

  dow SQLCODE = 0;

    // Si hay overflow de pagina, imprimir cabecera y subtitulos antes del detalle
    if *in01;
      RFECHA = %date();
      write CABECERA;
      write SUBTIT;
      *in01 = *off;
    endif;

    // Mover variables a campos del printer file
    RJNAME = wJobNam;
    RJUSER = wJobUsr;
    RJTYPE = wJobTyp;
    RJSTAT = wJobSts;
    RCPUT  = wCpuTim;
    RCPUPC = wCpuPct;
    RFTYPE = wFncTyp;
    RFUNC  = wFnc;

    // Escribir linea de detalle
    write DETALLE;

    exec sql FETCH C_ACTJOB
      INTO :wJobNam, :wJobUsr, :wJobTyp, :wJobSts,
           :wCpuTim, :wCpuPct, :wFncTyp, :wFnc;

  enddo;

  // --- Cerrar cursor -------------------------------------------------
  exec sql CLOSE C_ACTJOB;

end-proc ACTJOBR;
