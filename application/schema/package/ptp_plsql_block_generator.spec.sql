CREATE OR REPLACE PACKAGE ptp_plsql_block_generator AS

    --
    --PLSQL block generator implementation package
    --------------------------------------------------------------------------------

    SUBTYPE gtyp_in_out IS VARCHAR2(3);
    gc_argument_in  CONSTANT gtyp_in_out := 'IN';
    gc_argument_out CONSTANT gtyp_in_out := 'OUT';

    -- 
    -- Returns create type specification DDL statement for in/out Object Type for PLSQL block  wrapper method
    -- %param a_package_name_in
    -- %param a_method_name_in
    -- %param a_in_out_in
    -- %param a_subprogram_id_in
    -- %param a_overload_in
    -- %return create type specification DDL statement
    --
    FUNCTION get_arguments_type_spec
    (
        a_package_name_in  IN user_arguments.package_name%TYPE,
        a_method_name_in   IN user_arguments.object_name%TYPE,
        a_in_out_in        IN gtyp_in_out,
        a_subprogram_id_in IN user_arguments.subprogram_id%TYPE DEFAULT NULL,
        a_overload_in      IN user_arguments.overload%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    -- 
    -- Returns create type body DDL statement for in/out Object Type for PLSQL block  wrapper method
    -- %param a_package_name_in
    -- %param a_method_name_in
    -- %param a_in_out_in
    -- %param a_subprogram_id_in
    -- %param a_overload_in
    -- %return create type body DDL statement
    --
    FUNCTION get_arguments_type_body
    (
        a_package_name_in  IN user_arguments.package_name%TYPE,
        a_method_name_in   IN user_arguments.object_name%TYPE,
        a_in_out_in        IN gtyp_in_out,
        a_subprogram_id_in IN user_arguments.subprogram_id%TYPE DEFAULT NULL,
        a_overload_in      IN user_arguments.overload%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    -- 
    -- Returns create package specification DDL statement of wrapper packager for specified package
    -- %param a_package_name_in
    -- %return create package specification DDL statement 
    --
    FUNCTION get_wrapper_package_spec(a_package_name_in IN user_arguments.package_name%TYPE)
        RETURN CLOB;

    -- 
    -- Returns create package body DDL statement of wrapper packager for specified package
    -- %param a_package_name_in
    -- %return create package body DDL statement 
    --
    FUNCTION get_wrapper_package_body(a_package_name_in IN user_arguments.package_name%TYPE)
        RETURN CLOB;

    -- internal
    FUNCTION get_wrapper_method_impl
    (
        a_package_name_in  IN VARCHAR2,
        a_method_name_in   IN VARCHAR2,
        a_subprogram_id_in IN INTEGER DEFAULT NULL,
        a_overload_in      IN INTEGER DEFAULT NULL
    ) RETURN VARCHAR2;

    --
    -- Generate argument types and packages with wrapper methods
    PROCEDURE generate_test_objects
    (
        a_execute_ddl_in              IN BOOLEAN DEFAULT TRUE,
        a_output_ddl_in               IN BOOLEAN DEFAULT FALSE,
        a_pkg_name_like_expression_in IN VARCHAR2 DEFAULT NULL
    );

END;
/
