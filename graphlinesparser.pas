unit GraphLinesParser;

interface
uses
 sysutils, math,
 TabNumParser;

const
 GRAPH_CHANNELS = 24;
 GRAPH_CHANNEL_MIN = -$8000;
 GRAPH_CHANNEL_MAX = +$8000;
 GRAPH_GIRD_STEP_X = 1000;
 GRAPH_GIRD_STEP_Y = 1024;

type
 tGraphLines_item = record
  value : integer;
  err : boolean;
 end;

 tGraphLines = array[0 .. GRAPH_CHANNELS-1] of tGraphLines_item;

 tGraphLinesParser_Event = procedure(chanels:tGraphLines) of object;

 tGraphLinesParser=class
 private
  nums_parser : tTabNumParser;
  time_old : cardinal;
  time_valid : boolean;

  procedure evNums(nums:pTabNumParser_array; count:integer; str:pansichar; str_len:integer);
  //function check_nums(nums:pTabNumParser_array; count:integer):boolean;

 public
  onNumsEvent : tTabNumParser_NumsEvent;
  onChanels : tGraphLinesParser_Event;

  stat_errors : integer;
  stat_normals : integer;
  stat_lines : integer;

  constructor create;
  procedure parse(data:pbyte; size:integer);
  procedure reset;
 end;

implementation

constructor tGraphLinesParser.create;
begin
 nums_parser := tTabNumParser.create;
 nums_parser.onNumsEvent := self.evNums;
end;

procedure tGraphLinesParser.reset;
begin
 time_old := 0;
 time_valid := false;
 stat_errors := 0;
 stat_normals := 0;
 nums_parser.reset;
end;

procedure tGraphLinesParser.parse(data:pbyte; size:integer);
begin
 nums_parser.parse(data, size);
end;

{function tGraphLinesParser.check_nums(nums:pTabNumParser_array; count:integer):boolean;
var
 pos : integer;
 new_time : cardinal;

 res_nums_ok : boolean;
 res_range_ok : boolean;
 res_time_ok : boolean;
begin
// result := false;
// if count < (GRAPH_CHANNELS + 1) then
//  exit;

 res_nums_ok := true;
 for pos := 0 to GRAPH_CHANNELS do
   if nums[pos].error > 0 then res_nums_ok := false;;

 res_range_ok := true;
 for pos := 1 to GRAPH_CHANNELS do
  begin
   if nums[pos].value < GRAPH_CHANNEL_MIN then res_range_ok := false;
   if nums[pos].value > GRAPH_CHANNEL_MAX then res_range_ok := false;
  end;

 new_time := nums[0].value;

 res_time_ok := (new_time = (time_old + 1)) or (not time_valid);

 time_valid := res_range_ok and res_nums_ok;
 time_old := new_time;

 result := res_nums_ok and res_range_ok and res_time_ok;

 if result then
  inc(stat_normals)
 else
  inc(stat_errors);
end;}

procedure tGraphLinesParser.evNums(nums:pTabNumParser_array; count:integer; str:pansichar; str_len:integer);
var
 chanels : tGraphLines;
 pos : integer;
begin
 if @onNumsEvent <> nil then
  onNumsEvent(nums, count, str, str_len);

 for pos := 0 to length(chanels)-1 do
  begin
   chanels[pos].value := 0;
   chanels[pos].err := true;
  end;

 if count > length(chanels) then
  count := length(chanels);

 for pos := 0 to count-1 do
  begin
   chanels[pos].value := nums[pos + 0].value;
   chanels[pos].err := nums[pos + 0].error > 0;

   if chanels[pos].err then
    inc(stat_errors)
   else
    inc(stat_normals);
  end;
 inc(stat_lines);

 if @onChanels <> nil then
  onChanels(chanels);
end;

end.
