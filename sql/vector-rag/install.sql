whenever sqlerror exit failure rollback
set define on
set verify off
set serveroutput on

alter session set container = &&oracle_pdb;

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM DBA_MINING_MODELS
   WHERE OWNER = UPPER('&&app_schema')
     AND MODEL_NAME = 'VECTOR_RAG_MINILM';
  IF l_count != 1 THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Load VECTOR_RAG_MINILM into the application schema before installing');
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM DBA_TABLES
   WHERE OWNER = UPPER('&&app_schema')
     AND TABLE_NAME = 'VECTOR_RAG_DOCUMENTS';
  IF l_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20011,
      'VECTOR_RAG_DOCUMENTS already exists; refusing to replace it');
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM DBA_INDEXES
   WHERE OWNER = UPPER('&&app_schema')
     AND INDEX_NAME = 'VECTOR_RAG_HVI';
  IF l_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20012,
      'VECTOR_RAG_HVI already exists; refusing to replace it');
  END IF;
END;
/

CREATE TABLE &&app_schema..VECTOR_RAG_DOCUMENTS (
  DOC_ID         VARCHAR2(30)   CONSTRAINT VECTOR_RAG_DOCS_PK PRIMARY KEY,
  TITLE          VARCHAR2(120)  NOT NULL,
  CATEGORY       VARCHAR2(40)   NOT NULL,
  DOCUMENT_TEXT  VARCHAR2(2000) NOT NULL
);

INSERT ALL
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'RESTORE-001', 'Storm restoration priorities', 'OUTAGE',
    'DOC_ID=RESTORE-001 | TITLE=Storm restoration priorities | Utility crews first address immediate threats to life and public safety, then repair transmission and distribution equipment serving the largest number of customers. Hospitals, emergency services, and other critical facilities receive priority. Individual restoration times vary with damage, weather, and crew access. Customers should stay clear of downed wires and report an outage through the utility outage line.')
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'EV-RATE-002', 'Lower-cost overnight EV charging', 'ELECTRIC RATES',
    'DOC_ID=EV-RATE-002 | TITLE=Lower-cost overnight EV charging | Customers on a time-of-use electric rate may reduce charging costs by scheduling an electric vehicle to charge during the published off-peak hours. The exact hours and prices depend on the customer rate plan and season. Check the current tariff before changing a charging schedule. Use a qualified electrician for home charging equipment.')
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'GAS-SAFETY-003', 'Natural gas odor near an appliance', 'GAS SAFETY',
    'DOC_ID=GAS-SAFETY-003 | TITLE=Natural gas odor near an appliance | Natural gas is odorized to smell like rotten eggs. If you smell gas, leave the building immediately. Do not use a phone, light switch, appliance, flame, or vehicle inside or near the building. Once safely away, call emergency services and the utility gas emergency number. Do not re-enter until authorities say it is safe.')
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'METER-READ-004', 'Estimated meter readings', 'BILLING',
    'DOC_ID=METER-READ-004 | TITLE=Estimated meter readings | A bill may use an estimated meter reading when an actual reading is unavailable. The bill identifies an estimate. When a later actual reading is received, the next bill may include an adjustment for the difference. Customers can compare the meter display with the reading instructions printed on the bill and contact customer service if the usage appears incorrect.')
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'WATER-LEAK-005', 'Report a water main leak', 'WATER',
    'DOC_ID=WATER-LEAK-005 | TITLE=Report a water main leak | Report water flowing from a street, sidewalk, or public water main to the utility emergency or water-service line. Give the location and describe the flow if it is safe to observe. Do not enter a flooded street or touch equipment near electrical wires. Utility crews determine whether the location requires an urgent dispatch.')
  INTO &&app_schema..VECTOR_RAG_DOCUMENTS VALUES (
    'BILL-HELP-006', 'Payment assistance information', 'CUSTOMER SUPPORT',
    'DOC_ID=BILL-HELP-006 | TITLE=Payment assistance information | Customers who cannot pay a utility bill by its due date should contact customer service promptly to ask about payment arrangements and currently available assistance programs. Program eligibility and funding vary. Use the contact details printed on the current bill and do not send account credentials in an unsecured message.')
SELECT 1 FROM DUAL;

COMMIT;

CREATE HYBRID VECTOR INDEX &&app_schema..VECTOR_RAG_HVI
  ON &&app_schema..VECTOR_RAG_DOCUMENTS (DOCUMENT_TEXT)
  PARAMETERS ('MODEL &&app_schema..VECTOR_RAG_MINILM VECTOR_IDXTYPE IVF')
  PARALLEL 1;

PROMPT VECTOR_RAG_INSTALL_OK
EXIT SUCCESS
