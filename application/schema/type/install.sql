@&&run_dir_begin

rem needed only for 11.1 compatibility
rem todo: precompiler hints

prompt
prompt Creating type PTT_VARCHAR2_DELIMITED_CONCAT
prompt ===========================================
prompt
@@ptt_varchar2_delimited_concat.spec.sql
prompt
prompt Creating type body PTT_VARCHAR2_DELIMITED_CONCAT
prompt ================================================
prompt
@@ptt_varchar2_delimited_concat.body.sql
prompt
prompt Creating type PTT_VARCHAR2_CONCAT
prompt =================================
prompt
@@ptt_varchar2_concat.spec.sql
prompt
prompt Creating type body PTT_VARCHAR2_CONCAT
prompt ======================================
prompt
@@ptt_varchar2_concat.body.sql

@&&run_dir_end
