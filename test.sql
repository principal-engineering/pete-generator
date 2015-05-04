grant create materialized view to pete_test;

connect pete_test/pete_test@local

prompt install pete-generator
@install

prompt define action and script
define g_run_action = run
define g_run_script = run

@&&run_dir test

exit