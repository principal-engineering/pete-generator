create or replace package src_overloads as

    procedure other_overload(a_in in number);
    procedure other_overload(a_in in varchar2);

    --package with various overload types - generator should handle them all


    procedure overload(a_in in varchar2);

    procedure overload(a_in in number);

    procedure overload(a_inout in out integer);

    function overload return integer;

end;
/
create or replace package body src_overloads as

    procedure other_overload(a_in in varchar2) is
    begin
        null;
    end;

    procedure other_overload(a_in in number) is
    begin
        null;
    end;

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

end;
