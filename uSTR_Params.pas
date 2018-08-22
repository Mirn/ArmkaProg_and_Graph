unit uSTR_Params;

interface
uses SysUtils, Classes, math, registry, windows;

type
 __tstr_from_x_converter = function(data:pointer):string;
 __tstr_to_x_converter   = function(s:string; data:pointer; default:pointer):boolean;

 tstr_param = class
 private
  str_to_x   : __tstr_to_x_converter;
  str_from_x : __tstr_from_x_converter;
  name_cmp   : string;
  name_print : string;
  value      : pointer;
  default    : pointer;
  def_size   : integer;
  next       : tstr_param;

  procedure assign(
    v_str_to_x   : __tstr_to_x_converter;
    v_str_from_x : __tstr_from_x_converter;
    v_name       : string;
    v_value      : pointer;
    v_default    : pointer;
    v_def_size   : integer;
    v_next       : tstr_param);

  class function format_value(s:string):string;
  class function format_name(s:string):string;
  class function str_del_spaces(s:string):String;
  function from_str(find_name:string; new_value:string):boolean;

 public
  constructor nComment(v_comment:string; v_next:tstr_param);
  constructor nDivider(v_next:tstr_param);

  constructor nByte(v_name:string; v_value:pbyte; v_default:byte; v_next:tstr_param);
  constructor nShortInt(v_name:string; v_value:pShortInt; v_default:ShortInt; v_next:tstr_param);
  constructor nWord(v_name:string; v_value:pWord; v_default:word; v_next:tstr_param);
  constructor nSmallInt(v_name:string; v_value:pSmallInt; v_default:SmallInt; v_next:tstr_param);
  constructor nCardinal(v_name:string; v_value:pCardinal; v_default:Cardinal; v_next:tstr_param);
  constructor nInteger(v_name:string; v_value:pInteger; v_default:Integer; v_next:tstr_param);
  constructor nInt64(v_name:string; v_value:pInt64; v_default:Int64; v_next:tstr_param);
  constructor nDouble(v_name:string; v_value:pDouble; v_default:Double; v_next:tstr_param);
  constructor nSingle(v_name:string; v_value:pSingle; v_default:Single; v_next:tstr_param);
  constructor nBool(v_name:string; v_value:pBoolean; v_default:Boolean; v_next:tstr_param);
  constructor nStr(v_name:string; v_value:pstring; v_default:string; v_next:tstr_param);

  constructor nHexByte(v_name:string; v_value:pbyte; v_default:byte; v_next:tstr_param);
  constructor nHexWord(v_name:string; v_value:pWord; v_default:word; v_next:tstr_param);
  constructor nHexCardinal(v_name:string; v_value:pCardinal; v_default:Cardinal; v_next:tstr_param);
  constructor nHexInt64(v_name:string; v_value:pInt64; v_default:Int64; v_next:tstr_param);

  destructor  destroy; override;

  procedure set_default;

  procedure to_strings(list:tstringlist);
  function  to_file(fn:string):boolean;
  function  to_registry(root_key:HKEY; path:string):boolean;
  procedure to_registry_item(reg:tregistry);

  function  from_strings(list:tstringlist):integer;
  function  from_file(fn:string):boolean;
  function  from_registry(root_key:HKEY; path:string):boolean;
 end;

implementation

function str_from_str(data:pointer):string;forward;
function str_from_bool(data:pointer):string;forward;
function str_from_byte(data:pointer):string;forward;
function str_from_shortint(data:pointer):string;forward;
function str_from_word(data:pointer):string;forward;
function str_from_smallint(data:pointer):string;forward;
function str_from_cardinal(data:pointer):string;forward;
function str_from_integer(data:pointer):string;forward;
function str_from_int64(data:pointer):string;forward;
function str_from_double(data:pointer):string;forward;
function str_from_single(data:pointer):string;forward;

function str_from_hex_byte(data:pointer):string;forward;
function str_from_hex_word(data:pointer):string;forward;
function str_from_hex_cardinal(data:pointer):string;forward;
function str_from_hex_int64(data:pointer):string;forward;

function str_to_str(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_bool(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_byte(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_shortint(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_word(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_smallint(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_cardinal(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_integer(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_int64(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_single(s:string; data:pointer; default:pointer):boolean;forward;
function str_to_double(s:string; data:pointer; default:pointer):boolean;forward;

function str_from_str(data:pointer):string;
var
 value : ^string absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := '"'+value^+'"';
end;

function str_from_bool(data:pointer):string;
var
 value : ^boolean absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := BoolToStr(value^, true);
end;

function str_from_byte(data:pointer):string;
var
 value : ^byte absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_shortint(data:pointer):string;
var
 value : ^shortint absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_word(data:pointer):string;
var
 value : ^word absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_smallint(data:pointer):string;
var
 value : ^smallint absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_cardinal(data:pointer):string;
var
 value : ^cardinal absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_integer(data:pointer):string;
var
 value : ^integer absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_int64(data:pointer):string;
var
 value : ^int64 absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := inttostr(value^);
end;

function str_from_double(data:pointer):string;
var
 value : ^double absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := floattostr(value^);
end;

function str_from_single(data:pointer):string;
var
 value : ^single absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := floattostr(value^);
end;


function str_from_hex_byte(data:pointer):string;
var
 value : ^byte absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := '0x'+inttohex(value^, sizeof(value^)*2);
end;

function str_from_hex_word(data:pointer):string;
var
 value : ^word absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := '0x'+inttohex(value^, sizeof(value^)*2);
end;

function str_from_hex_cardinal(data:pointer):string;
var
 value : ^cardinal absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := '0x'+inttohex(value^, sizeof(value^)*2);
end;

function str_from_hex_int64(data:pointer):string;
var
 value : ^int64 absolute data;
begin
 if value = nil then begin  result := ''; exit; end;
 result := '0x'+inttohex(value^, sizeof(value^)*2);
end;

////////////////////////////////////////////////////////////////////////////////

function str_to_str(s:string; data:pointer; default:pointer):boolean;
var
 value : ^string absolute data;
begin
 value^ := s;
 result := true;
end;

function str_to_byte(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = byte;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<0) or (v>255)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_bool(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = boolean;
var
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 if UpperCase(s) = UpperCase('true') then value^  := true  else
 if UpperCase(s) = UpperCase('false') then value^ := false else
 if UpperCase(s) = UpperCase('1') then value^  := true  else
 if UpperCase(s) = UpperCase('0') then value^ := false else
  error := 1;

 if (error <> 0) and (def <> nil) then
  value^ := def^;
 result := error = 0;
end;

function str_to_shortint(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = shortint;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<-128) or (v>127)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_word(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = word;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<0) or (v>$FFFF)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_smallint(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = smallint;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<-$8000) or (v>$7FFF)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_cardinal(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = cardinal;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<0) or (v>$FFFFFFFF)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_integer(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = integer;
var
 v : int64;
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, v, error);
 if ((error <> 0) or (v<-$80000000) or (v>$7FFFFFFF)) and (def <> nil) then
  value^ := def^
 else
  value^ := v;
 result := error = 0;
end;

function str_to_int64(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = int64;
var
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 error : integer;
begin
 error := 0;
 val(s, value^, error);
 if (error <> 0) and (def <> nil) then
  value^ := def^;
 result := error = 0;
end;

function str_to_single(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = single;
var
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 //error : integer;
 v : extended;
 o : extended;
 d : tconv_type;
begin
{ error := 0;
 //val(s, value^, error);
 try
  value^ := StrToFloat(s);
 except
  on Exception : EConvertError do
   error := 1;
 end;
 if (error <> 0) and (def <> nil) then
  value^ := def^;
 result := error = 0;}
 o := value^;
 if def <> nil then
  d := def^
 else
  d := o;
 v := StrToFloatDef(s, d);
 if (v <> o) and ((v > MinSingle) and (v < MaxSingle)) then value^ := v;
 result := true;
end;

function str_to_double(s:string; data:pointer; default:pointer):boolean;
type
 tconv_type = double;
var
 value : ^tconv_type absolute data;
 def   : ^tconv_type absolute default;
 v : extended;
 o : extended;
 d : tconv_type;
begin
// o := sizeof(data^);
 o := value^;
 if def <> nil then
  d := def^
 else
  d := o;
 v := StrToFloatDef(s, d);
 if (v <> o) and ((v > MinDouble) and (v < MaxDouble)) then value^ := v;
 result := true;
end;

  //////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

constructor tstr_param.nComment(v_comment:string; v_next:tstr_param);
begin
 self.assign(nil, nil, '#'+v_comment, nil, nil, 0, v_next);
end;

constructor tstr_param.nDivider(v_next:tstr_param);
begin
 self.assign(nil, nil, '', nil, nil, 0, v_next);
end;

////////////////////////////////////////////////////////////////////////////////

constructor tstr_param.nByte;
var
 p : pbyte;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_byte, str_from_byte, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nShortInt;
var
 p : pShortInt;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_shortint, str_from_ShortInt, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nWord;
var
 p : pWord;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_word, str_from_word, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nSmallInt;
var
 p : pSmallInt;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_SmallInt, str_from_SmallInt, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nCardinal;
var
 p : pCardinal;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_Cardinal, str_from_Cardinal, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nInteger;
var
 p : pInteger;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_integer, str_from_integer, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nInt64(v_name:string; v_value:pInt64; v_default:Int64; v_next:tstr_param);
var
 p : pint64;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_int64, str_from_int64, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nDouble(v_name:string; v_value:pDouble; v_default:Double; v_next:tstr_param);
var
 p : pDouble;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_double, str_from_double, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nSingle(v_name:string; v_value:pSingle; v_default:Single; v_next:tstr_param);
var
 p : pSingle;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_single, str_from_single, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nBool(v_name:string; v_value:pBoolean; v_default:Boolean; v_next:tstr_param);
var
 p : pBoolean;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_bool, str_from_bool, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nStr(v_name:string; v_value:pstring; v_default:string; v_next:tstr_param);
var
 p : pchar;
begin
 getmem(p, length(v_default)+1);
 StrCopy(p, pchar(v_default));
 self.assign(str_to_Str, str_from_str, v_name, v_value, p, sizeof(v_default), v_next);
end;

////////////////////////////////////////////////////////////////////////////////

constructor tstr_param.nHexByte;
var
 p : pbyte;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_byte, str_from_hex_byte, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nHexWord;
var
 p : pWord;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_word, str_from_hex_word, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nHexCardinal;
var
 p : pCardinal;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_Cardinal, str_from_hex_Cardinal, v_name, v_value, p, sizeof(v_default), v_next);
end;

constructor tstr_param.nHexInt64(v_name:string; v_value:pInt64; v_default:Int64; v_next:tstr_param);
var
 p : pint64;
begin
 new(p);
 p^ := v_default;
 self.assign(str_to_int64, str_from_hex_int64, v_name, v_value, p, sizeof(v_default), v_next);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure tstr_param.assign;
begin
 str_to_x   := v_str_to_x;
 str_from_x := v_str_from_x;
 name_cmp   := self.format_name(v_name);
 name_print := v_name;
 value      := v_value;
 default    := v_default;
 def_size   := v_def_size;
 next       := v_next;
end;

destructor tstr_param.destroy;
begin
 if next <> nil then
  FreeAndNil(next);

 if default <> nil then
  Dispose(default);
end;

class function tstr_param.str_del_spaces(s:string):String;
begin
 while (length(s) > 0) and (s[1] in [' ',#9]) do
  delete(s,1,1);
 while (length(s) > 0) and (s[length(s)] in [' ',#9]) do
  delete(s,length(s),1);
 result := s;
end;

class function tstr_param.format_name(s:string):string;
begin
 result := UpperCase(str_del_spaces(s));
end;

class function tstr_param.format_value(s:string):string;
begin
 result := str_del_spaces(s);
 if length(result) < 2 then exit;
 if (result[1]='"') and (result[length(result)]='"') then
  begin
   Delete(result,1,1);
   Delete(result,length(result),1);
  end;
end;

{class function tstr_param.format_name(s:string):string;
var
 a,b,p : integer;
 //test : string;
begin
 //test := UpperCase(str_del_spaces(s));
 result := '';
 if length(s) = 0 then exit;

 a := 1;
 b := length(s);
 while (b > a) and (s[a] in [' ',#9]) do inc(a);
 while (b > a) and (s[b] in [' ',#9]) do dec(b);

 if b < (a+1) then exit;

 p := 1;
 SetLength(result, b-a+1);
 while (b >= a) do
  begin
   result[p] := UpCase(s[a]);
   inc(a);
   inc(p);
  end;
 //assert(test=result, 'test = '+test+#13'result = '+result);
end;

class function tstr_param.format_value(s:string):string;
var
 a,b,p : integer;
begin
 result := '';
 if length(s) = 0 then exit;

 a := 1;
 b := length(s);
 while (b > a) and (s[a] in [' ',#9]) do inc(a);
 while (b > a) and (s[b] in [' ',#9]) do dec(b);

 if b < a then exit;
 if (s[a]='"') and (s[b]='"') then
  begin
   dec(b);
   inc(a);
   if b < a then exit;
  end;

 p := 1;
 SetLength(result, b-a+1);
 while (b >= a) do
  begin
   result[p] := s[a];
   inc(a);
   inc(p);
  end;
end;}

////////////////////////////////////////////////////////////////////////////////

function tstr_param.from_str(find_name:string; new_value:string):boolean;
begin
 if (find_name <> self.name_cmp) or (@str_to_x = nil) or (value = nil) then
  begin
   if next = nil then
    result := false
   else
    result := next.from_str(find_name, new_value);
   exit;
  end;

 result := str_to_x(new_value, self.value, self.default);
end;

function tstr_param.from_strings(list:tstringlist):integer;
var
 k : integer;
 s : string;
 p : integer;
 c : integer;

 v_name  : string;
 v_value : string;
begin
 result := 0;

 for k:=0 to list.Count-1 do
  begin
   s := list.strings[k];
   p := pos('=', s);
   c := pos('#', s);
   if (c > 0) and (c < p)then continue;
   if (p < 2) or (p >= length(s)) then continue;
   v_name  := format_name (copy(s,1,p-1));
   v_value := format_value(copy(s, p+1, length(s)-p));

   if v_name <> '' then
    if self.from_str(v_name, v_value) then
     inc(result);
  end;
end;

procedure tstr_param.to_strings(list:tstringlist);
var
 s:string;
begin
 s := name_print;
 if (@str_from_x <> nil) and (value <> nil) then
  s := s + #9'='#9 + str_from_x(value);

 list.Add(s);

 if next <> nil then
  next.to_strings(list);
end;

procedure tstr_param.set_default;
type
 pstr = ^string;
begin
 if (default <> nil) and (value <> nil) and (def_size > 0) then
  if @str_from_x = @str_from_str then
   pstr(value)^ := pchar(default)
  else
   Move(default^, value^, def_size);

 if next <> nil then
  next.set_default;
end;

function  tstr_param.to_file(fn:string):boolean;
var
 list : tstringlist;
begin
 result := true;
 list := TStringList.Create;
 self.to_strings(list);
 try
  list.SaveToFile(fn);
 except
  result := false
 end;
 FreeAndNil(list);
end;

function  tstr_param.from_file(fn:string):boolean;
var
 list : tstringlist;
begin
 result := FileExists(fn);
 if not result then exit;

 list := TStringList.Create;
 try
  list.LoadFromFile(fn);
  if self.from_strings(list) = 0 then
   result := false;
 except
  result := false
 end;
end;

procedure tstr_param.to_registry_item(reg:tregistry);
begin
 if self = nil then exit;

 if (value <> nil) or (@str_from_x <> nil) then
  reg.WriteString(name_cmp, str_from_x(value));

 if next <> nil then
  next.to_registry_item(reg);
end;

function  tstr_param.to_registry;
var
 reg  : TRegistry;
 list : tstringlist;
begin
 result := false;
 reg  := TRegistry.Create;
 list := TStringList.Create;
 self.to_strings(list);

 try
  reg.RootKey := root_key;
  reg.Access  := KEY_ALL_ACCESS;

  if not reg.OpenKey(path, True) then
   begin
    result := false;
    FreeAndNil(reg);
    FreeAndNil(list);
    exit;
   end;

  to_registry_item(reg);

 except
  if reg <> nil then
   begin
    result := false;
    reg.CloseKey;
    FreeAndNil(reg);
    FreeAndNil(list);
   end;
  exit;
 end;

 reg.CloseKey;
 FreeAndNil(reg);
 FreeAndNil(list);
 result := true;
end;

function  tstr_param.from_registry(root_key:HKEY; path:string):boolean;
var
 reg   : TRegistry;
 list  : tstringlist;
 names : tstringlist;

 k : integer;
begin
 result := false;
 reg   := TRegistry.Create;
 list  := TStringList.Create;
 names := TStringList.Create;

 try
  reg.RootKey := root_key;
  reg.Access  := KEY_READ;

  if not reg.OpenKey(path, false) then
   begin
    result := false;
    FreeAndNil(reg);
    FreeAndNil(list);
    FreeAndNil(names);
    exit;
   end;

  reg.GetValueNames(names);
  for k := 0 to names.Count-1 do
   list.Add(names[k]+'='+reg.ReadString(names[k]));
  self.from_strings(list);

 except
  if reg <> nil then
   begin
    result := false;
    reg.CloseKey;
    FreeAndNil(reg);
    FreeAndNil(list);
    FreeAndNil(names);
   end;
  exit;
 end;

 reg.CloseKey;
 FreeAndNil(reg);
 FreeAndNil(list);
 FreeAndNil(names);
 result := true;
end;

end.
