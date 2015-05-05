CREATE OR REPLACE PACKAGE src_arg_data_types AS

    --package with test for arguments with supported data types

    --sys_refcursor
    /**
    * not implemented as it needs xml to cursor conversion
    * imeplement such wrappers manually
    */
    --PROCEDURE method_sys_refcrs_in(a_crs_in IN SYS_REFCURSOR);
    --PROCEDURE method_sys_refcrs_inout(a_crs_inout IN OUT SYS_REFCURSOR);

    PROCEDURE method_sys_refcrs_out(a_crs_out OUT SYS_REFCURSOR);

    --xmltype
    PROCEDURE method_xmltype_in
    (
        a_xml_in    IN xmltype,
        a_xml_out   OUT xmltype,
        a_xml_inout IN OUT xmltype
    );

    --scalar
    --  number
    --  varchar2
    --  date
    --  interval day to second
    --  interval year to month
    PROCEDURE method_scalar
    (
        a_number_in    IN NUMBER,
        a_number_out   OUT NUMBER,
        a_varchar2_in  IN VARCHAR2,
        a_varchar2_out OUT VARCHAR2,
        a_date_in      IN DATE,
        a_date_out     OUT DATE,
        a_idts_in      IN INTERVAL DAY TO SECOND,
        a_idts_out     OUT INTERVAL DAY TO SECOND,
        a_iytm_in      IN INTERVAL YEAR TO MONTH,
        a_iytm_out     OUT INTERVAL YEAR TO MONTH
    );

    --sql type object
    PROCEDURE method_object_in(a_obj_in IN src_object_type);
    PROCEDURE method_object_out(a_obj_out OUT src_object_type);
    PROCEDURE method_object_inout(a_obj_inout IN OUT src_object_type);

    --sql type varray
    PROCEDURE method_object_varray_in(a_varray_in IN src_object_varray);
    PROCEDURE method_object_varray_out(a_varray_out OUT src_object_varray);
    PROCEDURE method_object_varray_inout(a_varray_inout IN OUT src_object_varray);

    --sql type table
    PROCEDURE method_object_table_in(a_table_in IN src_object_table);
    PROCEDURE method_object_table_out(a_table_out OUT src_object_table);
    PROCEDURE method_object_table_inout(a_table_inout IN OUT src_object_table);

    --plsql record
    TYPE typ_record IS RECORD(
        n               NUMBER,
        v               VARCHAR2(255),
        d               DATE,
        idts            INTERVAL DAY TO SECOND,
        iytm            INTERVAL YEAR TO MONTH,
        obj_object_type src_other_object_type,
        obj_table_type  src_object_table,
        obj_varray_type src_object_varray);

    --plsql table
    TYPE typ_table IS TABLE OF typ_record;

    --plsql indexed table
    TYPE typ_plsint_indexed_table IS TABLE OF typ_record INDEX BY PLS_INTEGER;
    TYPE typ_varchar2_indexed_table IS TABLE OF typ_record INDEX BY VARCHAR2(255);

    --plsql subtype
    SUBTYPE short_string IS VARCHAR2(255);

END;
/
CREATE OR REPLACE PACKAGE BODY src_arg_data_types AS

    --sys_refcursor
    PROCEDURE method_sys_refcrs_out(a_crs_out OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN a_crs_out FOR
            SELECT 42 AS n FROM dual;
    END;

    --xmltype
    PROCEDURE method_xmltype_in
    (
        a_xml_in    IN xmltype,
        a_xml_out   OUT xmltype,
        a_xml_inout IN OUT xmltype
    ) IS
    BEGIN
        NULL;
    END;

    --scalar
    --  number
    --  varchar2
    --  date
    --  interval day to second
    --  interval year to month
    PROCEDURE method_scalar
    (
        a_number_in    IN NUMBER,
        a_number_out   OUT NUMBER,
        a_varchar2_in  IN VARCHAR2,
        a_varchar2_out OUT VARCHAR2,
        a_date_in      IN DATE,
        a_date_out     OUT DATE,
        a_idts_in      IN INTERVAL DAY TO SECOND,
        a_idts_out     OUT INTERVAL DAY TO SECOND,
        a_iytm_in      IN INTERVAL YEAR TO MONTH,
        a_iytm_out     OUT INTERVAL YEAR TO MONTH
    ) IS
    BEGIN
        NULL;
    END;

    --sql type object
    PROCEDURE method_object_in(a_obj_in IN src_object_type) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_out(a_obj_out OUT src_object_type) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_inout(a_obj_inout IN OUT src_object_type) IS
    BEGIN
        NULL;
    END;

    --sql type varray
    PROCEDURE method_object_varray_in(a_varray_in IN src_object_varray) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_varray_out(a_varray_out OUT src_object_varray) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_varray_inout(a_varray_inout IN OUT src_object_varray) IS
    BEGIN
        NULL;
    END;

    --sql type table
    PROCEDURE method_object_table_in(a_table_in IN src_object_table) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_table_out(a_table_out OUT src_object_table) IS
    BEGIN
        NULL;
    END;

    PROCEDURE method_object_table_inout(a_table_inout IN OUT src_object_table) IS
    BEGIN
        NULL;
    END;

END;
/
