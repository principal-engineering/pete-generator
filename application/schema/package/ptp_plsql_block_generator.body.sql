CREATE OR REPLACE PACKAGE BODY ptp_plsql_block_generator AS

    --------------------------------------------------------------------------------
    CURSOR gcrs_type_argument_lists
    (
        a_package_name_in  user_procedures.object_name%TYPE,
        a_method_name_in   user_procedures.procedure_name%TYPE,
        a_subprogram_id_in user_procedures.subprogram_id%TYPE,
        a_overload_in      user_procedures.subprogram_id%TYPE,
        a_in_out_in        ptp_plsql_block_generator.gtyp_in_out
    ) IS
        WITH type_attrs AS
         (
          --generate type attributes definitions and constructor arguments
          SELECT CASE a_in_out_in
                      WHEN 'IN' THEN
                       m.input_type_name
                      ELSE
                       m.output_type_name
                  END AS type_name,
                  a.type_attr_name || ' ' || a.type_attr_type ||
                  nvl2(a.type_attr_length, '(' || a.type_attr_length || ')', NULL) AS type_attr_definition,
                  a.type_attr_name || ' ' || a.type_attr_type || ' default null' AS type_attr_constructor,
                  a.position,
                  a.package_name,
                  a.method_name
            FROM ptm_metadata_arguments a
            JOIN ptm_metadata_methods_api_types m ON (a.package_name =
                                                     m.package_name AND
                                                     a.method_name =
                                                     m.method_name AND
                                                     a.subprogram_id =
                                                     m.subprogram_id)
           WHERE 1 = 1
             AND in_out LIKE '%' || a_in_out_in || '%'
             AND a.package_name = a_package_name_in
             AND a.method_name = a_method_name_in
             AND (a_subprogram_id_in IS NULL OR
                 a.subprogram_id = a_subprogram_id_in)
             AND (a_overload_in IS NULL OR a.overload = a_overload_in)
             AND a.data_level = 0)
        -- aggregate to lists
        SELECT DISTINCT --TODO: listagg for version > 11.1
                        ptf_varchar2_delimited_concat(type_attr_definition) --
                           over(PARTITION BY type_name ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS type_attr_definition_list,
                        ptf_varchar2_delimited_concat(type_attr_constructor) --
                        over(PARTITION BY type_name ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS type_attr_constructor_list,
                        package_name,
                        method_name,
                        type_name
          FROM type_attrs;
    TYPE gtyp_type_argument_lists_tab IS TABLE OF gcrs_type_argument_lists%ROWTYPE;

    --------------------------------------------------------------------------------
    FUNCTION get_metadata_methods_api_types
    (
        a_package_name_in  IN VARCHAR2,
        a_method_name_in   IN VARCHAR2,
        a_subprogram_id_in IN INTEGER,
        a_overload_in      IN INTEGER
    ) RETURN ptm_metadata_methods_api_types%ROWTYPE IS
        lrec_result ptm_metadata_methods_api_types%ROWTYPE;
    BEGIN
        SELECT *
          INTO lrec_result
          FROM ptm_metadata_methods_api_types m
         WHERE m.package_name = a_package_name_in
           AND m.method_name = a_method_name_in
           AND (a_subprogram_id_in IS NULL OR
               m.subprogram_id = a_subprogram_id_in)
           AND (a_overload_in IS NULL OR m.overload = a_overload_in);
        --
        RETURN lrec_result;
        --
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20000,
                                    'Method not found <package>.<method>: "' || --
                                    a_package_name_in || '"."' ||
                                    a_method_name_in || '"',
                                    TRUE);
        WHEN too_many_rows THEN
            raise_application_error(-20000,
                                    'More than one method matched. Set subprogram_id or overload',
                                    TRUE);
    END get_metadata_methods_api_types;

    --------------------------------------------------------------------------------
    FUNCTION get_arguments_type_spec
    (
        a_package_name_in  IN user_arguments.package_name%TYPE,
        a_method_name_in   IN user_arguments.object_name%TYPE,
        a_in_out_in        IN gtyp_in_out,
        a_subprogram_id_in IN user_arguments.subprogram_id%TYPE DEFAULT NULL,
        a_overload_in      IN user_arguments.overload%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_argument_type_spec_tpl     VARCHAR(32767) --
        := 'create or replace type #TypeName# as object (' || chr(10) || --
           '  #AttributesDefinitionList#,' || chr(10) || --
           '  constructor function #TypeName# (self in out nocopy #TypeName#,' ||
           chr(10) || --
           ' #AttributesConstructorList#) return self as result' || chr(10) || --
           ');';
        ltab_type_argument_lists     gtyp_type_argument_lists_tab;
        lrec_metadata_mtds_api_types ptm_metadata_methods_api_types%ROWTYPE;
    BEGIN
        --
        --get method metadata - raise exception if too many rows
        lrec_metadata_mtds_api_types := get_metadata_methods_api_types(a_package_name_in  => a_package_name_in,
                                                                       a_method_name_in   => a_method_name_in,
                                                                       a_subprogram_id_in => a_subprogram_id_in,
                                                                       a_overload_in      => a_overload_in);
        --
        OPEN gcrs_type_argument_lists(a_package_name_in  => a_package_name_in,
                                      a_method_name_in   => a_method_name_in,
                                      a_subprogram_id_in => a_subprogram_id_in,
                                      a_overload_in      => a_overload_in,
                                      a_in_out_in        => a_in_out_in);
        FETCH gcrs_type_argument_lists BULK COLLECT
            INTO ltab_type_argument_lists;
        CLOSE gcrs_type_argument_lists;
        --
        IF ltab_type_argument_lists.count > 1
        THEN
            RAISE too_many_rows;
        ELSIF ltab_type_argument_lists.count = 0
        THEN
            RETURN REPLACE(REPLACE(REPLACE(l_argument_type_spec_tpl,
                                           '#TypeName#',
                                           CASE a_in_out_in WHEN 'IN' THEN
                                           lrec_metadata_mtds_api_types.input_type_name ELSE
                                           lrec_metadata_mtds_api_types.output_type_name END),
                                   '#AttributesConstructorList#',
                                   'dummy number default null'),
                           '#AttributesDefinitionList#',
                           'dummy number');
        ELSE
            RETURN REPLACE(REPLACE(REPLACE(l_argument_type_spec_tpl,
                                           '#TypeName#',
                                           ltab_type_argument_lists(1).type_name),
                                   '#AttributesConstructorList#',
                                   ltab_type_argument_lists(1)
                                   .type_attr_constructor_list),
                           '#AttributesDefinitionList#',
                           ltab_type_argument_lists(1).type_attr_definition_list);
        END IF;
    EXCEPTION
        WHEN too_many_rows THEN
            raise_application_error(-20000,
                                    'More than one method matched. Set subprogram_id or overload',
                                    TRUE);
        WHEN OTHERS THEN
            IF gcrs_type_argument_lists%ISOPEN
            THEN
                CLOSE gcrs_type_argument_lists;
            END IF;
            RAISE;
    END get_arguments_type_spec;

    --------------------------------------------------------------------------------
    FUNCTION get_arguments_type_body
    (
        a_package_name_in  IN user_arguments.package_name%TYPE,
        a_method_name_in   IN user_arguments.object_name%TYPE,
        a_in_out_in        IN gtyp_in_out,
        a_subprogram_id_in IN user_arguments.subprogram_id%TYPE DEFAULT NULL,
        a_overload_in      IN user_arguments.overload%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_argument_type_body_tpl     VARCHAR(32767) --
        := 'create or replace type body #TypeName# as' || chr(10) || --
           '  constructor function #TypeName# (self in out nocopy #TypeName#,' ||
           chr(10) || --
           ' #AttributesConstructorList#) return self as result is' || chr(10) || --
           '  begin' || chr(10) || --
           '    return;' || chr(10) || --
           '  end;' || chr(10) || --
           'end;';
        ltab_type_argument_lists     gtyp_type_argument_lists_tab;
        lrec_metadata_mtds_api_types ptm_metadata_methods_api_types%ROWTYPE;
    BEGIN
        --
        --get method metadata - raise exception if too many rows
        lrec_metadata_mtds_api_types := get_metadata_methods_api_types(a_package_name_in  => a_package_name_in,
                                                                       a_method_name_in   => a_method_name_in,
                                                                       a_subprogram_id_in => a_subprogram_id_in,
                                                                       a_overload_in      => a_overload_in);
        --
        OPEN gcrs_type_argument_lists(a_package_name_in  => a_package_name_in,
                                      a_method_name_in   => a_method_name_in,
                                      a_subprogram_id_in => a_subprogram_id_in,
                                      a_overload_in      => a_overload_in,
                                      a_in_out_in        => a_in_out_in);
        FETCH gcrs_type_argument_lists BULK COLLECT
            INTO ltab_type_argument_lists;
        CLOSE gcrs_type_argument_lists;
        --
        IF ltab_type_argument_lists.count > 1
        THEN
            RAISE too_many_rows;
        ELSIF ltab_type_argument_lists.count = 0
        THEN
            RETURN REPLACE(REPLACE(l_argument_type_body_tpl,
                                   '#TypeName#',
                                   CASE a_in_out_in WHEN 'IN' THEN
                                   lrec_metadata_mtds_api_types.input_type_name ELSE
                                   lrec_metadata_mtds_api_types.output_type_name END),
                           '#AttributesConstructorList#',
                           'dummy number default null');
        ELSE
            RETURN REPLACE(REPLACE(l_argument_type_body_tpl,
                                   '#TypeName#',
                                   ltab_type_argument_lists(1).type_name),
                           '#AttributesConstructorList#',
                           ltab_type_argument_lists(1)
                           .type_attr_constructor_list);
        END IF;
    EXCEPTION
        WHEN too_many_rows THEN
            raise_application_error(-20000,
                                    'More than one method matched. Set subprogram_id or overload',
                                    TRUE);
        WHEN OTHERS THEN
            IF gcrs_type_argument_lists%ISOPEN
            THEN
                CLOSE gcrs_type_argument_lists;
            END IF;
            RAISE;
    END get_arguments_type_body;

    --------------------------------------------------------------------------------
    FUNCTION get_wrapper_method_spec
    (
        a_package_name_in  IN VARCHAR2,
        a_method_name_in   IN VARCHAR2,
        a_subprogram_id_in IN INTEGER DEFAULT NULL,
        a_overload_in      IN INTEGER DEFAULT NULL
    ) RETURN VARCHAR2 IS
        --
        --method implementation template  
        l_method_implementation_tpl VARCHAR2(32767) --
        := 'procedure #UxMethodName#' || chr(10) || --
           '  (' || chr(10) || --
           '    p_xml_in  in xmltype,' || chr(10) || --
           '    p_xml_out out nocopy xmltype' || chr(10) || --
           '  );' || chr(10) --
         ;
        --
        lrec_metadata_mtds_api_types ptm_metadata_methods_api_types%ROWTYPE;
    BEGIN
        --
        --get method metadata - raise exception if too many rows
        lrec_metadata_mtds_api_types := get_metadata_methods_api_types(a_package_name_in  => a_package_name_in,
                                                                       a_method_name_in   => a_method_name_in,
                                                                       a_subprogram_id_in => a_subprogram_id_in,
                                                                       a_overload_in      => a_overload_in);
        --
        RETURN REPLACE(l_method_implementation_tpl,
                       '#UxMethodName#',
                       lrec_metadata_mtds_api_types.ux_method_name);
        --
    END get_wrapper_method_spec;

    --------------------------------------------------------------------------------
    FUNCTION get_wrapper_method_impl
    (
        a_package_name_in  IN VARCHAR2,
        a_method_name_in   IN VARCHAR2,
        a_subprogram_id_in IN INTEGER DEFAULT NULL,
        a_overload_in      IN INTEGER DEFAULT NULL
    ) RETURN VARCHAR2 IS
        --
        --method implementation template  
        l_method_implementation_tpl VARCHAR2(32767) --
        := 'procedure #UxMethodName#' || chr(10) || --
           '  (' || chr(10) || --
           '    p_xml_in  in xmltype,' || chr(10) || --
           '    p_xml_out out nocopy xmltype' || chr(10) || --
           '  ) is' || chr(10) || --
           '  l_params_in  #InputTypeName#;' || chr(10) || --
           '  l_params_out #OutputTypeName# := #OutputTypeName#();' || chr(10) || --
           '  --' || chr(10) || ---
           '  --declaration of local helper variables' || chr(10) || --
           '  #RefCrsDeclaration#' || chr(10) || --
           'begin' || chr(10) || --
           '  --' || chr(10) || --
           '  --create input params object from xml' || chr(10) || --
           '  p_xml_in.toobject(object => l_params_in);' || chr(10) || --
           '  --' || chr(10) || --
           '  --for all in/out arguments assign in/out arguments of output params object' ||
           chr(10) || --
           '  #InOutAssignment#' || --      
           '  --' || chr(10) || --
           '  --call method' || chr(10) || --
           '  #ResultAssignment##PackageName#.#MethodName#(#ArgumentsAssignementList#);' ||
           chr(10) || --
           '  --' || chr(10) || --
           '  --add helper output arguments to output xml' || chr(10) || --
           '  #RefCrsToXml#' || --
           '  --' || chr(10) || --
           '  --convert output parameters object to xml' || chr(10) || --
           '  p_xml_out := xmltype.createxml(xmlData => l_params_out);' ||
           chr(10) || --
           '  --' || chr(10) || --
           'end #UxMethodName#;';
        --
        --------------------------------------------------------------------------------
        --helper templates
        --declaration
        l_refcrs_declaration_tpl VARCHAR2(255) --
        := '#LocalHelperName# sys_refcursor;' || chr(10);
        --convert to xml
        l_refcrs_to_xml_tpl VARCHAR2(255) --
        := 'l_params_out.#ArgName# := xmlType.createXml(#LocalHelperName#);' ||
           chr(10);
        --
        --cursor of cursor fragments
        CURSOR lcrs_cursor_sql_fragments IS
            SELECT DISTINCT ptf_varchar2_concat(REPLACE(l_refcrs_declaration_tpl,
                                                        '#LocalHelperName#',
                                                        a.local_helper_name)) --
                            over(ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS refcrs_declaration,
                            ptf_varchar2_concat(REPLACE(REPLACE(l_refcrs_to_xml_tpl,
                                                                '#LocalHelperName#',
                                                                a.local_helper_name),
                                                        '#ArgName#',
                                                        a.argument_name)) --
                            over(ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS refcrs_to_xml
              FROM ptm_metadata_arguments a
             WHERE package_name = a_package_name_in
               AND method_name = a_method_name_in
               AND (a_subprogram_id_in IS NULL OR
                   a.subprogram_id = a_subprogram_id_in)
               AND (a_overload_in IS NULL OR a.overload = a_overload_in)
               AND data_type = 'REF CURSOR';
        --
        --------------------------------------------------------------------------------
        --arguments templates
        --in -> out assignment - for in/out arguments
        l_inout_assignment_tpl VARCHAR2(255) := 'l_params_out.#ArgName# := l_params_in.#ArgName#;' ||
                                                chr(10);
        CURSOR lcrs_inout_asgn_sql_fragments IS
            SELECT DISTINCT ptf_varchar2_concat(REPLACE(l_inout_assignment_tpl,
                                                        '#ArgName#',
                                                        a.argument_name)) --
                            over(ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS inout_assignment,
                            position
              FROM ptm_metadata_arguments a
             WHERE package_name = a_package_name_in
               AND method_name = a_method_name_in
               AND (a_subprogram_id_in IS NULL OR
                   a.subprogram_id = a_subprogram_id_in)
               AND (a_overload_in IS NULL OR a.overload = a_overload_in)
               AND in_out = 'IN/OUT'
               AND argument_name IS NOT NULL
             ORDER BY position;
        --argument assignement
        l_args_assignment_tpl        VARCHAR2(255) := '#ArgName# => l_params_#InOut#.#ArgName#' ||
                                                      chr(10);
        l_args_helper_assignment_tpl VARCHAR2(255) := '#ArgName# => #LocalHelperName#' ||
                                                      chr(10);
        CURSOR lcrs_args_asgn_sql_fragments IS
            SELECT DISTINCT ptf_varchar2_delimited_concat(REPLACE(REPLACE(CASE
                                                                              WHEN data_type IN ('REF CURSOR') THEN
                                                                               REPLACE(l_args_helper_assignment_tpl,
                                                                                       '#LocalHelperName#',
                                                                                       a.local_helper_name)
                                                                              ELSE
                                                                               l_args_assignment_tpl
                                                                          END,
                                                                          '#ArgName#',
                                                                          a.argument_name),
                                                                  '#InOut#',
                                                                  lower(decode(a.in_out,
                                                                               'IN/OUT',
                                                                               'out',
                                                                               a.in_out)))) --
                            over(ORDER BY position rows BETWEEN unbounded preceding AND unbounded following) AS args_assignment,
                            position
              FROM ptm_metadata_arguments a
             WHERE package_name = a_package_name_in
               AND method_name = a_method_name_in
               AND (a_subprogram_id_in IS NULL OR
                   a.subprogram_id = a_subprogram_id_in)
               AND (a_overload_in IS NULL OR a.overload = a_overload_in)
               AND argument_name IS NOT NULL
             ORDER BY position;
        --
        lrec_metadata_mtds_api_types ptm_metadata_methods_api_types%ROWTYPE;
        l_sql                        VARCHAR2(32767);
    BEGIN
        --
        --get method metadata - raise exception if too many rows
        lrec_metadata_mtds_api_types := get_metadata_methods_api_types(a_package_name_in  => a_package_name_in,
                                                                       a_method_name_in   => a_method_name_in,
                                                                       a_subprogram_id_in => a_subprogram_id_in,
                                                                       a_overload_in      => a_overload_in);
        --
        --build sql statement
        l_sql := REPLACE(l_method_implementation_tpl,
                         '#UxMethodName#',
                         lrec_metadata_mtds_api_types.ux_method_name);
        l_sql := REPLACE(l_sql,
                         '#MethodName#',
                         lrec_metadata_mtds_api_types.method_name);
        l_sql := REPLACE(l_sql,
                         '#PackageName#',
                         lrec_metadata_mtds_api_types.package_name);
        l_sql := REPLACE(l_sql,
                         '#InputTypeName#',
                         lrec_metadata_mtds_api_types.input_type_name);
        l_sql := REPLACE(l_sql,
                         '#OutputTypeName#',
                         lrec_metadata_mtds_api_types.output_type_name);
        --
        --------------------------------------------------------------------------------
        --helper sql fragments
        --refcursors
        FOR sql_fragment IN lcrs_cursor_sql_fragments
        LOOP
            l_sql := REPLACE(l_sql,
                             '#RefCrsDeclaration#',
                             sql_fragment.refcrs_declaration);
            l_sql := REPLACE(l_sql, '#RefCrsToXml#', sql_fragment.refcrs_to_xml);
        END LOOP;
        l_sql := REPLACE(l_sql, '#RefCrsDeclaration#');
        l_sql := REPLACE(l_sql, '#RefCrsToXml#');
        --result assignment
        IF lrec_metadata_mtds_api_types.method_type = 'FUNCTION'
        THEN
            l_sql := REPLACE(l_sql,
                             '#ResultAssignment#',
                             'l_params_out.result := ');
        ELSE
            l_sql := REPLACE(l_sql, '#ResultAssignment#');
        END IF;
        --
        --------------------------------------------------------------------------------
        --arguments sql fragments
        FOR sql_fragment IN lcrs_inout_asgn_sql_fragments
        LOOP
            l_sql := REPLACE(l_sql,
                             '#InOutAssignment#',
                             sql_fragment.inout_assignment);
        END LOOP;
        l_sql := REPLACE(l_sql, '#InOutAssignment#');
        --argument assignements    
        FOR sql_fragment IN lcrs_args_asgn_sql_fragments
        LOOP
            l_sql := REPLACE(l_sql,
                             '#ArgumentsAssignementList#',
                             sql_fragment.args_assignment);
        END LOOP;
        l_sql := REPLACE(l_sql, '#ArgumentsAssignementList#');
        --
        RETURN l_sql;
        --
    END get_wrapper_method_impl;

    --------------------------------------------------------------------------------
    FUNCTION get_wrapper_package_spec(a_package_name_in IN user_arguments.package_name%TYPE)
        RETURN CLOB IS
        l_result       CLOB;
        l_package_name VARCHAR2(30);
    BEGIN
        --
        dbms_lob.createtemporary(lob_loc => l_result, cache => FALSE);
        --
        FOR package_method_api_type IN (SELECT *
                                          FROM ptm_metadata_methods_api_types m
                                         WHERE package_name = a_package_name_in
                                         ORDER BY m.subprogram_id)
        LOOP
            --
            IF dbms_lob.getlength(l_result) = 0
            THEN
                l_result       := 'create or replace package ' ||
                                  package_method_api_type.ux_package_name ||
                                  ' as' || chr(10);
                l_package_name := package_method_api_type.ux_package_name;
            END IF;
            --
            l_result := l_result || chr(10) ||
                        get_wrapper_method_spec(a_package_name_in  => package_method_api_type.package_name,
                                                a_method_name_in   => package_method_api_type.method_name,
                                                a_subprogram_id_in => package_method_api_type.subprogram_id);
        END LOOP;
        --
        l_result := l_result || chr(10) || 'end ' || l_package_name || ';';
        --
        RETURN l_result;
        --
    END get_wrapper_package_spec;

    --------------------------------------------------------------------------------
    FUNCTION get_wrapper_package_body(a_package_name_in IN user_arguments.package_name%TYPE)
        RETURN CLOB IS
        l_result       CLOB;
        l_package_name VARCHAR2(30);
    BEGIN
        --
        dbms_lob.createtemporary(lob_loc => l_result, cache => FALSE);
        --
        FOR package_method_api_type IN (SELECT *
                                          FROM ptm_metadata_methods_api_types m
                                         WHERE package_name = a_package_name_in
                                         ORDER BY m.subprogram_id)
        LOOP
            --
            IF dbms_lob.getlength(l_result) = 0
            THEN
                l_result       := 'create or replace package body ' ||
                                  package_method_api_type.ux_package_name ||
                                  ' as' || chr(10);
                l_package_name := package_method_api_type.ux_package_name;
            END IF;
            --
            l_result := l_result || chr(10) || lpad('-', 80, '-') || chr(10) ||
                        get_wrapper_method_impl(a_package_name_in  => package_method_api_type.package_name,
                                                a_method_name_in   => package_method_api_type.method_name,
                                                a_subprogram_id_in => package_method_api_type.subprogram_id);
        END LOOP;
        --
        l_result := l_result || chr(10) || 'end ' || l_package_name || ';';
        --
        RETURN l_result;
        --
    END get_wrapper_package_body;

    --------------------------------------------------------------------------------
    PROCEDURE generate_test_objects
    (
        a_execute_ddl_in              IN BOOLEAN DEFAULT TRUE,
        a_output_ddl_in               IN BOOLEAN DEFAULT FALSE,
        a_pkg_name_like_expression_in IN VARCHAR2 DEFAULT NULL
    ) IS
        --
        PROCEDURE execute_ddl_statement
        (
            p_statement_in    IN CLOB,
            p_package_name_in IN user_arguments.package_name%TYPE DEFAULT NULL,
            p_method_name_in  IN user_arguments.object_name%TYPE DEFAULT NULL
        ) IS
            le_succes_with_comp_error EXCEPTION;
            PRAGMA EXCEPTION_INIT(le_succes_with_comp_error, -24344);
        BEGIN
            IF p_statement_in IS NOT NULL
            THEN
                IF a_output_ddl_in
                THEN
                    dbms_output.put_line(p_statement_in || chr(10) || '/' ||
                                         chr(10));
                END IF;
                IF a_execute_ddl_in
                THEN
                    EXECUTE IMMEDIATE p_statement_in;
                END IF;
            END IF;
        EXCEPTION
            WHEN le_succes_with_comp_error THEN
                dbms_output.put_line('ERROR: package:method: [' ||
                                     p_package_name_in || ':' ||
                                     p_method_name_in || ']');
                dbms_output.put_line(SQLERRM);
            WHEN OTHERS THEN
                dbms_output.put_line(substr(p_statement_in, 1, 4000));
                dbms_output.put_line('ERROR: package:method: [' ||
                                     p_package_name_in || ':' ||
                                     p_method_name_in || ']');
                dbms_output.put_line(SQLERRM);
                RAISE;
        END;
        --
    BEGIN
        <<package_loop>>
        FOR lrec_package IN (SELECT DISTINCT package_name
                               FROM ptm_metadata_methods
                              WHERE package_name LIKE
                                    nvl(a_pkg_name_like_expression_in, '%'))
        LOOP
            <<method_loop>>
            FOR lrec_method IN (SELECT *
                                  FROM ptm_metadata_methods
                                 WHERE package_name = lrec_package.package_name)
            LOOP
                --
                --create input type specification
                execute_ddl_statement(p_statement_in    => get_arguments_type_spec(a_package_name_in  => lrec_method.package_name,
                                                                                   a_method_name_in   => lrec_method.method_name,
                                                                                   a_in_out_in        => ptp_plsql_block_generator.gc_argument_in,
                                                                                   a_subprogram_id_in => lrec_method.subprogram_id),
                                      p_package_name_in => lrec_method.method_name,
                                      p_method_name_in  => lrec_method.method_name);
                --
                --create input type body
                execute_ddl_statement(p_statement_in    => get_arguments_type_body(a_package_name_in  => lrec_method.package_name,
                                                                                   a_method_name_in   => lrec_method.method_name,
                                                                                   a_in_out_in        => ptp_plsql_block_generator.gc_argument_in,
                                                                                   a_subprogram_id_in => lrec_method.subprogram_id),
                                      p_package_name_in => lrec_method.method_name,
                                      p_method_name_in  => lrec_method.method_name);
                --
                --create output type specification
                execute_ddl_statement(p_statement_in    => get_arguments_type_spec(a_package_name_in  => lrec_method.package_name,
                                                                                   a_method_name_in   => lrec_method.method_name,
                                                                                   a_in_out_in        => ptp_plsql_block_generator.gc_argument_out,
                                                                                   a_subprogram_id_in => lrec_method.subprogram_id),
                                      p_package_name_in => lrec_method.method_name,
                                      p_method_name_in  => lrec_method.method_name);
                --
                --create output type body
                execute_ddl_statement(p_statement_in    => get_arguments_type_body(a_package_name_in  => lrec_method.package_name,
                                                                                   a_method_name_in   => lrec_method.method_name,
                                                                                   a_in_out_in        => ptp_plsql_block_generator.gc_argument_out,
                                                                                   a_subprogram_id_in => lrec_method.subprogram_id),
                                      p_package_name_in => lrec_method.method_name,
                                      p_method_name_in  => lrec_method.method_name);
            END LOOP method_loop;
            --
            --create package specification
            execute_ddl_statement(p_statement_in    => get_wrapper_package_spec(a_package_name_in => lrec_package.package_name),
                                  p_package_name_in => lrec_package.package_name);
            --
            --create package body
            execute_ddl_statement(p_statement_in    => get_wrapper_package_body(a_package_name_in => lrec_package.package_name),
                                  p_package_name_in => lrec_package.package_name);
            --
        END LOOP package_loop;
        --
    END generate_test_objects;

END;
/
