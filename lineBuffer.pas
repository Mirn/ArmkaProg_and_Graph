unit LineBuffer;

interface
uses
 sysutils, math, windows, classes;

const
 LINE_BUFFER_SIZE = $20000;

type
 pLineBuffer_info = ^tLineBuffer_info;
 tLineBuffer_info = record
  bottom : integer;
  top    : integer;
 end;

 pLineBuffer_item = ^tLineBuffer_item;
 tLineBuffer_item = record
  info : pLineBuffer_info;
  value : integer;
 end;

 tLineItem_stat = record
  min : double;
  max : double;
  cnt : integer;
 end;

 tLineItems_doubles = array of double;
 tLineItems_integers = array of tLineBuffer_item;

 tLineBuffer = class
 private
  main_data : array[0 .. LINE_BUFFER_SIZE - 1] of tLineBuffer_item;
  main_size : integer;

  temp_buf : array[0 .. (LINE_BUFFER_SIZE div 8) - 1] of tLineBuffer_item;
  temp_cnt : integer;

  refreshed_cnt : int64;

 public
  stat_normal : integer;
  stat_error : integer;
  stat_total : integer;

  stat_last_value : integer;
  stat_last_valid : boolean;
  stat_avrg_sum : int64;
  stat_avrg_cnt : integer;

  memfree_mode : boolean;

  constructor create;
  procedure reset;

  function calc_ofs(pos_x:integer; ofs_x, scale_x:integer):integer;
  function get_value_avrg(x:integer; ofs_x, scale_x:integer; var valid:boolean):double;
  function get_value_stat(x:integer; ofs_x, scale_x:integer):tLineItem_stat;
  function read_y_avrg(x:integer; ofs_x, scale_x:integer; scale_y:int64; y_amp:integer; y_ofs:integer; var valid:boolean):integer;
  function read_y_stat(x:integer; ofs_x, scale_x:integer; scale_y:int64; y_amp:integer; y_ofs:integer):tLineItem_stat;
  function calc_y(y:double; scale_y:integer; y_amp:integer; y_ofs:integer):integer;

  procedure add(value:integer; err:boolean);
  procedure refresh;

  function import_strings(x1, x2:integer; ofs_x, scale_x:integer):tstringlist;
  function import_doubles(x1, x2:integer; ofs_x, scale_x:integer):tLineItems_doubles;
  function import_integers(x1, x2:integer; ofs_x, scale_x:integer):tLineItems_integers;

  property stat_total_counter:int64 read refreshed_cnt;
  procedure stat_avrg_read_reset(var result:integer; var valid:boolean);
  procedure stat_last_read_reset(var result:integer; var valid:boolean);
 end;


implementation
uses
 graphlinesparser;

const
 dummy_info : tLineBuffer_info = (bottom:0; top:1);

constructor tLineBuffer.create;
begin
 self.reset;
end;

procedure tLineBuffer.reset;
begin
 temp_cnt := 0;
 ZeroMemory(@temp_buf[0], sizeof(temp_buf));

 main_size := 0;
 ZeroMemory(@main_data[0], sizeof(main_data));

 refreshed_cnt := 0;
end;

procedure tLineBuffer.stat_avrg_read_reset(var result:integer; var valid:boolean);
begin
 valid := stat_avrg_cnt > 0;
 if valid then
  result := round(stat_avrg_sum / stat_avrg_cnt)
 else
  result := 0;

 stat_avrg_sum := 0;
 stat_avrg_cnt := 0;
end;

procedure tLineBuffer.stat_last_read_reset(var result:integer; var valid:boolean);
begin
 result := stat_last_value;
 valid := stat_last_valid;
 stat_last_value := 0;
 stat_last_valid := false;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure tLineBuffer.add(value:integer; err:boolean);
begin
 if temp_cnt >= Length(temp_buf) then
  begin
   if memfree_mode then
    FreeMemory(pointer(value));
   exit;
  end;

 temp_buf[temp_cnt].value := value;

 if err then
  begin
   temp_buf[temp_cnt].info := nil;
   inc(stat_error);
  end
 else
  begin
   stat_last_valid := true;
   stat_last_value := value;
   stat_avrg_sum := stat_avrg_sum + value;
   inc(stat_avrg_cnt);

   temp_buf[temp_cnt].info := @dummy_info;
   inc(stat_normal);
  end;

 inc(temp_cnt);
 inc(stat_total);
end;

procedure tLineBuffer.refresh;
var
 pos : integer;
begin
 if temp_cnt <= 0 then
  exit;

 if memfree_mode then
  begin
   for pos := 0 to temp_cnt - 1 do
    if main_data[pos].value <> 0 then
     FreeMemory(pointer(main_data[pos].value));
  end;

 move(main_data[temp_cnt], main_data[0], (length(main_data) - temp_cnt) * sizeof(main_data[0]));
 move(temp_buf[0], main_data[length(main_data) - temp_cnt], (temp_cnt * sizeof(temp_buf[0])));

 main_size := main_size + temp_cnt;
 main_size := math.Min(length(main_data), main_size);
 refreshed_cnt := refreshed_cnt + temp_cnt;

 temp_cnt := 0;
end;

function tLineBuffer.import_strings(x1, x2:integer; ofs_x, scale_x:integer):tstringlist;
var
 index_x1 : integer;
 index_x2 : integer;
 index_a : integer;
 index_b : integer;
 list : tstringlist;
 pos : integer;
 str : string;
begin
 index_x1 := length(main_data) - 1 - calc_ofs(x1, ofs_x, scale_x);
 index_x2 := length(main_data) - 1 - calc_ofs(x2, ofs_x, scale_x);

 index_a := math.Min(index_x1, index_x2);
 index_b := math.Max(index_x1, index_x2);

 index_a := math.Min(index_a, length(main_data) - 1);
 index_b := math.Min(index_b, length(main_data) - 1);

 index_a := math.Max(index_a, 0);
 index_b := math.Max(index_b, 0);

 list := tstringlist.create;
 pos := index_a;
 while pos <= index_b do
  begin
   if main_data[pos].value <> 0 then
    begin
     str := pansichar(main_data[pos].value);
     list.Add(str);
    end;
   inc(pos);
  end;
 result := list;
end;

function tLineBuffer.import_doubles(x1, x2:integer; ofs_x, scale_x:integer):tLineItems_doubles;
var
 index_x1 : integer;
 index_x2 : integer;
 index_a : integer;
 index_b : integer;
 pos : integer;
 cnt : integer;
begin
 index_x1 := length(main_data) - 1 - calc_ofs(x1, ofs_x, scale_x);
 index_x2 := length(main_data) - 1 - calc_ofs(x2, ofs_x, scale_x);

 index_a := math.Min(index_x1, index_x2);
 index_b := math.Max(index_x1, index_x2);

 index_a := math.Min(index_a, length(main_data) - 1);
 index_b := math.Min(index_b, length(main_data) - 1);

 index_a := math.Max(index_a, 0);
 index_b := math.Max(index_b, 0);

 cnt := 0;
 pos := index_a;
 SetLength(result, index_b - index_a);
 while pos < index_b do
  begin
   if main_data[pos].info <> nil then
    begin
     result[cnt] := main_data[pos].value;
     inc(cnt);
    end;
   inc(pos);
  end;
 SetLength(result, cnt);
end;

function tLineBuffer.import_integers(x1, x2:integer; ofs_x, scale_x:integer):tLineItems_integers;
var
 index_x1 : integer;
 index_x2 : integer;
 index_a : integer;
 index_b : integer;
 pos : integer;
 cnt : integer;
begin
 index_x1 := length(main_data) - 1 - calc_ofs(x1, ofs_x, scale_x);
 index_x2 := length(main_data) - 1 - calc_ofs(x2, ofs_x, scale_x);

 index_a := math.Min(index_x1, index_x2);
 index_b := math.Max(index_x1, index_x2);

 index_a := math.Min(index_a, length(main_data) - 1);
 index_b := math.Min(index_b, length(main_data) - 1);

 index_a := math.Max(index_a, 0);
 index_b := math.Max(index_b, 0);

 cnt := 0;
 pos := index_a;
 SetLength(result, index_b - index_a);
 while pos < index_b do
  begin
   if main_data[pos].info <> nil then
    begin
     result[cnt] := main_data[pos];
     inc(cnt);
    end;
   inc(pos);
  end;
 SetLength(result, cnt);
end;

function tLineBuffer.calc_ofs(pos_x:integer; ofs_x, scale_x:integer):integer;
var
 glitch_correct : integer;
begin
 ofs_x := (ofs_x div scale_x) * scale_x;
 ofs_x := length(main_data) - 1 - ofs_x;
 glitch_correct := stat_total_counter mod scale_x;
 ofs_x := ofs_x + (pos_x * scale_x) + glitch_correct;
 result := ofs_x;
end;

function tLineBuffer.get_value_avrg(x:integer; ofs_x, scale_x:integer; var valid:boolean):double;
var
 sum : int64;
 cnt : integer;
 pos : integer;
 index : integer;
 v : integer;
 item : pLineBuffer_item;
begin
 sum := 0;
 cnt := 0;

 index := calc_ofs(x, ofs_x, scale_x);

 for pos := 0 to scale_x - 1 do
  begin
   item := @main_data[length(main_data) - 1 - index];
   inc(index);
   if (index >= 0) and (index < main_size) and (item^.info <> nil) then
    begin
     v := item^.value;
     sum := sum + v;
     inc(cnt);
    end;
  end;

 if cnt = 0 then
  begin
   valid := false;
   result := 0;
   exit;
  end;

 valid := true;
 result := sum / cnt;
end;

function tLineBuffer.get_value_stat(x:integer; ofs_x, scale_x:integer):tLineItem_stat;
var
 pos : integer;
 index : integer;
 v : integer;
 item : pLineBuffer_item;
begin
 result.cnt := 0;
 result.min := GRAPH_CHANNEL_MAX;
 result.max := GRAPH_CHANNEL_MIN;

 index := calc_ofs(x, ofs_x, scale_x);

 for pos := 0 to scale_x - 1 do
  begin
   item := @main_data[length(main_data) - 1 - index];
   inc(index);
   if (index >= 0) and (index < main_size) and (item^.info <> nil) then
    begin
     v := item^.value;
     result.min := math.Min(result.min, v);
     result.max := math.Max(result.max, v);
     inc(result.cnt);
    end;
  end;
end;

function tLineBuffer.read_y_avrg(x:integer; ofs_x, scale_x:integer; scale_y:int64; y_amp:integer; y_ofs:integer; var valid:boolean):integer;
var
 value : double;
begin
 result := 0;
 value := get_value_avrg(x, ofs_x, scale_x, valid);
 if not valid then
  exit;

 result := calc_y(value, scale_y, y_amp, y_ofs);
end;

function tLineBuffer.read_y_stat(x:integer; ofs_x, scale_x:integer; scale_y:int64; y_amp:integer; y_ofs:integer):tLineItem_stat;
begin
 result := get_value_stat(x, ofs_x, scale_x);
 if result.cnt <= 0 then
  exit;

 result.Min := calc_y(result.min, scale_y, y_amp, y_ofs);
 result.max := calc_y(result.max, scale_y, y_amp, y_ofs);
end;

function tLineBuffer.calc_y(y:double; scale_y:integer; y_amp:integer; y_ofs:integer):integer;
begin
// if y_amp > 1 then
  y :=  ((y - y_ofs) * y_amp) + y_ofs;

 result := scale_y - round((y - GRAPH_CHANNEL_MIN)  * scale_y / (GRAPH_CHANNEL_MAX - GRAPH_CHANNEL_MIN));
end;

end.
