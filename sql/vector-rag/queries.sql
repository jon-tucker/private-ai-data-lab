whenever sqlerror exit failure rollback
set define on
set verify off
set long 10000
set pagesize 100
set linesize 220
set trimspool on
alter session set container = &&oracle_pdb;

PROMPT === Storm restoration priorities; expect RESTORE-001 ===
SELECT d.DOC_ID, d.TITLE, h.SCORE, h.CHUNK_TEXT
  FROM (
    SELECT DBMS_HYBRID_VECTOR.SEARCH(JSON(q'~{
      "hybrid_index_name": "&&app_schema..VECTOR_RAG_HVI",
      "search_scorer": "RRF",
      "search_fusion": "UNION",
      "vector": {"search_text": "After a severe storm, which customers get electricity restored first?", "search_mode": "CHUNK"},
      "text": {"contains": "storm AND restoration"},
      "return": {"values": ["rowid", "score", "chunk_text", "chunk_id"], "topN": 3}
    }~')) AS PAYLOAD
      FROM DUAL
  ) s
 CROSS JOIN JSON_TABLE(s.PAYLOAD, '$[*]' COLUMNS (
    SOURCE_ROWID VARCHAR2(18) PATH '$.rowid',
    SCORE NUMBER PATH '$.score',
    CHUNK_TEXT VARCHAR2(4000) PATH '$.chunk_text'
  )) h
  JOIN &&app_schema..VECTOR_RAG_DOCUMENTS d
    ON d.ROWID = CHARTOROWID(h.SOURCE_ROWID)
 ORDER BY h.SCORE DESC;

PROMPT === Lower-cost overnight EV charging; expect EV-RATE-002 ===
SELECT d.DOC_ID, d.TITLE, h.SCORE, h.CHUNK_TEXT
  FROM (
    SELECT DBMS_HYBRID_VECTOR.SEARCH(JSON(q'~{
      "hybrid_index_name": "&&app_schema..VECTOR_RAG_HVI",
      "search_scorer": "RRF",
      "search_fusion": "UNION",
      "vector": {"search_text": "How can I charge an electric car at night for less money?", "search_mode": "CHUNK"},
      "text": {"contains": "off AND peak"},
      "return": {"values": ["rowid", "score", "chunk_text", "chunk_id"], "topN": 3}
    }~')) AS PAYLOAD
      FROM DUAL
  ) s
 CROSS JOIN JSON_TABLE(s.PAYLOAD, '$[*]' COLUMNS (
    SOURCE_ROWID VARCHAR2(18) PATH '$.rowid',
    SCORE NUMBER PATH '$.score',
    CHUNK_TEXT VARCHAR2(4000) PATH '$.chunk_text'
  )) h
  JOIN &&app_schema..VECTOR_RAG_DOCUMENTS d
    ON d.ROWID = CHARTOROWID(h.SOURCE_ROWID)
 ORDER BY h.SCORE DESC;

PROMPT === Rotten-egg odor near a stove; expect GAS-SAFETY-003 ===
SELECT d.DOC_ID, d.TITLE, h.SCORE, h.CHUNK_TEXT
  FROM (
    SELECT DBMS_HYBRID_VECTOR.SEARCH(JSON(q'~{
      "hybrid_index_name": "&&app_schema..VECTOR_RAG_HVI",
      "search_scorer": "RRF",
      "search_fusion": "UNION",
      "vector": {"search_text": "What should I do if I smell rotten eggs near my stove?", "search_mode": "CHUNK"},
      "text": {"contains": "rotten AND eggs"},
      "return": {"values": ["rowid", "score", "chunk_text", "chunk_id"], "topN": 3}
    }~')) AS PAYLOAD
      FROM DUAL
  ) s
 CROSS JOIN JSON_TABLE(s.PAYLOAD, '$[*]' COLUMNS (
    SOURCE_ROWID VARCHAR2(18) PATH '$.rowid',
    SCORE NUMBER PATH '$.score',
    CHUNK_TEXT VARCHAR2(4000) PATH '$.chunk_text'
  )) h
  JOIN &&app_schema..VECTOR_RAG_DOCUMENTS d
    ON d.ROWID = CHARTOROWID(h.SOURCE_ROWID)
 ORDER BY h.SCORE DESC;

EXIT SUCCESS
