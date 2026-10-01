whenever sqlerror exit failure rollback
set define on
set verify off
set serveroutput on

alter session set container = &&oracle_pdb;

DECLARE
  l_schema_name       VARCHAR2(128) := UPPER('&&app_schema');
  l_directory_name    VARCHAR2(128) := UPPER('&&model_directory_name');
  l_directory_path    VARCHAR2(4000) := '&&model_directory_path';
  l_schema_sql        VARCHAR2(261);
  l_directory_sql     VARCHAR2(261);
  l_existing_privilege PLS_INTEGER := 0;
  l_temporary_privilege BOOLEAN := FALSE;
  l_directory_created BOOLEAN := FALSE;
  l_model_count       PLS_INTEGER := 0;

  PROCEDURE clean_temporary_directory IS
  BEGIN
    IF l_directory_created THEN
      BEGIN
        EXECUTE IMMEDIATE 'REVOKE READ, WRITE ON DIRECTORY ' || l_directory_sql ||
                          ' FROM ' || l_schema_sql;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
      BEGIN
        EXECUTE IMMEDIATE 'DROP DIRECTORY ' || l_directory_sql;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
      l_directory_created := FALSE;
    END IF;
  END;
BEGIN
  l_schema_sql := DBMS_ASSERT.ENQUOTE_NAME(l_schema_name, FALSE);
  l_directory_sql := DBMS_ASSERT.ENQUOTE_NAME(l_directory_name, FALSE);

  SELECT COUNT(*)
    INTO l_model_count
    FROM DBA_MINING_MODELS
   WHERE OWNER = l_schema_name
     AND MODEL_NAME = 'VECTOR_RAG_MINILM';
  IF l_model_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001,
      'VECTOR_RAG_MINILM already exists; refusing to overwrite it');
  END IF;

  SELECT COUNT(*)
    INTO l_model_count
    FROM DBA_DIRECTORIES
   WHERE DIRECTORY_NAME = l_directory_name;
  IF l_model_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'Temporary model directory object already exists; refusing to replace it');
  END IF;

  SELECT COUNT(*)
    INTO l_existing_privilege
    FROM DBA_SYS_PRIVS
   WHERE GRANTEE = l_schema_name
     AND PRIVILEGE = 'CREATE MINING MODEL';

  EXECUTE IMMEDIATE 'CREATE DIRECTORY ' || l_directory_sql || ' AS ' ||
                    DBMS_ASSERT.ENQUOTE_LITERAL(l_directory_path);
  l_directory_created := TRUE;
  EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY ' || l_directory_sql ||
                    ' TO ' || l_schema_sql;

  IF l_existing_privilege = 0 THEN
    EXECUTE IMMEDIATE 'GRANT CREATE MINING MODEL TO ' || l_schema_sql;
    l_temporary_privilege := TRUE;
  END IF;

  DBMS_VECTOR.LOAD_ONNX_MODEL(
    directory  => l_directory_name,
    file_name  => 'all_MiniLM_L12_v2.onnx',
    model_name => l_schema_name || '.VECTOR_RAG_MINILM'
  );

  SELECT COUNT(*)
    INTO l_model_count
    FROM DBA_MINING_MODELS
   WHERE OWNER = l_schema_name
     AND MODEL_NAME = 'VECTOR_RAG_MINILM';
  IF l_model_count != 1 THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Model import returned without creating the expected schema model');
  END IF;

  clean_temporary_directory;
  IF l_temporary_privilege THEN
    EXECUTE IMMEDIATE 'REVOKE CREATE MINING MODEL FROM ' || l_schema_sql;
    l_temporary_privilege := FALSE;
  END IF;
  DBMS_OUTPUT.PUT_LINE('VECTOR_RAG_MODEL_LOAD_OK');
EXCEPTION
  WHEN OTHERS THEN
    clean_temporary_directory;
    IF l_temporary_privilege THEN
      BEGIN
        EXECUTE IMMEDIATE 'REVOKE CREATE MINING MODEL FROM ' || l_schema_sql;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    END IF;
    RAISE;
END;
/

EXIT SUCCESS
