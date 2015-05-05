CREATE OR REPLACE TYPE ptt_varchar2_concat AS OBJECT
(
    text VARCHAR2(4000),
    STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT ptt_varchar2_concat)
        RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateIterate
    (
        SELF  IN OUT ptt_varchar2_concat,
        VALUE IN VARCHAR2
    ) RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateTerminate
    (
        SELF        IN ptt_varchar2_concat,
        returnValue OUT VARCHAR2,
        flags       IN NUMBER
    ) RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateMerge
    (
        SELF IN OUT ptt_varchar2_concat,
        ctx2 IN ptt_varchar2_concat
    ) RETURN NUMBER
)
/
