create materialized view ptm_metadata_function_result as
select a.object_name, a.package_name, a.subprogram_id, a.overload
  from user_arguments a
 where position = 0
;

create unique index ptm_metadata_fnc_result_pk 
  on ptm_metadata_function_result(package_name, object_name, subprogram_id)
/
