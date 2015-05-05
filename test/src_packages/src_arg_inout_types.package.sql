create or replace package src_arg_inout_types as

    --package with various inout type combinations
    procedure overload(a_in in varchar2);

    procedure overload(a_in in number);

    procedure overload(a_inout in out integer);

    function overload return integer;

    function overload(a_in in integer, a_out out integer) return integer;

end;
/
create or replace package body src_arg_inout_types as

    procedure overload(a_in in varchar2) is
    begin
        null;
    end;

    procedure overload(a_in in number) is
    begin
        null;
    end;

    procedure overload(a_inout in out integer) is
    begin
        null;
    end;

    function overload return integer is
    begin
        return 42;
    end;

    function overload(a_in in integer, a_out out integer) return integer is
    begin
        a_out := a_in;
        return a_in;
    end;

end;
/
