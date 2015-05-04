create materialized view ptm_metadata_mtds_wth_rec_arg as
select object_name as method_name,
       nvl(package_name, 'USERPROCS') as package_name,
       overload,
       subprogram_id
  from user_arguments
 where data_type = 'PL/SQL RECORD'
;

create index ptm_metadata_mtdswthrecarg_in1 on
ptm_metadata_mtds_wth_rec_arg(package_name, method_name, subprogram_id)
;
