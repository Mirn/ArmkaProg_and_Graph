unit LineCtrl;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, ExtCtrls, math, dialogs,
  hsv2rgb;

type
 tline_ctrl = class
 private
  bmp : tbitmap;
  paintbox : tpaintbox;
  line_count : integer;
  base_colors : array of cardinal;
  mb_left_state : boolean;
  mb_left_state_valid : boolean;
  old_index : integer;

  pickup_priority : array of integer;
  pickup_set : set of byte;

  procedure onPaintBoxPaint(Sender: TObject);
  procedure onPaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure onPaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure onPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

  procedure recalc_colors;
  procedure recalc_enabled;

 public
  line_names   : array of string;
  line_colors  : array of cardinal;
  line_enabled : array of boolean;
  last_values  : array of integer;
  last_valid   : array of boolean;
  line_marked  : integer;
  color_probe  : cardinal;
  enabled_count: integer;
  enabled_last : integer;

  constructor create(cnt:integer; pbox:tpaintbox);
  destructor dispose;virtual;

  procedure settings_save;
  function  settings_load:boolean;
  procedure settings_default;

  procedure pickup_start;
  function  pickup_add(color:cardinal):boolean;
  function  pickup_end:integer;
 end;


implementation

const
 CONF_FILE = 'ArmkaGraph.lines_config';

constructor tline_ctrl.create(cnt:integer; pbox:tpaintbox);
var
 pos : integer;
begin
 line_count := cnt;

 setlength(base_colors, line_count);
 setlength(line_colors, line_count);
 setlength(line_enabled, line_count);
 setlength(last_values, line_count);
 setlength(last_valid, line_count);
 setlength(pickup_priority, line_count);
 setlength(line_names, line_count);

 line_marked := -1;
 for pos := 0 to line_count - 1 do
  begin
   line_names[pos] := 'Chanel ' + inttostr(pos);
   line_colors[pos] := HSV(pos / length(line_colors), 1, 255);
   base_colors[pos] := line_colors[pos];
   line_enabled[pos] := true;
  end;

 paintbox := pbox;
 paintbox.OnPaint := self.onPaintBoxPaint;
 paintbox.OnMouseDown := self.onPaintBoxMouseDown;
 paintbox.OnMouseMove := self.onPaintBoxMouseMove;
 paintbox.OnMouseUp := self.onPaintBoxMouseUp;

 bmp := TBitmap.Create;
 bmp.Width := paintbox.Width;
 bmp.Height := paintbox.Height;
end;

destructor tline_ctrl.dispose;
begin
 FreeAndNil(bmp);
 setlength(base_colors, 0);
 setlength(line_colors, 0);
 setlength(line_enabled, 0);
 setlength(last_values, 0);
 setlength(last_valid, 0);
 setlength(pickup_priority, 0);
 setlength(line_names, 0);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure tline_ctrl.settings_default;
var
 pos : integer;
begin
 for pos := 0 to line_count - 1 do
  begin
   line_names[pos] := 'Chanel ' + inttostr(pos);
   line_enabled[pos] := true;
  end;
 recalc_enabled;
end;

procedure tline_ctrl.settings_save;
var
 list : tstringlist;
 s : string;
 pos : integer;
begin
 list := TStringList.Create;

 s := '';
 for pos := 0 to line_count - 1 do
  if line_enabled[pos] then
   s := s + '1'
  else
   s := s + '0';
 list.Add(s + ' // Enabled chanels');

 for pos := 0 to line_count - 1 do
  list.Add(line_names[pos]);

 list.SaveToFile(CONF_FILE);
 FreeAndNil(list);
end;

function tline_ctrl.settings_load:boolean;
var
 list : tstringlist;
 s : string;
 pos : integer;
begin
 result := false;
 if not FileExists(CONF_FILE) then
  exit;
  
 list := TStringList.Create;
 list.LoadFromFile(CONF_FILE);
 if list.Count > line_count then
  begin
   s := list.Strings[0];
   if length(s) >= line_count then
    for pos := 0 to line_count - 1 do
     line_enabled[pos] := (s[1 + pos] <> '0');

   for pos := 0 to line_count - 1 do
    line_names[pos] := list.Strings[1 + pos];

   result := true;
   self.recalc_colors;
   self.recalc_enabled;
  end;
 FreeAndNil(list);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure tline_ctrl.recalc_colors;
var
 pos : integer;
 cnt : integer;
 sub : integer;
begin
 cnt := 0;
 for pos := 0 to line_count - 1 do
  if line_enabled[pos] then
   inc(cnt);
 enabled_count := cnt;

 sub := 0;
 for pos := 0 to line_count - 1 do
  if line_enabled[pos] then
   begin
    line_colors[pos] := HSV(sub / cnt, 1, 255);
    base_colors[pos] := line_colors[pos];
    inc(sub);
   end;
end;

procedure tline_ctrl.onPaintBoxPaint(Sender: TObject);
var
 pos : integer;
begin
 bmp.Canvas.Pen.style := psclear;
 bmp.Canvas.Brush.style := bssolid;
 bmp.Canvas.Brush.Color := rgb(0,0,0);
 bmp.Canvas.Rectangle(0,0, bmp.Width + 1, bmp.Height + 1);

 bmp.Canvas.Pen.style := psSolid;
 bmp.Canvas.Font.Name := 'MS Sans Serif';
 bmp.Canvas.Font.Size := 8;
 bmp.Canvas.Font.Style := [];

 for pos := 0 to length(line_colors) - 1 do
  begin
   bmp.Canvas.Font.Style := [];

   if line_enabled[pos] then
    bmp.Canvas.Font.Color := line_colors[pos]
   else
    begin
     bmp.Canvas.Font.Color := rgb(64, 64, 64);
     if line_marked = pos then
      line_marked := -1;
    end;

   if pos = line_marked then
    begin
     bmp.Canvas.Font.Style := [fsbold];
     bmp.Canvas.Font.Color := rgb(255, 255, 255);
    end;

   bmp.Canvas.TextOut(0, pos * 13, line_names[pos]);
   if last_valid[pos] then
    begin
     if line_enabled[pos] then
      bmp.Canvas.Font.Color := color_probe
     else
      bmp.Canvas.Font.Color := rgb(70,70,70);
     bmp.Canvas.TextOut(60, pos * 13, inttostr(last_values[pos]));
    end;
  end;

 paintbox.Canvas.Draw(0,0, bmp);
end;

procedure tLine_Ctrl.onPaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 index : integer;
begin
 index := y div 13;
 if (index < 0) or (index >= length(line_colors)) then exit;

 if Button = mbright then
  begin
   line_enabled[index] := not line_enabled[index];
   mb_left_state := line_enabled[index];
   mb_left_state_valid := true;
   recalc_enabled;
  end;

 if button = mbmiddle then
  begin
   line_names[index] := InputBox('Chanel name', 'Name:', line_names[index]);
   PaintBox.Repaint;
  end;

 if Button = mbleft then
  begin
   if line_enabled[index] then
    begin
     if line_marked = index then
      line_marked := -1
     else
      line_marked := index;
    end;
  end;

 recalc_colors;
 PaintBox.Repaint;
 old_index := index;
end;

procedure tLine_Ctrl.onPaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 index : integer;
begin
 index := y div 13;
 if (index < 0) or (index >= length(line_colors)) then exit;

 if Button = mbright then
  mb_left_state_valid := false;
end;

procedure tLine_Ctrl.onPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
 index : integer;
begin
 index := y div 13;
 if (index < 0) or (index >= length(line_colors)) then
  exit;

// if ssLeft in shift then
//  line_marked := index;

 if ssRight in shift then
  if mb_left_state_valid then
   begin
    while old_index <> index do
     begin
      line_enabled[old_index] := mb_left_state;
      if index > old_index then inc(old_index);
      if index < old_index then dec(old_index);
     end;
    line_enabled[old_index] := mb_left_state;
   end;

 recalc_enabled;
 recalc_colors;
 PaintBox.Repaint;
end;

procedure tLine_Ctrl.pickup_start;
begin
 pickup_set := [];
end;

function tLine_Ctrl.pickup_add(color:cardinal):boolean;
var
 pos : integer;
begin
 for pos := 0 to line_count - 1 do
  if line_enabled[pos] then
   if line_colors[pos] = color then
    begin
     pickup_set := pickup_set + [pos];
     result := true;
     exit;
    end;
 result := false;
end;

function tLine_Ctrl.pickup_end:integer;
var
 pos : integer;
 idx : integer;
 val : integer;
begin
 for pos := 0 to line_count - 1 do
  pickup_priority[pos] := math.Min(line_count-1, pickup_priority[pos] + 1);

 result := -1;
 idx := -1;
 val := -1;

 for pos := 0 to line_count - 1 do
  if pos in pickup_set then
   if val < pickup_priority[pos] then
    begin
     idx := pos;
     val := pickup_priority[pos];
    end;

 if idx < 0 then
  begin
   line_marked := -1;
   exit;
  end;

 pickup_priority[idx] := 0;
 result := idx;
 line_marked := idx;
end;

procedure tLine_Ctrl.recalc_enabled;
var
 pos : integer;
begin
 enabled_count := 0;

 for pos := 0 to line_count - 1 do
  if line_enabled[pos] then
   begin
    enabled_last := pos;
    inc(enabled_count);
   end;
end;

end.
