-- version-features.md claims: "IS JSON predicate (SQL-standard JSON
-- validation) | 12.3". Verify IS JSON correctly evaluates true for valid
-- JSON payloads (object/array) and false for text that is not valid JSON,
-- against stored rows in json_documents (fixtures/12.3-delta.sql).
SELECT label, payload IS JSON AS is_json FROM json_documents ORDER BY id;
