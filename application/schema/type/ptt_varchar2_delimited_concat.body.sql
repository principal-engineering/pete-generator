create or replace type body ptt_varchar2_delimited_concat is

  static function ODCIAggregateInitialize(ctx in out ptt_varchar2_delimited_concat) return number is
  begin
    ctx := ptt_varchar2_delimited_concat(null);
    return ODCIConst.Success;
  end;

  member function ODCIAggregateIterate
  (
    self  in out ptt_varchar2_delimited_concat,
    value in varchar2
  ) return number is
  begin
    if self.text is null
    then
      self.text := value;
    else
      self.text := self.text || ',' || value;
    end if;
    return ODCIConst.Success;
  end;

  member function ODCIAggregateTerminate
  (
    self        in ptt_varchar2_delimited_concat,
    returnValue out varchar2,
    flags       in number
  ) return number is
  begin
    returnValue := self.text;
    return ODCIConst.Success;
  end;

  member function ODCIAggregateMerge
  (
    self in out ptt_varchar2_delimited_concat,
    ctx2 in ptt_varchar2_delimited_concat
  ) return number is
  begin
    if ctx2.text is null
    then
      null;
    else
      self.text := self.text || ',' || ctx2.text;
    end if;
    return ODCIConst.Success;
  end;

end;
/
