whenever sqlerror exit failure rollback
set define on
set verify off
set serveroutput on
alter session set container = &&oracle_pdb;

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM DBA_TABLES
   WHERE OWNER = UPPER('&&app_schema')
     AND TABLE_NAME = 'VECTOR_RAG_DOCUMENTS';

  IF l_count = 1 THEN
    EXECUTE IMMEDIATE
      'DROP TABLE &&app_schema..VECTOR_RAG_DOCUMENTS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('Removed VECTOR_RAG_DOCUMENTS and its indexes.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Example table is already absent; nothing removed.');
  END IF;
END;
/

PROMPT VECTOR_RAG_UNINSTALL_OK (embedding model retained)
EXIT SUCCESS
