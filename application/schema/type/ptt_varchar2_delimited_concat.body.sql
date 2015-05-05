CREATE OR REPLACE TYPE BODY ptt_varchar2_delimited_concat IS

    STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT ptt_varchar2_delimited_concat)
        RETURN NUMBER IS
    BEGIN
        ctx := ptt_varchar2_delimited_concat(NULL);
        RETURN ODCIConst.Success;
    END;

    MEMBER FUNCTION ODCIAggregateIterate
    (
        SELF  IN OUT ptt_varchar2_delimited_concat,
        VALUE IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF self.text IS NULL
        THEN
            self.text := VALUE;
        ELSE
            self.text := self.text || ',' || VALUE;
        END IF;
        RETURN ODCIConst.Success;
    END;

    MEMBER FUNCTION ODCIAggregateTerminate
    (
        SELF        IN ptt_varchar2_delimited_concat,
        returnValue OUT VARCHAR2,
        flags       IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        returnValue := self.text;
        RETURN ODCIConst.Success;
    END;

    MEMBER FUNCTION ODCIAggregateMerge
    (
        SELF IN OUT ptt_varchar2_delimited_concat,
        ctx2 IN ptt_varchar2_delimited_concat
    ) RETURN NUMBER IS
    BEGIN
        IF ctx2.text IS NULL
        THEN
            NULL;
        ELSE
            self.text := self.text || ',' || ctx2.text;
        END IF;
        RETURN ODCIConst.Success;
    END;

END;
/
