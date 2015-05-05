prompt init sqlsn
@sqlsnrc

--we need sqlsn run module to traverse directory tree during install
prompt require sqlsn-run module
@&&sqlsn_require sqlsn-run

prompt define action and script
define g_run_action = refresh
define g_run_script = refresh

@&&run_script application/schema/mview/refresh.sql

exit
