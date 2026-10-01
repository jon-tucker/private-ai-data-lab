whenever sqlerror exit failure rollback
set define on
set verify off
set serveroutput on
alter session set container = &&oracle_pdb;

DECLARE
  l_count PLS_INTEGER;
  l_dimensions PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM DBA_MINING_MODELS
   WHERE OWNER = UPPER('&&app_schema')
     AND MODEL_NAME = 'VECTOR_RAG_MINILM';
  IF l_count != 1 THEN
    RAISE_APPLICATION_ERROR(-20020, 'Expected embedding model is missing');
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM DBA_TABLES
   WHERE OWNER = UPPER('&&app_schema')
     AND TABLE_NAME = 'VECTOR_RAG_DOCUMENTS';
  IF l_count != 1 THEN
    RAISE_APPLICATION_ERROR(-20021, 'Example document table is missing');
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM DBA_INDEXES
   WHERE OWNER = UPPER('&&app_schema')
     AND INDEX_NAME = 'VECTOR_RAG_HVI'
     AND STATUS = 'VALID';
  IF l_count != 1 THEN
    RAISE_APPLICATION_ERROR(-20022, 'Hybrid vector index is missing or invalid');
  END IF;

  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM &&app_schema..VECTOR_RAG_DOCUMENTS'
    INTO l_count;
  IF l_count != 6 THEN
    RAISE_APPLICATION_ERROR(-20023,
      'Expected exactly six synthetic example documents');
  END IF;

  EXECUTE IMMEDIATE
    'SELECT VECTOR_DIMENSION_COUNT(VECTOR_EMBEDDING(' ||
    DBMS_ASSERT.ENQUOTE_NAME(UPPER('&&app_schema'), FALSE) ||
    '.VECTOR_RAG_MINILM USING ''verification query'' AS data)) FROM DUAL'
    INTO l_dimensions;
  IF l_dimensions != 384 THEN
    RAISE_APPLICATION_ERROR(-20024,
      'Expected 384-dimensional MiniLM query embeddings');
  END IF;

  DBMS_OUTPUT.PUT_LINE('VECTOR_RAG_VALIDATION_OK');
  DBMS_OUTPUT.PUT_LINE('Embedding dimensions: ' || l_dimensions);
END;
/

SELECT OWNER, MODEL_NAME, MINING_FUNCTION, ALGORITHM
  FROM DBA_MINING_MODELS
 WHERE OWNER = UPPER('&&app_schema')
   AND MODEL_NAME = 'VECTOR_RAG_MINILM';

SELECT OWNER, INDEX_NAME, INDEX_TYPE, STATUS
  FROM DBA_INDEXES
 WHERE OWNER = UPPER('&&app_schema')
   AND INDEX_NAME = 'VECTOR_RAG_HVI';

SELECT DOC_ID, TITLE, CATEGORY
  FROM &&app_schema..VECTOR_RAG_DOCUMENTS
 ORDER BY DOC_ID;

EXIT SUCCESS
