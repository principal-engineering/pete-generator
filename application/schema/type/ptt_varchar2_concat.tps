create or replace type ptt_varchar2_concat as object
(
  text varchar2(4000),
  static function ODCIAggregateInitialize(ctx in out ptt_varchar2_concat) return number,

  member function ODCIAggregateIterate
  (
    self  in out ptt_varchar2_concat,
    value in varchar2
  ) return number,

  member function ODCIAggregateTerminate
  (
    self        in ptt_varchar2_concat,
    returnValue out varchar2,
    flags       in number
  ) return number,

  member function ODCIAggregateMerge
  (
    self in out ptt_varchar2_concat,
    ctx2 in ptt_varchar2_concat
  ) return number
)
/
