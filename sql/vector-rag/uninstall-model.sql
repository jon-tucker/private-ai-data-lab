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
  IF l_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20030,
      'Remove VECTOR_RAG_DOCUMENTS first; its hybrid index may use the model');
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM DBA_MINING_MODELS
   WHERE OWNER = UPPER('&&app_schema')
     AND MODEL_NAME = 'VECTOR_RAG_MINILM';
  IF l_count = 1 THEN
    DBMS_VECTOR.DROP_ONNX_MODEL(
      model_name => UPPER('&&app_schema') || '.VECTOR_RAG_MINILM',
      force => TRUE
    );
    DBMS_OUTPUT.PUT_LINE('Removed VECTOR_RAG_MINILM.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Example model is already absent; nothing removed.');
  END IF;
END;
/

EXIT SUCCESS
