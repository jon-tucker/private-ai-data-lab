/*
 * Platform-owned compatibility objects.
 *
 * The vendor model loader is intentionally excluded. These tables retain the
 * native VECTOR storage used by the application without granting DATA_PUMP_DIR
 * or loading an ONNX model into the database.
 */
CREATE TABLE product_embeddings (
    embedding_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id        NUMBER NOT NULL REFERENCES products(product_id),
    embedding_model   VARCHAR2(100) DEFAULT 'platform_ollama',
    embedding_text    CLOB,
    embedding         VECTOR(384),
    created_at        TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT uq_prod_embed UNIQUE (product_id, embedding_model)
);

CREATE TABLE post_embeddings (
    embedding_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id           NUMBER NOT NULL REFERENCES social_posts(post_id),
    embedding_model   VARCHAR2(100) DEFAULT 'platform_ollama',
    embedding_text    CLOB,
    embedding         VECTOR(384),
    created_at        TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT uq_post_embed UNIQUE (post_id, embedding_model)
);

CREATE TABLE semantic_matches (
    match_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id           NUMBER NOT NULL REFERENCES social_posts(post_id),
    product_id        NUMBER NOT NULL REFERENCES products(product_id),
    similarity_score  NUMBER(6,5),
    match_rank        NUMBER(4),
    match_method      VARCHAR2(30) DEFAULT 'vector'
                      CHECK (match_method IN ('vector','keyword','hybrid','visual')),
    verified          NUMBER(1) DEFAULT 0,
    created_at        TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE INDEX idx_semantic_post ON semantic_matches(post_id);
CREATE INDEX idx_semantic_product ON semantic_matches(product_id);
CREATE INDEX idx_semantic_score ON semantic_matches(similarity_score DESC);

/*
 * Compatibility context only. It deliberately does not install VPD policies
 * and does not trust the caller-provided demonstration username. Until real
 * application authentication is added, all sessions receive a fixed private
 * demonstration context.
 */
CREATE OR REPLACE PACKAGE sc_security_ctx AS
    PROCEDURE set_user_context(p_username IN VARCHAR2);
    FUNCTION get_region RETURN VARCHAR2;
    FUNCTION get_role RETURN VARCHAR2;
END sc_security_ctx;
/

CREATE OR REPLACE PACKAGE BODY sc_security_ctx AS
    PROCEDURE set_user_context(p_username IN VARCHAR2) IS
    BEGIN
        NULL;
    END;

    FUNCTION get_region RETURN VARCHAR2 IS
    BEGIN
        RETURN 'ALL';
    END;

    FUNCTION get_role RETURN VARCHAR2 IS
    BEGIN
        RETURN 'admin';
    END;
END sc_security_ctx;
/
