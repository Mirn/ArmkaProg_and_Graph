unit uLog_Viewer;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, math, AppEvnts, menus,
  //uMAP_debug_log,
  u_millesecond_timer;

type
 tLog_Viewer = class;
 tLog_Viewer_onCopy = procedure(sender:tLog_Viewer; var str:string; pos:integer) of object;
 tLog_Viewer_onString = procedure(sender:tLog_Viewer; str:string; pos:integer) of object;
 tLog_Viewer_onEvent = procedure(sender:tLog_Viewer) of object;
 tLog_Viewer_onString_Draw = procedure(sender:tLog_Viewer; str:string; pos:integer; font:TFont; brush:TBrush) of object;

 tLog_Viewer = class
 private
  menu : TPopupMenu;
  menu_item_copy : TMenuItem;
  menu_item_stat : TMenuItem;

  bitmap : TBitmap;

  view_size : TPoint;
  draw_size : TPoint;
  char_size : TPoint;

  text : TStringList;
  text_update_cnt : integer;

  update_time : cardinal;
  scroll_time : cardinal;

  paint_box : TPaintBox;
  ApplicationEvents : tApplicationEvents;

  index : array of tpoint;

  //debug_log : tMAP_debug_main;

  sel_start : tpoint;
  sel_run : boolean;

  select_from : tpoint;
  select_to : tpoint;

  old_message_event : TMessageEvent;

  smooth_speed_need : double;
  smooth_speed_curr : double;
  smooth_timer : tmillisecond_timer;
  smooth_update_cnt : integer;

  last_chars : integer;
  last_strings  : integer;
  last_end_char : char;

  function sel_from:tpoint;
  function sel_to:tpoint;
  procedure point_sel_correct(var p:tpoint);
  procedure select_all;
  procedure select_none;

  procedure string_style(str:string; font:tfont; brush:TBrush);

  procedure bitmap_rebuild;
  procedure view_size_update;
  procedure draw_size_update;
  procedure scroll_bar_update;

  procedure onMenuCopy(Sender: TObject);
  procedure onMenuStat(Sender: TObject);
  procedure onChange_Y(sender:tobject);
  procedure onChange_X(sender:tobject);
  procedure onPaint(Sender: TObject);
  procedure onMouseDown(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
  procedure onMouseMove(Sender:TObject; Shift:TShiftState; X,Y:Integer);
  procedure onMouseUp(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
  procedure onWinMSG(var Msg: tagMSG; var Handled: Boolean);

  procedure draw_raw(dx,dy:integer);

  function scr2pos(x,y:integer):tpoint;

  function check_script(text:string; var color_b:cardinal; var color_f:cardinal; var style:TFontStyles):boolean;

 public
  scroll_bar_y : TScrollBar;
  scroll_bar_x : TScrollBar;

  auto_update_scroll : boolean;
  auto_scroll_smooth : boolean;

  char_top_limit : word;

  bkcolor_enabled  : tcolor;
  bkcolor_disabled : tcolor;

  onString : tLog_Viewer_onString;
  onReset : tLog_Viewer_onEvent;

  onDraw_begin : tLog_Viewer_onEvent;
  onDraw_string : tLog_Viewer_onString;
  onDraw_control : tLog_Viewer_onString_Draw;
  onDraw_end : tLog_Viewer_onEvent;

  onMenu_Stat : tLog_Viewer_onString;
  onMenu_Copy : tLog_Viewer_onCopy;

  font_color_normal : cardinal;
  font_color_ok : cardinal;
  font_color_error : cardinal;

  colors_script : tstringlist;
  colors_script_fname : string;

  constructor create(paint:TPaintBox; app_events:TApplicationEvents; stat_feature:boolean = false);
  destructor destroy;override;
  procedure text_update(text:pchar; count:integer; new_text:boolean = false);

  procedure redraw;

  procedure onResize(Sender:tobject);
  procedure onTimer(Sender:tobject);

  procedure select_lines(line_from, line_to:integer; repaint:boolean = true);

  property get_char_size:TPoint read char_size;
 end;

procedure clipboard_write(format:cardinal; s:widestring);

implementation

procedure _inf(var v);
begin
end;

procedure ctrl_chars_to_space(var str:string);
var
 pos : integer;
begin
 for pos := 1 to length(str) do
  if ord(str[pos]) < 32 then
   str[pos] := ' ';
end;

function remove_code8(str:string):string;
var
 i_pos : integer;
 o_cnt : integer;
begin
 if length(str) = 0 then
  begin
   result := '';
   exit;
  end;

 SetLength(result, length(str));
 ZeroMemory(@result[1], length(str));

 o_cnt := 1;
 for i_pos := 1 to length(str) do
  if str[i_pos] <> #8 then
   begin
    result[o_cnt] := str[i_pos];
    inc(o_cnt);
   end;
 SetLength(result, o_cnt-1);
end;

constructor tLog_Viewer.create(paint:TPaintBox; app_events : TApplicationEvents; stat_feature:boolean = false);
begin
 bkcolor_enabled  := rgb(255, 255, 255);
 bkcolor_disabled := rgb(240, 250, 240);

 font_color_normal := rgb(  0,   0,   0);
 font_color_ok     := rgb(  0,   0, 100);
 font_color_error  := rgb(100,   0,   0);

 paint_box  := paint;
 paint_box.OnPaint := self.onPaint;
 paint_box.OnMouseDown := self.onMouseDown;
 paint_box.OnMouseMove := self.onMouseMove;
 paint_box.OnMouseUp := self.onMouseUp;

 paint_box.Height := paint_box.Height - 17;
 paint_box.Width := paint_box.Width - 17;

 scroll_bar_x := tscrollbar.Create(nil);
 scroll_bar_x.Parent  := paint_box.Parent;
 scroll_bar_x.Visible := true;
 scroll_bar_x.Kind   := sbHorizontal;
 scroll_bar_x.left   := paint_box.left;
 scroll_bar_x.top    := paint_box.top + paint_box.Height;
 scroll_bar_x.width  := paint_box.width;
 scroll_bar_x.Height := 17;
 scroll_bar_x.Anchors := [akLeft];
 if akbottom in  paint_box.Anchors then
  scroll_bar_x.Anchors := scroll_bar_x.Anchors + [akbottom]
 else
  scroll_bar_x.Anchors := scroll_bar_x.Anchors + [aktop];
 if akright in  paint_box.Anchors then
  scroll_bar_x.Anchors := scroll_bar_x.Anchors + [akright];
 scroll_bar_x.OnChange := self.onChange_X;

 scroll_bar_y := tscrollbar.Create(nil);
 scroll_bar_y.Parent  := paint_box.Parent;
 scroll_bar_y.Visible := true;
 scroll_bar_y.Kind   := sbVertical;
 scroll_bar_y.left   := paint_box.left + paint_box.width;
 scroll_bar_y.top    := paint_box.top;
 scroll_bar_y.Width  := 17;
 scroll_bar_y.Height := paint_box.Height;

 scroll_bar_y.Anchors := [akTop];
 if akright in  paint_box.Anchors then
  scroll_bar_y.Anchors := scroll_bar_y.Anchors + [akright]
 else
  scroll_bar_y.Anchors := scroll_bar_y.Anchors + [akleft];
 if akbottom in  paint_box.Anchors then
  scroll_bar_y.Anchors := scroll_bar_y.Anchors + [akbottom];

 scroll_bar_y.OnChange := self.onChange_Y;

 ApplicationEvents := app_events;
 old_message_event := ApplicationEvents.OnMessage;
 ApplicationEvents.OnMessage := self.onWinMSG;

 view_size_update;
 draw_size_update;

 text := TStringList.Create;

 paint_box.Repaint;

 menu := TPopupMenu.Create(paint_box.Owner);

 menu_item_copy := TMenuItem.create(menu);
 menu_item_copy.Caption := 'Copy to clipboard';
 menu_item_copy.Default := true;
 menu_item_copy.OnClick := self.onMenuCopy;
 menu.Items.Add(menu_item_copy);

 if stat_feature then
  begin
   menu_item_stat := TMenuItem.create(menu);
   menu_item_stat.Caption := 'Report by selected key';
   menu_item_stat.Default := false;
   menu_item_stat.OnClick := self.onMenuStat;
   menu.Items.Add(menu_item_stat);
  end;

 //debug_log := tMAP_debug_main.create(self.ClassName, '', nil);
 //debug_log.create_log;

 char_top_limit := 256;

 milliseconds_start(smooth_timer);

 colors_script := TStringList.create();
end;

destructor tLog_Viewer.destroy;
begin
 //FreeAndNil(debug_log);
 FreeAndNil(menu_item_copy);
 FreeAndNil(menu_item_stat);
 FreeAndNil(menu);
 FreeAndNil(bitmap);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure tLog_Viewer.text_update(text:pchar; count:integer; new_text:boolean = false);
var
 old : integer;
 val : integer;
 cur_buf  : pchar;
 buffer   : pchar;
 buf_size : integer;

 str : string;
 pos : integer;
 column : integer;

 old_y_pos : integer;
 old_y_max : integer;

 new_end_char : char;
 new_chars : integer;

  function next_text:char;
  begin
   result := text^;
   dec(count);
   inc(text);
  end;

  procedure next_buf(v:char);
  begin
   cur_buf^ := v;
   inc(cur_buf);
   inc(column);
  end;

  procedure next_buf_num(v:char);
  var
   s : string;
  begin
   s := inttohex(ord(v), 2);
   next_buf('<');
   next_buf(s[1]);
   next_buf(s[2]);
   next_buf('>');
  end;

  procedure next_line_process(cr_ln:integer);
  begin
   if old = cr_ln then
    begin
     next_text;
     val := 0;
    end
   else
    next_buf(next_text);
   column := 0;
  end;

  procedure next_tab_process;
  begin
   if (column mod 8 = 0) and (column <> 0) then
    begin
     next_buf(#9);
     next_text;
    end
   else
    next_buf(#8);
  end;

begin
 new_chars := count;

 old_y_pos := scroll_bar_y.Position;
 old_y_max := scroll_bar_y.Max;

 if count < 2000000 then
  buf_size := sizeof(char) * (count*8 + 1)
 else
  buf_size := sizeof(char) * (count*4 + 1);

 buffer := GetMemory(buf_size);
 if buffer = nil then exit;
 ZeroMemory(buffer, buf_size);

 val := 0;
 old := 0;
 column := 0;
 cur_buf := buffer;
 if text <> nil then
  while (count > 0) and ((cardinal(cur_buf) - cardinal(buffer)) < (buf_size-10)) do
   begin
    old := val;
    val := ord(text^);
    
    if val > char_top_limit then next_buf_num(next_text) else
    if val >= 32 then next_buf(next_text) else
    if val = 10 then next_line_process(13) else
    if val = 13 then next_line_process(10) else
    if val = 9 then next_tab_process else
     next_buf_num(next_text);

    if column > 512 then
     if val <> 9 then
      begin
       next_buf('>');
       next_buf('|');
       next_buf(#13);
       column := 0;
       val := 13;
      end;
   end;
 next_buf(#0);

 if text<>nil then
  begin
   if text^ = #0 then dec(text);
   new_end_char := text^
  end
 else
  new_end_char := #0;

 self.text.SetText(buffer);
 FreeMemory(buffer);

 SetLength(index, 0);
 SetLength(index, self.text.Count);

 for pos := 0 to self.text.Count-1 do
  begin
   index[pos].X := char_size.X * length(self.text.Strings[pos]);
   index[pos].y := char_size.Y * pos;
  end;

 draw_size_update;
 view_size_update;
 scroll_bar_update;

 if auto_update_scroll then
  if (old_y_max - old_y_pos) < (char_size.y) then
   begin
    select_none;
    scroll_bar_y.Position := scroll_bar_y.Max;
   end;

 redraw;

 update_time := GetTickCount;
 inc(text_update_cnt);

 if @onReset <> nil then
  if (last_chars > new_chars) or new_text then
   onReset(self);

 if new_text then
  last_strings := 0;
  
 if @onString <> nil then
  begin
   if (last_strings < self.text.Count) then
    for pos := math.max(0, last_strings-1) to math.max(0, self.text.Count - 2) do
     begin
      str := self.text.Strings[pos];
      ctrl_chars_to_space(str);
      onString(Self, str, pos);
     end;
  end;

 last_end_char := new_end_char;
 last_strings := self.text.Count;
 last_chars := new_chars;
end;

procedure tLog_Viewer.bitmap_rebuild;
begin
 if bitmap <> nil then
  FreeAndNil(bitmap);

 bitmap := TBitmap.Create;
 bitmap.PixelFormat := pf32bit;
 bitmap.Width  := paint_box.Width;
 bitmap.Height := paint_box.Height;

 bitmap.Canvas.Font.Name := 'Courier New';
 bitmap.Canvas.Font.Size := 10;
 bitmap.Canvas.Font.Charset := RUSSIAN_CHARSET;
 bitmap.Canvas.Font.Pitch   := fpFixed;

 char_size.X := bitmap.Canvas.TextWidth('A');
 char_size.Y := bitmap.Canvas.TextHeight('A')+1;
end;

procedure tLog_Viewer.view_size_update;
var
 new_size : tpoint;
begin
 new_size.X := paint_box.Width;
 new_size.y := paint_box.Height;

 if (view_size.X <> new_size.x) or (view_size.Y <> new_size.Y) then
  bitmap_rebuild;

 view_size := new_size;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure tLog_Viewer.draw_size_update;
var
 new_size : tpoint;
 pos : integer;
begin
 new_size.y := 0;
 new_size.x := 0;

 for pos := 0 to length(index)-1 do
  begin
   new_size.x := MAX(new_size.x, index[pos].x + char_size.x);
   new_size.y := MAX(new_size.y, index[pos].y + char_size.Y);
  end;

 draw_size := new_size;
end;

procedure scroll_update(scroll_bar:TScrollBar; draw_size, view_size, char_size:integer);
var
 pos : integer;
begin
 if view_size >= draw_size then
  begin
   scroll_bar.PageSize    := 1;
   scroll_bar.SmallChange := 1;
   scroll_bar.LargeChange := 1;

   scroll_bar.SetParams(1, 1, 1);
  end
 else
  begin
   if (scroll_bar.min = 1) and (scroll_bar.max = 1) and (scroll_bar.Position = 1) then
    scroll_bar.SetParams(0, 0, 1);

   pos := scroll_bar.Position;
   scroll_bar.SetParams(math.max(0, math.min(draw_size - view_size, pos)), 0, draw_size - view_size);

   scroll_bar.PageSize := 0;

   if (draw_size - view_size >= char_size*3) then
    begin
     scroll_bar.SmallChange := char_size;
     scroll_bar.LargeChange := ((view_size div 2) div char_size) * char_size;
    end
   else
    begin
     scroll_bar.SmallChange := 1;
     scroll_bar.LargeChange := 2;
    end;
   _inf(scroll_bar);
  end;
end;

procedure tLog_Viewer.scroll_bar_update;
begin
 scroll_update(scroll_bar_y, draw_size.y, view_size.y, char_size.y);
 scroll_update(scroll_bar_x, draw_size.x, view_size.x, char_size.x);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure tLog_Viewer.onChange_Y(sender:tobject);
begin
 if self = nil then exit;
 redraw;
 scroll_time := GetTickCount;
end;

procedure tLog_Viewer.onChange_X(sender:tobject);
begin
 if self = nil then exit;
 redraw;
 scroll_time := GetTickCount;
end;

procedure tLog_Viewer.onPaint(sender:tobject);
begin
 if self = nil then exit;
 redraw;
end;

procedure tLog_Viewer.onMouseDown(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
begin
 if self = nil then exit;
 if button = mbleft then
  if ssShift in shift then
   begin
    select_to := scr2pos(x,y);
    redraw;
   end
  else
   begin
    sel_run := true;
    sel_start := scr2pos(x,y);
    select_from := sel_start;
    select_to   := sel_start;
   end;

 windows.SetFocus(scroll_bar_y.Handle);
end;

procedure tLog_Viewer.onMouseMove(Sender:TObject; Shift:TShiftState; X,Y:Integer);
begin
 if self = nil then exit;
 if sel_run then
  begin
   select_to := scr2pos(x,y);
   redraw;
  end;
end;

procedure tLog_Viewer.onMouseUp(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
var
 point : tpoint;
begin
 if self = nil then exit;
 if button = mbleft then
  if sel_run then
   begin
    select_to := scr2pos(x,y);
    sel_run := false;
    redraw;
   end;

 if button = mbright then
  if (sel_from.y <> sel_to.Y) or (sel_from.x <> sel_to.x) then
   begin
    point.x := x;
    point.Y := y;
    point := paint_box.ClientToScreen(point);
    menu.Popup(point.x, point.y);
   end;
end;

procedure clipboard_write(format:cardinal; s:widestring);
var
 len : cardinal;
 hmem : hglobal;
begin
 if s='' then
  begin
   OpenClipboard(0);
   EmptyClipboard();
   CloseClipboard();
   exit;
  end;

 s := s + #0;
 len := length(s)*sizeof(s[1]);
 hMem := GlobalAlloc(GMEM_MOVEABLE, len);
 CopyMemory(GlobalLock(hmem), @s[1], len);
 GlobalUnlock(hMem);
 OpenClipboard(Application.MainForm.Handle);
 EmptyClipboard();
 SetClipboardData(format, hMem);
 CloseClipboard();
end;

procedure tLog_Viewer.onMenuStat(Sender: TObject);
begin
 if self = nil then exit;
 if (sel_from.y <> sel_to.Y) or
    ((sel_from.y = sel_to.Y) and (sel_from.x = sel_to.x)) or
    (text.count = 0) then
  begin
   ShowMessage('Ошибка: выделите одининочный параметр'#13 +
    'он должен быть:'#13 +
    ' - на одной строке'#13 +
    ' - иметь уникальное имя'#13 +
    ' - это не числовой результат измерения'#13 +
    ' - это не текстовый результат тестов'#13 +
    ' - это не элемент оформления'#13 +
    ' - всегда расположено в том-же самом месте строки относительно левого края лога'#13 +
    ' - всегда имеет одно и тоже наименование'#13 +#13 +
    'примеры:'#13 +
    'mV: MCU_15: SLIC_LINEU'#13 +
    'SystemCoreClock'#13 +
    'Balance	[TEL_DC: __ ALL OFF] ::	[TEL_DC: __ ALL OFF]'
    );
   exit;
  end;

 if @onMenu_Stat <> nil then
  onMenu_Stat(self, remove_code8(copy(text.Strings[sel_from.y], sel_from.X+1, sel_to.X - sel_from.X)), sel_from.x+1);
end;

procedure tLog_Viewer.onMenuCopy(Sender: TObject);
var
 pos : integer;
 list : tstringlist;
 str : string;
begin
 if self = nil then exit;
 if (sel_from.y = sel_to.Y) and (sel_from.x = sel_to.x) then exit;
 if text.count = 0 then exit;

 if (sel_from.y = sel_to.y) and (sel_from.X < sel_to.x) then
  begin
   str := remove_code8(copy(text.Strings[sel_from.y], sel_from.X+1, sel_to.X - sel_from.X));
   if @onMenu_Copy <> nil then
    onMenu_Copy(self, str, sel_from.y);
   clipboard_write(CF_UNICODETEXT, str)
  end
 else
  begin
   list := TStringList.Create;
   for pos := sel_from.Y to sel_to.Y-1 do
    list.Add(text.Strings[pos]);
   str := remove_code8(list.GetText);
   if @onMenu_Copy <> nil then
    onMenu_Copy(self, str, sel_from.y);
   clipboard_write(CF_UNICODETEXT, str);
   list.Free;
  end;
end;

function scroll_switch(scroll_a,scroll_b:TScrollBar; msg,vk_minus, vk_plus:integer; step:integer):boolean;
var
 dlt : integer;
begin
 result := false;

 if scroll_a.Focused then
  if (Msg = vk_plus) or (Msg = vk_minus) then
   begin
    if Msg = vk_plus then
     dlt := +1
    else
     dlt := -1;

    windows.SetFocus(scroll_b.handle);

    if step <> 0 then
     scroll_b.Position := scroll_b.Position + dlt * step
    else
     if dlt > 0 then
      scroll_b.Position := scroll_b.Max
     else
      scroll_b.Position := scroll_b.Min;

    result := true;
   end;
end;

procedure tLog_Viewer.onWinMSG(var Msg: tagMSG; var Handled: Boolean);
begin
 if self = nil then exit;
 if @old_message_event <> nil then
  old_message_event(msg, handled);

 if Msg.message = WM_MOUSEWHEEL then
  if (scroll_bar_x.Focused or scroll_bar_y.Focused) then
   begin
    scroll_bar_y.Position := scroll_bar_y.Position - (SmallInt(HiWord(cardinal(Msg.wParam))) div 2);
    handled := true;
   end;

 if Msg.message = WM_CHAR then
  begin
   if char(msg.wparam) = ^C then self.onMenuCopy(self);
   if char(msg.wparam) = ^A then self.select_all;
   redraw;
  end;

 if Msg.message = WM_KEYDOWN then
  begin
   handled := handled or scroll_switch(scroll_bar_y, scroll_bar_x, Msg.wParam, VK_LEFT,  VK_RIGHT, scroll_bar_x.SmallChange);
   handled := handled or scroll_switch(scroll_bar_x, scroll_bar_y, Msg.wParam, VK_DOWN,  VK_UP,   -scroll_bar_y.SmallChange);
   handled := handled or scroll_switch(scroll_bar_x, scroll_bar_y, Msg.wParam, VK_PRIOR, VK_NEXT,  scroll_bar_y.LargeChange);
   handled := handled or scroll_switch(scroll_bar_x, scroll_bar_y, Msg.wParam, VK_HOME,  VK_END,   0);
  end;
end;

procedure tLog_Viewer.onTimer(Sender:tobject);
var
 speed : double;
 time : double;
 delta : double;
begin
 if not auto_scroll_smooth then exit;

 if smooth_update_cnt = text_update_cnt then exit;

 if scroll_bar_y.Position >= scroll_bar_y.Max then
  begin
   smooth_update_cnt := text_update_cnt;
   exit;
  end;

 speed := math.max(smooth_speed_curr, char_size.Y);
 speed := math.min(speed, scroll_bar_y.LargeChange*10);

 time := math.min(50, milliseconds_get(smooth_timer));
 milliseconds_start(smooth_timer);
 time := time / 1000;

 scroll_bar_y.Position := math.min(scroll_bar_y.Max, scroll_bar_y.Position + math.max(1, round(speed * time)));

 delta := scroll_bar_y.Max - scroll_bar_y.Position;
 //debug_log.send_nums([scroll_bar_y.Max, scroll_bar_y.Position, delta, smooth_speed_curr, smooth_speed_need]);

 smooth_speed_need := math.max(1, smooth_speed_need);
 if delta > (smooth_speed_need * 1.5) then smooth_speed_need := smooth_speed_need * 1.1;
 if delta < (smooth_speed_need * 1.0) then smooth_speed_need := smooth_speed_need * 0.9;

 smooth_speed_curr := smooth_speed_curr + min(+5.0, smooth_speed_need - smooth_speed_curr);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure tLog_Viewer.select_lines(line_from, line_to:integer; repaint:boolean = true);
begin
 line_from := math.max(0, math.Min(text.Count - 1, line_from));
 line_to   := math.max(0, math.Min(text.Count, line_to));

 select_from.x := 0;
 select_from.y := line_from;

 select_to.x := 0;
 select_to.y := line_to;

 if repaint then
  self.redraw;
end;

procedure tLog_Viewer.select_all;
begin
 if text.Count = 0 then exit;

 select_from.x := 0;
 select_from.y := 0;

 select_to.x := length(text.Strings[text.Count-1]);
 select_to.y := text.Count;
end;

procedure tLog_Viewer.select_none;
begin
 select_from.x := 0;
 select_from.y := 0;

 select_to.x := 0;
 select_to.y := 0;

 sel_run := false;
end;

procedure tLog_Viewer.point_sel_correct(var p:tpoint);
begin
 if text.count = 0 then
  begin
   p.x := 0;
   p.y := 0;
  end;

 p.x := math.max(0, p.x);
 p.y := math.max(0, math.min(p.y, text.Count));
end;

function tLog_Viewer.sel_from:tpoint;
begin
 if select_from.Y = select_to.Y then
  if select_from.x < select_to.x then
   result := select_from
  else
   result := select_to
 else
  if select_from.y < select_to.y then
   result := select_from
  else
   result := select_to;
 point_sel_correct(result);
end;

function tLog_Viewer.sel_to:tpoint;
begin
 if select_from.Y = select_to.Y then
  if select_from.x > select_to.x then
   result := select_from
  else
   result := select_to
 else
  if select_from.y > select_to.y then
   result := select_from
  else
   result := select_to;

 point_sel_correct(result);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function extract_string(str:string):string;
var
 pos : integer;
begin
 result := '';
 pos := 1;

 while pos <= Length(str) do
  begin
   if str[pos] = '"' then break;
   inc(pos);
   if pos > Length(str) then exit;
  end;

 while pos <= Length(str) do
  begin
   if str[pos] = '"' then exit;
   result := result + str[pos];
   inc(pos);
   if pos > Length(str) then break;
  end;

 result := '';
end;

function tLog_Viewer.check_script(text:string; var color_b:cardinal; var color_f:cardinal; var style:TFontStyles):boolean;
var
 str : string;
 key : string;
 fb  : ansichar;
 ib : string;
 sr,sg,sb : string;
 r,g,b : integer;
 pos : integer;
begin
 result := false;
 if colors_script = nil then exit;
 if colors_script.Count = 0 then exit;

 for pos:= 0 to colors_script.Count-1 do
  begin
   str := colors_script.Strings[pos];
   if Length(str) < 16 then continue;
   if str[1] in ['#', ':', '/', '@'] then continue;
   if UpperCase(str) = 'END OF ARMKA TERMINAL SCRIPT' then exit;

   fb := str[1]; delete(str, 1, 2);
   sr := copy(str, 1, 3); delete(str, 1, 4);
   sg := copy(str, 1, 3); delete(str, 1, 4);
   sb := copy(str, 1, 3); delete(str, 1, 4);
   ib := copy(str, 1, 3); delete(str, 1, 4);
   key := str;

   if fb = '' then continue;
   if sr = '' then continue;
   if sg = '' then continue;
   if sb = '' then continue;
   if ib = '' then continue;
   if key = '' then continue;

   try
    r := strtoint(sr);
    g := strtoint(sg);
    b := strtoint(sb);
   except
    continue;
   end;

   if system.pos(key, text) <> 0 then
    begin
     if fb in ['F', 'f'] then
      color_f := rgb(r, g, b)
     else
      color_b := rgb(r, g, b);

     if ib[1] in ['B', 'b'] then style := style + [fsBold];
     if ib[2] in ['B', 'b'] then style := style + [fsBold];
     if ib[3] in ['B', 'b'] then style := style + [fsBold];

     if ib[1] in ['I', 'i'] then style := style + [fsItalic];
     if ib[2] in ['I', 'i'] then style := style + [fsItalic];
     if ib[3] in ['I', 'i'] then style := style + [fsItalic];

     if ib[1] in ['U', 'u'] then style := style + [fsUnderline];
     if ib[2] in ['U', 'u'] then style := style + [fsUnderline];
     if ib[3] in ['U', 'u'] then style := style + [fsUnderline];

     if ib[1] in ['S', 's'] then style := style + [fsStrikeOut];
     if ib[2] in ['S', 's'] then style := style + [fsStrikeOut];
     if ib[3] in ['S', 's'] then style := style + [fsStrikeOut];
     
     result := true;
    end;
  end;
end;

procedure tLog_Viewer.string_style(str:string; font:tfont; brush:TBrush);
var
 p : integer;
 old : string;
 clr_b, clr_f : cardinal;
 style:TFontStyles;
begin
 old := str;
 str := ' ' + UpperCase(str) + ' ';
 for p := 1 to length(str) do
  if not (str[p] in ['A'..'Z', '0' .. '9']) then
   str[p] := ' ';

 if pos(' ERROR ', str) <> 0 then
  begin
   font.Color := rgb(200, 0, 0);
   font.Style := [fsBold];
  end
 else
   begin
    for p := 1 to length(old)-3 do
     if old[p + 0] = '<' then
     if old[p + 1] in ['0'..'9', 'A'..'F'] then
     if old[p + 2] in ['0'..'9', 'A'..'F'] then
     if old[p + 3] = '>' then
      begin
       font.Color := font_color_error;
       font.Style := [fsBold];
       exit;
      end;

     if pos(' OK ', str) <> 0 then
      begin
       font.Color := font_color_ok;
       font.Style := [fsBold];
      end
     else
      begin
       font.Color := font_color_normal;
       font.Style := [];

       clr_b := brush.Color;
       clr_f := font.Color;
       style := font.Style;

       if check_script(old, clr_b, clr_f, style) then
        begin
         if brush.Color <> rgb(155, 155, 255) then
          brush.Color := clr_b;
         font.Color  := clr_f;
         font.Style  := style;
        end;
      end;
   end
end;

procedure tLog_Viewer.redraw;
begin
 if colors_script_fname <> '' then
  if colors_script <> nil then
   if FileExists(colors_script_fname) then
    begin
     try
      colors_script.LoadFromFile(colors_script_fname);
     except
     end;
    end;

 draw_raw(scroll_bar_x.Position - scroll_bar_x.Min,
          scroll_bar_y.Position - scroll_bar_y.Min);
end;

procedure tLog_Viewer.draw_raw(dx,dy:integer);
var
 pos : integer;
 x,y : integer;
 str : string;
 color_white : cardinal;
 color_txt, color_sel : cardinal;
 color : cardinal;
begin
 if @onDraw_begin <> nil then
  onDraw_begin(self);

 if @onDraw_string <> nil then
  for pos := math.max(0, dy div char_size.Y) to
   math.min(((dy  + view_size.Y) div char_size.Y), length(index)-1) do
   onDraw_string(self, text.Strings[pos], pos);

 if (not auto_update_scroll) or (scroll_bar_y.Position = scroll_bar_y.max) then
  color_white := bkcolor_enabled
 else
  color_white := bkcolor_disabled;

 bitmap.Canvas.Pen.Style := psSolid;
 bitmap.Canvas.Pen.Color := color_white;
 bitmap.Canvas.Brush.Style := bsSolid;
 bitmap.Canvas.Brush.Color := color_white;
 bitmap.Canvas.Rectangle(0, 0, bitmap.Width, bitmap.Height);

 if text.count = 0 then
  begin
   paint_box.Canvas.Draw(0, 0, bitmap);
   exit;
  end;

 color_txt := color_white;
 color_sel := rgb(155, 155, 255);

 //debug_log.send('draw'#9 + inttostr(dx) + #9 + inttostr(dy));

 for pos := math.max(0, dy div char_size.Y) to
  math.min(((dy  + view_size.Y) div char_size.Y), length(index)-1) do
  begin
   x := -dx;
   y := index[pos].y - dy;
   if y < -char_size.Y then continue;
   if y > bitmap.Height then break;

   str := text.Strings[pos];
   ctrl_chars_to_space(str);

   if (pos >= sel_from.Y) and (pos < sel_to.y) then
    color := color_sel
   else
    color := color_txt;
   bitmap.Canvas.Brush.Color := color;

   string_style(str, bitmap.Canvas.Font, bitmap.Canvas.Brush);

   if (sel_from.y = pos) and (sel_from.y = sel_to.y) and (sel_from.X < sel_to.x) then
    begin
     bitmap.Canvas.Brush.Color := color_txt;
     if @onDraw_control <> nil then onDraw_control(self, str, pos, bitmap.Canvas.Font, bitmap.Canvas.Brush);
     bitmap.Canvas.TextOut(x, y, copy(str, 1, sel_from.X));

     bitmap.Canvas.Brush.Color := color_sel;
     bitmap.Canvas.TextOut(x + sel_from.X * char_size.x, y, copy(str, sel_from.X+1, sel_to.X - sel_from.X));

     bitmap.Canvas.Brush.Color := color_txt;
     if @onDraw_control <> nil then onDraw_control(self, str, pos, bitmap.Canvas.Font, bitmap.Canvas.Brush);
     bitmap.Canvas.TextOut(x + sel_to.X * char_size.x,   y, copy(str, sel_to.X+1,  length(str) - sel_to.X));
    end
   else
    begin
     if length(str) > 1024 then
      str := copy(str, 1, 1024) + '...';
     if @onDraw_control <> nil then onDraw_control(self, str, pos, bitmap.Canvas.Font, bitmap.Canvas.Brush);
     bitmap.Canvas.TextOut(x,y, str);
    end;
  end;

 paint_box.Canvas.Draw(0, 0, bitmap);

 if @onDraw_end <> nil then
  onDraw_end(self);
end;

function tLog_Viewer.scr2pos(x,y:integer):tpoint;
var
 dx,dy:integer;
begin
 dx := scroll_bar_x.Position - scroll_bar_x.Min;
 dy := scroll_bar_y.Position - scroll_bar_y.Min;

 result.x := round((x + dx) / char_size.x);
 result.y := (y + dy) div char_size.y;
end;

procedure tLog_Viewer.onResize(Sender:tobject);
begin
 if self = nil then exit;
 if scroll_bar_y.Focused then
   windows.SetFocus(0);

 view_size_update;
 scroll_bar_update;
 redraw;
end;

end.
