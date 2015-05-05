CREATE OR REPLACE TYPE src_object_type AS OBJECT
(
    n               NUMBER,
    v               VARCHAR2(255),
    d               DATE,
    idts            INTERVAL DAY TO SECOND,
    iytm            INTERVAL YEAR TO MONTH,
    obj_object_type src_other_object_type,
    obj_table_type  src_object_table,
    obj_varray_type src_object_varray
)
;
/
