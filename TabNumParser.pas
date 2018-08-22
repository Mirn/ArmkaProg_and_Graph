unit TabNumParser;

interface
uses sysutils, math;

type
 tTabNumParser_num = record
  str : pansichar;
  value : integer;
  error : integer;
 end;
 tTabNumParser_array = array [0..31] of tTabNumParser_num;
 pTabNumParser_array = ^tTabNumParser_array;

 tTabNumParser_NumsEvent = procedure(nums:pTabNumParser_array; count:integer; str:pansichar; str_len:integer) of object;

 tTabNumParser=class
 private
  //str : String[255];
  num : integer;
  err : integer;
  pos : integer;
  neg : integer;

  nums : tTabNumParser_array;
  count : integer;
  old_char : byte;

  buf : array[0 .. $10000] of ansichar;
  buf_size : integer;
  start_num : pansichar;
  start_line : pansichar;

  procedure parse_block(data:pbyte; size:integer);
  procedure num_start;
  procedure num_parse(c:byte);
  procedure num_next(s:pansichar);
 public
  onNumsEvent : tTabNumParser_NumsEvent;

  constructor create(NumsEvent:tTabNumParser_NumsEvent = nil);
  procedure parse(data:pbyte; size:integer);
  procedure reset;
 end;

implementation

constructor tTabNumParser.create;
begin
 onNumsEvent := NumsEvent;
 self.reset;
end;

procedure tTabNumParser.reset;
begin
 num_start;
 start_num  := @buf[0];
 start_line := @buf[0];
end;

procedure tTabNumParser.num_start;
begin
 err := 0;
 num := 0;
 pos := 0;
 neg := 1;
end;

procedure tTabNumParser.num_next(s:pansichar);
begin
 nums[count].value := num * neg;
 nums[count].error := err;
 nums[count].str := s;

 if (pos = 0) then
  nums[count].error := 1;
 inc(count);
 num_start;
end;
 
procedure tTabNumParser.num_parse(c:byte);
begin
 if err > 0 then exit;
 if pos = 0 then
  begin
   if (c = ord(' ')) then exit;
   if (c = ord('-')) then
    begin
     neg := -1;
     exit;
    end;
  end;

 c := c - ord('0');
 if c > 9 then
  begin
   err := 1;
   exit;
  end;
 num := num * 10 + c;
 inc(pos);
end;

procedure tTabNumParser.parse_block(data:pbyte; size:integer);
var
 new_char : byte;
begin

 while size > 0 do
  begin
   new_char := data^;
   inc(data);
   dec(size);

   if (new_char = 10) and (old_char = 13) then
    begin
     old_char := 0;
     continue;
    end;

   if (new_char = 13) and (old_char = 10) then
    begin
     old_char := 0;
     continue;
    end;

   if ((new_char = 10) and (old_char <> 13)) or
      ((new_char = 13) and (old_char <> 10)) then
    begin
     if (count < length(nums)) then
      begin
       //Val(str, nums[count].value, nums[count].error); //str := '';
       num_next(start_num);
       dec(data);
       data^ := 0;
       inc(data);
       start_num := pansichar(data);
      end;
     if @onNumsEvent <> nil then
      onNumsEvent(@nums[0], count, start_line, cardinal(data) - cardinal(start_line));
     start_line := pansichar(data);
     count := 0;
    end
   else
    if (new_char >= 32) or (new_char = 9) then
     //if length(str) < 255 then
      begin
       if new_char <> 9 then
        begin
         //str[0] := char(ord(str[0]) + 1);
         //str[ord(str[0])] := ansichar(new_char);
         num_parse(new_char);
        end
       else
        if (count < length(nums)) then
         begin
          //Val(str, nums[count].value, nums[count].error);
          //str := '';
          num_next(start_num);
          dec(data);
          data^ := 0;
          inc(data);
          start_num := pansichar(data);
         end;
      end;

   old_char := new_char;
  end;
end;

procedure tTabNumParser.parse(data:pbyte; size:integer);
var
 addr_buf : cardinal;
 index_line : integer;
 index_num : integer;

 shift_size : integer;
 add_size : integer;
begin
 while size > 0 do
  begin
   addr_buf := cardinal(@buf);
   index_num := cardinal(start_num) - addr_buf;
   index_line := cardinal(start_line) - addr_buf;

   shift_size := math.min(index_num, index_line);

   if buf_size > shift_size then
    move(buf[shift_size], buf[0], buf_size - shift_size);

   dec(buf_size, shift_size);
   dec(start_num, shift_size);
   dec(start_line, shift_size);

   add_size := math.min(length(buf) - buf_size, size);
   if add_size = 0 then break;
   move(data^, buf[buf_size], add_size);
   inc(data, add_size);
   dec(size, add_size);

   parse_block(@(buf[buf_size]), add_size);
   inc(buf_size, add_size);
  end;
end;

end.
