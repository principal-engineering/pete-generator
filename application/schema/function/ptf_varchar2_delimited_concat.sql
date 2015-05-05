CREATE OR REPLACE FUNCTION ptf_varchar2_delimited_concat(VALUE IN VARCHAR2)
    RETURN VARCHAR2
    AGGREGATE USING ptt_varchar2_delimited_concat;
/
