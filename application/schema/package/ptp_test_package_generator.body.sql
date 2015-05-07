CREATE OR REPLACE PACKAGE BODY ptp_test_package_generator AS

    CURSOR c_metody(a_package_name_in IN VARCHAR2) IS
        SELECT *
          FROM user_procedures up --enhancement - konfigurable whether use user% or all% system view - user is faster, but you may want to generate from another schema
         WHERE upper(up.object_name) = upper(a_package_name_in)
           AND up.PROCEDURE_NAME IS NOT NULL
         ORDER BY up.SUBPROGRAM_ID;
    /**
    * prints a string to standard output
    */
    PROCEDURE print(a_what_in IN VARCHAR2) IS
    BEGIN
        dbms_output.put_line(a_what_in); --enhancement - support for long strings
    END print;

    /**
    * returns a name for the test package. If it is suitable it will be PREFIX (default 'UT_' + name of given package)
    * else the computed name will be shortened to 28 chars and appended with a counter
    */
    FUNCTION get_test_pack_name(a_package_name_in IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'UT_' || upper(a_package_name_in);
        --todo doimplementovat okrajove pripady
    END;

    /**
     * return a name for a test method. If it is suitable it will be 'test_' + name of a given method name
        * else the computed name will be shortened to 28 chars and appended with a counter
    */
    FUNCTION get_test_method_name
    (
        a_method_name_in IN VARCHAR2,
        a_overload_in    IN NUMBER
    ) RETURN VARCHAR2 IS
        l_suffix VARCHAR2(10);
    BEGIN
        IF (a_overload_in IS NOT NULL)
        THEN
            l_suffix := '_' || a_overload_in;
        END IF;
    
        RETURN get_usable_name(a_method_name_in || l_suffix);
    END;

    /**
    * returns a string with test method spec for a given method
    */
    FUNCTION get_test_method_spec(a_method_name_in VARCHAR2) RETURN VARCHAR2 IS
        l_result VARCHAR2(3000);
    BEGIN
        /*
            PROCEDURE NASOB;  todo neajeky commment?
        */
        l_result := '    procedure ' || a_method_name_in || ';
';
    
        pete_logger.trace(l_result);
        RETURN l_result;
    END;

    /**
    * return 
    
    /**
    * returns a string with package head definition
    */
    FUNCTION get_package_head(a_package_name_in IN VARCHAR2) RETURN VARCHAR2 IS
        l_result         VARCHAR2(10000);
        l_test_pack_name VARCHAR2(35);
    BEGIN
        l_test_pack_name := get_test_pack_name(a_package_name_in);
        l_result         := 'CREATE OR REPLACE PACKAGE ' || l_test_pack_name || ' IS
    --
    -- Automated tests package
    --

    --
    -- Hook method - runs once before all test procedures and other hook methods
    -- 
    PROCEDURE before_all;
    
    --
    -- Hook method - runs once before each test procedure
    -- 
    PROCEDURE before_each;

    --
    -- Hook method - runs once after each test procedure
    --
    PROCEDURE after_each;

    --
    -- Hook method - runs once after all test procedures and other hook methods
    --
    PROCEDURE after_all;

    -- test methods
';
        FOR r_method IN c_metody(a_package_name_in)
        LOOP
            l_result := l_result ||
                        get_test_method_spec(get_test_method_name(r_method.procedure_name,
                                                                  r_method.overload)); --enhancement - overloaded procedures
        END LOOP;
    
        l_result := l_result || 'END ' || l_test_pack_name || ';
' || '/
';
        pete_logger.trace(l_result);
        RETURN l_result;
    END get_package_head;

    /**
    * returns a return parameter type for a given function of null if given method is procedure
    */
    FUNCTION get_return_parameter_type
    (
        a_package_name_in IN VARCHAR2,
        a_method_name_in  IN VARCHAR2,
        a_overload_in     IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return_param VARCHAR2(50);
    BEGIN
        BEGIN
            SELECT data_type
              INTO l_return_param
              FROM user_arguments ua
             WHERE ua.PACKAGE_NAME = a_package_name_in
               AND ua.OBJECT_NAME = a_method_name_in
               AND ua.OVERLOAD = a_overload_in
               AND ua.POSITION = 0;
            IF (l_return_param = 'VARCHAR2')
            THEN
                l_return_param := 'VARCHAR2(1000)';
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_return_param := NULL;
        END;
    
        RETURN l_return_param;
    END;

    /**
     * returns a call of a given procedure
    */
    FUNCTION get_call
    (
        a_package_name_in IN VARCHAR2,
        a_method_name_in  IN VARCHAR2,
        a_overload_in     IN NUMBER
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(4000);
        l_has_params boolean default false;
    BEGIN
        -- MATIKA.NASOB(a_in => '', b_in => '')
        l_result := a_package_name_in || '.' || a_method_name_in || '(';
        FOR r_arg IN (SELECT *
                        FROM user_arguments ua
                       WHERE ua.OBJECT_NAME = a_method_name_in
                         AND ua.PACKAGE_NAME = a_package_name_in
                         AND ua.OVERLOAD = a_overload_in
                         AND ua.POSITION > 0
                       ORDER BY ua.position)
        LOOP
            l_result := l_result || r_arg.argument_name || ' => '''',';
            l_has_params := true;
        END LOOP;
        --delete last ',' or '(' if there are no arguments 
        l_result := substr(l_result, 1, length(l_result) - 1);
        if (l_has_params) then 
        l_result := l_result || ')';
        end if;
        l_result := l_result || ';';
        RETURN l_result;
    END;

    /**
    * shortens a given string by deleting wovels from the back of the string until
    * the string has length of 30 or less. If there are not enough wovels to delete, 
    * simply trims the temporaray wovelfree result
    */
    FUNCTION get_usable_name(a_name_in VARCHAR2) RETURN VARCHAR2 IS
        l_result VARCHAR2(100);
        l_length NUMBER;
    BEGIN
        l_result := a_name_in;
        --while too long, cut a wovel from the back. One at a time.
        WHILE (length(l_result) > 30)
        LOOP
            l_length := length(l_result);
            pete_logger.trace('l_result ' || l_result);
            --this regexp is a convenient trick - it depends on greedy behaviour of the first .* pattern
            l_result := regexp_replace(l_result,
                                       '(.*)[aeiouy](.*)',
                                       '\1\2',
                                       1,
                                       1,
                                       'i');
            IF (length(l_result) = l_length)
            THEN
                pete_logger.trace('no more wovels, forget the rest');
                l_result := substr(l_result, 1, 30);
            END IF;
        END LOOP;
    
        pete_logger.trace('returns ' || l_result);
        RETURN l_result;
    END get_usable_name;

    /**
    * returns an implementation of a test method
    */
    FUNCTION get_test_method_impl
    (
        a_package_name_in     IN VARCHAR2,
        a_method_name_in      IN VARCHAR2,
        a_overload_in         IN NUMBER,
        a_test_method_name_in IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_result                VARCHAR2(4000);
        l_return_parameter_type VARCHAR2(30); -- null for procedures
    BEGIN
        /*
            PROCEDURE NASOB_1 IS
              l_actual number;
              l_expected number;
            BEGIN
                l_expected = '';
        
                --call tested code
                l_actual := MATIKA.NASOB(a_in => '', b_in => '')
        
                pete_Assert.eq (a_expected_in => l_expected, a_actual_in => l_actual, a_comment_in => 'Test of matika.nasob');
        
            END NASOB_1;
        */
        l_result := '    procedure ' || a_test_method_name_in || ' is
';
    
        l_return_parameter_type := get_return_parameter_type(a_package_name_in => a_package_name_in,
                                                             a_method_name_in  => a_method_name_in,
                                                             a_overload_in     => a_overload_in);
    
        IF (l_return_parameter_type IS NOT NULL)
        THEN
            --function
            l_result := l_result || '      l_actual ' ||
                        l_return_parameter_type || ';
      l_expected ' || l_return_parameter_type || ';
    begin
      l_expected := '''';

      --call tested code
      l_actual := ' ||
                        get_call(a_package_name_in => a_package_name_in,
                                 a_method_name_in  => a_method_name_in,
                                 a_overload_in     => a_overload_in) || '

      utAssert.eq(a_expected_in => l_expected, a_actual_in => l_actual, a_comment_in => ''Test of ' ||
                        a_package_name_in || '.' || a_method_name_in ||
                        ''');
    end ' || a_test_method_name_in || ';
';
        ELSE
            l_result := l_result || '    begin
      --call tested code
      ' ||
                        get_call(a_package_name_in => a_package_name_in,
                                 a_method_name_in  => a_method_name_in,
                                 a_overload_in     => a_overload_in) || '

      utAssert.this(null /*<boolean expression>*/, a_comment_in => ''Test of ' ||
                        a_package_name_in || '.' || a_method_name_in ||
                        ''');
    end ' || a_test_method_name_in || ';
';
        END IF;
    
        pete_logger.trace(l_result);
        RETURN l_result;
    END;
    /**
    * returns a string with package body definition
    */
    FUNCTION get_package_body(a_package_name_in IN VARCHAR2) RETURN VARCHAR2 IS
        l_result         VARCHAR2(10000);
        l_test_pack_name VARCHAR2(35);
    BEGIN
        l_test_pack_name := get_test_pack_name(a_package_name_in);
        l_result         := 'CREATE OR REPLACE PACKAGE BODY ' ||
                            l_test_pack_name || ' IS

    PROCEDURE before_all
    is
    begin
      null;
    end;
    
    PROCEDURE before_each
    is
    begin
      null;
    end;

    PROCEDURE after_each
    is
    begin
      null;
    end;

    PROCEDURE after_all
    is
    begin
      null;
    end;

    -- test methods
';
        FOR r_method IN c_metody(a_package_name_in)
        LOOP
            l_result := l_result ||
                        get_test_method_impl(a_package_name_in     => r_method.object_name,
                                             a_method_name_in      => r_method.procedure_name,
                                             a_overload_in         => r_method.overload,
                                             a_test_method_name_in => get_test_method_name(r_method.procedure_name,
                                                                                           r_method.overload));
        END LOOP;
    
        l_result := l_result || 'END ' || l_test_pack_name || ';
' || '/
';
        pete_logger.trace(l_result);
        RETURN l_result;
    END get_package_body;

    /**
    * genereates a testing package to test a given package
    */
    PROCEDURE gen_package(a_package_name_in IN VARCHAR2) IS
    BEGIN
        pete_logger.trace('GEN_PACKAGE: ' || 'a_package_name_in:' ||
                          NVL(a_package_name_in, 'NULL'));
    
        print(get_package_head(a_package_name_in));
        print(get_package_body(a_package_name_in));
    END;

    /**
    * generates a test method to test a given metod - it may be added to an existing testing package
    */
    PROCEDURE gen_method
    (
        a_package_name_in IN VARCHAR2,
        a_method_name_in  IN VARCHAR2
    ) IS
        l_result VARCHAR2(10000);
    BEGIN
        l_result := get_test_method_spec(a_method_name_in => a_method_name_in) ||
                    chr(10) || chr(10) ||
                    get_test_method_impl(a_package_name_in     => a_package_name_in,
                                         a_method_name_in      => a_method_name_in,
                                         a_overload_in         => NULL,
                                         a_test_method_name_in => a_method_name_in); --enhancement - overloads
        print(l_result);
    END;
END ptp_test_package_generator;
/
