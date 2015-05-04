create or replace function ptf_varchar2_delimited_concat(value in varchar2) return varchar2
  aggregate using ptt_varchar2_delimited_concat;
/
