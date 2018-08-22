unit uSimple_speed;

interface

uses
  SysUtils, windows;

type
 tSimple_speed = class
 private
  stat_readed : int64;
  stat_time_old : int64;
  stat_time_read : int64;
  stat_readed_reset : boolean;

 public
  constructor create;
  procedure add_value(value:integer);
  function read_reset:double;
 end;

implementation

constructor tSimple_speed.create;
begin
 QueryPerformanceCounter(stat_time_old);
end;

procedure tSimple_speed.add_value(value:integer);
var
 t : int64;
begin
 QueryPerformanceCounter(t);
 if stat_readed_reset then
  begin
   stat_readed := 0;
   stat_time_read := 0;
  end;
 inc(stat_readed, value);
 stat_time_read := stat_time_read + (t - stat_time_old);
 stat_time_old := t;
end;

function tSimple_speed.read_reset:double;
var
 freq : int64;
 spd : double;
begin
 QueryPerformanceFrequency(freq);
 spd := stat_time_read / freq;
 if spd > 0 then
  spd := round(stat_readed / spd)
 else
  spd := 0;
 stat_readed_reset := true;
 result := spd;
end;

end.
