@&&run_dir_begin

prompt create source types
@&&run_dir src_types

prompt create source packages
@&&run_dir src_packages

prompt create test cases and test scripts
@&&run_dir test_cases_and_test_scripts

--begin
--  utp_plsql_block_generator.generate_test_objects(p_pkg_name_like_expression_in => 'UT_TEST%');
--end;
--/

show errors

@&&run_dir_end
