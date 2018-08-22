unit GraphLinesForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, math, AppEvnts, menus,
  hsv2rgb,
  lineBuffer,
  dev_msg_const,
  TabNumParser,
  ufifo_map,
  GraphLinesParser,
  LineCtrl,
  uSimpleLog,
  uSimple_speed,
  Unit_Win7Taskbar;

type
  TGraphLinesForm = class(TForm)
    PaintBox: TPaintBox;
    PauseCheckBox: TCheckBox;
    SpeedRadioGroup: TRadioGroup;
    XScrollBar: TScrollBar;
    FastTimer: TTimer;
    SecondTimer: TTimer;
    CtrlPaintBox: TPaintBox;
    AmpRadioGroup: TRadioGroup;
    ScrollBarY: TScrollBar;
    YZeroButton: TButton;
    YMinButton: TButton;
    YMaxButtonButton: TButton;
    ApplicationEvents1: TApplicationEvents;
    ScreenShotButton: TButton;
    LastScreenshotLabel1: TLabel;
    LastScreenshotLabel2: TLabel;
    LastScreenshotLabel3: TLabel;
    AvrgModeCheckBox: TCheckBox;
    FFTCheckBox: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FastTimerTimer(Sender: TObject);
    procedure SecondTimerTimer(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure SpeedRadioGroupClick(Sender: TObject);
    procedure PauseCheckBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure YZeroButtonClick(Sender: TObject);
    procedure YMinButtonClick(Sender: TObject);
    procedure YMaxButtonButtonClick(Sender: TObject);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure AmpRadioGroupClick(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG;
      var Handled: Boolean);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScreenShotButtonClick(Sender: TObject);
    procedure ScreenShotButtonMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ScreenShotButtonMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FFTCheckBoxClick(Sender: TObject);

  protected
   procedure WndProc(var Message : TMessage); override;

  private
   dbg_log : file;

   parser : tGraphLinesParser;
   lines : array[0 .. GRAPH_CHANNELS-1] of tLineBuffer;
   text_log : tLineBuffer;
   ctrl : tLine_Ctrl;

   bitmap : TBitmap;

   stat_fps : integer;
   dbg_info : integer;

   base_mouse_y : integer;
   base_scrol_y : integer;
   base_mouse_x : integer;
   base_scrol_x : integer;

   zoom_shift_x : integer;
   zoom_shift_y : integer;

   mouse_old_client : tpoint;
   mouse_old_screen : tpoint;

   info_line_x : integer;
   info_line_enbled : boolean;

   selection_x1 : integer;
   selection_x2 : integer;
   selection_enabled : boolean;
   selection_time : cardinal;

   last_screenshot : string;
   last_screenshot_show : boolean;

   speeder : tsimple_speed;

   menu : tpopupmenu;
   item_copy_text : TMenuItem;
   item_copy_selected : TMenuItem;

   procedure onNums(nums:pTabNumParser_array; count:integer; str:pansichar; str_len:integer);
   procedure onChanels(chanels:tGraphLines);

   procedure redraw_all;
   procedure redraw_infoline;
   procedure redraw_gird;
   procedure redraw_selection;
   procedure redraw_chanels(avrg_mode:boolean);
   procedure redraw_marked(avrg_mode:boolean);
   procedure redraw_chanel(chanel:integer; width:integer; color:cardinal; avrg_mode:boolean);

   procedure reinit_bmp;
   procedure reinit_scroller_y;
   procedure reinit_scroller_x;

   function  calc_speed:double;
   function  calc_speed_step:integer;
   function  calc_speed_mult:integer;
   function  calc_amp:integer;
   function  calc_ofs:integer;
   function  calc_lift:integer;
   function  calc_lift_full:integer;

   procedure recalc_info_line;

   function bmpX_to_index(x:integer):integer;

   procedure onMenuCopyText(Sender: TObject);
   procedure onMenuCopySelected(Sender: TObject);

  public
   fifo : tFIFO_map;
   bringup_event : thandle;
   close_event : thandle;

   procedure update_fft;

   procedure onConnect();
   procedure onDisConnect();
   procedure onRX(data:pbyte; size:integer);
  end;

var
  LinesForm: TGraphLinesForm;

implementation
uses uarmkafft_form;

{$R *.dfm}

const
 SCREENSHOT_DIR = 'ScreenShots';

procedure clipboard_write(s:widestring);
var
 len : cardinal;
 hmem : hglobal;
const
 format = CF_UNICODETEXT;
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

function isCtrlDown : Boolean;  begin result := (GetAsyncKeyState(VK_CONTROL) and (1 shl 15) <> 0) end;
function isShiftDown : Boolean; begin result := (GetAsyncKeyState(VK_SHIFT) and (1 shl 15) <> 0) end;
function isAltDown : Boolean;   begin result := (GetAsyncKeyState(VK_MENU) and (1 shl 15) <> 0) end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.FormCreate(Sender: TObject);
var
 pos : integer;
begin
// logfile_create(rx_log, ExtractFilePath(paramstr(0)) + 'logs\' + time_str + '_device.log');
// logfile_create(dev_log, ExtractFilePath(paramstr(0)) + 'logs\' + time_str + '_system.log');
 logfile_create(dbg_log, ExtractFilePath(paramstr(0)) + 'logs\' + date_time_filename + '_debug.log');

 parser := tGraphLinesParser.create;
 parser.onNumsEvent := self.onNums;
 parser.onChanels := self.onChanels;

 ctrl := tline_ctrl.create(length(lines), CtrlPaintBox);
 if not ctrl.settings_load then
  ctrl.settings_default;

 for pos := 0 to length(lines) - 1 do
  lines[pos] := tLineBuffer.create;

 text_log :=tLineBuffer.create;
 text_log.memfree_mode := true;

 bitmap := nil;
 reinit_bmp;
 reinit_scroller_x;
 reinit_scroller_y;
 self.DoubleBuffered := true;

 InitializeTaskbarAPI;

 selection_x1 := -1;
 selection_x2 := -1;

 Self.Constraints.MinHeight := 830;
 Self.Constraints.MinWidth := (self.Width - ScrollBarY.Left)*2;
// self.Constraints.MaxWidth := 2048;
// self.Constraints.MaxHeight := 1024;
 speeder := tsimple_speed.create;

 menu := TPopupMenu.Create(self);

 item_copy_text := TMenuItem.create(menu);
 item_copy_text.Caption := 'Copy all as text';
 item_copy_text.Default := true;
 item_copy_text.OnClick := self.onMenuCopyText;
 menu.Items.Add(item_copy_text);

 item_copy_selected := TMenuItem.create(menu);
 item_copy_selected.Caption := 'Copy selected only';
 item_copy_selected.Default := false;
 item_copy_selected.OnClick := self.onMenuCopySelected;
 menu.Items.Add(item_copy_selected);
end;

procedure TGraphLinesForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
 pos : integer;
begin
 logfile_close(dbg_log);

 ctrl.settings_save;

 FreeAndNil(bitmap);
 FreeAndNil(parser);
 FreeAndNil(ctrl);

 FreeAndNil(item_copy_text);
 FreeAndNil(item_copy_selected);
 FreeAndNil(menu);
 
 for pos := 0 to length(lines) - 1 do
  FreeAndNil(lines[pos]);
end;

procedure TGraphLinesForm.FormShow(Sender: TObject);
begin
end;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TGraphLinesForm.onRX(data:pbyte; size:integer);
begin
 parser.parse(data, size);
end;

procedure TGraphLinesForm.onNums(nums:pTabNumParser_array; count:integer; str:pansichar; str_len:integer);
//var
// s : ansistring;
// pos : integer;
var
 buf : pansichar;
 pos : integer;
 c : ansichar;
begin
{ s := '';
 for pos := 0 to count - 1 do
  if nums[pos].error <> 0 then
   s := s + 'error' + #9
  else
   s := s + ansistring(inttostr(nums[pos].value)) + #9;
 logfile_write_str(dbg_log, s);}

 while str_len > 0 do
  begin
   if (byte(str^) <> 10) and (byte(str^) <> 13) then
    break;
   inc(str);
   dec(str_len);
  end;

 buf := GetMemory(str_len + 1);
 pos := 0;
 while pos < str_len do
  begin
   c := str^;
   if byte(c) = 0 then
    c := ansichar(9);
   buf[pos] := c;
   inc(pos);
   inc(str);
  end;
 buf[pos] := ansichar(0);

 text_log.add(integer(buf), false);

 //logfile_write_str(dbg_log, buf);
 //FreeMemory(buf);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.onConnect();
begin
 parser.reset;
end;

procedure TGraphLinesForm.onDisConnect();
begin
end;

procedure TGraphLinesForm.FastTimerTimer(Sender: TObject);
var
 pos : integer;
 buf : array of byte;
 size : integer;
begin
 if not PauseCheckBox.Checked then
  begin
   fifo.update;
   size := fifo.bytes_count;
   if size > 0 then
    begin
     SetLength(buf, size);
     fifo.read(@(buf[0]), size);
     self.onRX(@(buf[0]), size);
     XScrollBar.Position := XScrollBar.Max - XScrollBar.PageSize;
     SetLength(buf, 0);
    end;
   speeder.add_value(size);
  end;

 if WaitForSingleObject(close_event, 0) = WAIT_OBJECT_0 then
  begin
   self.Close;
   exit;
  end;

 if WaitForSingleObject(bringup_event, 0) = WAIT_OBJECT_0 then
  begin
   Application.Minimize;
   Application.ProcessMessages;
   Application.Restore;
  end;

 for pos := 0 to length(lines) - 1 do
  lines[pos].refresh;
 text_log.refresh;

 redraw_all;
 PaintBox.Canvas.Draw(0,0, bitmap);
 inc(stat_fps);

 if ArmkaFFT_Form.Visible then
  ArmkaFFT_Form.redraw;
end;

procedure TGraphLinesForm.SecondTimerTimer(Sender: TObject);
var
 pos : integer;
begin

 self.Caption :=
  ' fps: ' + inttostr(stat_fps) +
  ' speed: ' + inttostr(round(speeder.read_reset)) + 
  ' lines: ' + inttostr(parser.stat_lines) +
  ' nums: ' + inttostr(parser.stat_normals) +
  ' other: ' + inttostr(parser.stat_errors) +
  ' fifo: ' + inttostr(fifo.ratio_count div 10) + '%' +
  '';

 if parser.stat_lines > 0 then
  begin
   SetTaskbarProgressState(tbpsNormal);
   SetTaskbarProgressValue(2, 10);
  end
 else
  SetTaskbarProgressState(tbpsNone);

 if not PauseCheckBox.Checked then
  for pos := 0 to length(lines)-1 do
   begin
    lines[pos].stat_avrg_read_reset(ctrl.last_values[pos], ctrl.last_valid[pos]);
    ctrl.color_probe := rgb(175, 175, 175);
   end;
 CtrlPaintBox.Repaint;

 parser.stat_lines := 0;
 parser.stat_errors := 0;
 parser.stat_normals := 0;

 stat_fps := 0;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.onChanels(chanels:tGraphLines);
var
 pos : integer;
begin
 for pos := 0 to length(lines) - 1 do
  lines[pos].add(chanels[pos].value, chanels[pos].err);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.redraw_chanel(chanel:integer; width:integer; color:cardinal; avrg_mode:boolean);
var
 x : integer;
 y : integer;
 y1, y2 : integer;
 valid : boolean;
 old_valid : boolean;
 speed_step : integer;
 speed_mult : integer;
 ofs : integer;
 amp : integer;
 y_lift : int64;
 stat : tLineItem_stat;
begin
 bitmap.Canvas.Pen.style := pssolid;
 bitmap.Canvas.Pen.Color := color;
 bitmap.Canvas.Pen.Width := width;

 amp := calc_amp;
 ofs := calc_ofs;
 y_lift := calc_lift_full;

 speed_step := calc_speed_step;
 speed_mult := calc_speed_mult;

 old_valid := false;
 x := 0;
 if avrg_mode then
  while x <= (bitmap.width + 1) do
   begin
    y := lines[chanel].read_y_avrg(x div speed_step, ofs, speed_mult, bitmap.Height-1, amp, y_lift, valid);
    if valid then
     begin
      if old_valid = true then
       bitmap.Canvas.LineTo(bitmap.Width - x, y)
      else
       bitmap.Canvas.MoveTo(bitmap.Width - x, y);
     end;
    old_valid := valid;
    inc(x, speed_step);
   end
 else
  while x <= (bitmap.width + 1) do
   begin
    stat := lines[chanel].read_y_stat(x div speed_step, ofs, speed_mult, bitmap.Height-1, amp, y_lift);
    if stat.cnt > 0 then
     begin
      y1 := round(stat.min);
      y2 := round(stat.max);
      if old_valid = true then
       begin
        bitmap.Canvas.LineTo(bitmap.Width - x, y1);
        if y2 <> y1 then
         bitmap.Canvas.LineTo(bitmap.Width - x, y2);
       end
      else
       bitmap.Canvas.MoveTo(bitmap.Width - x, y1);
     end;
   old_valid := stat.cnt > 0;
   inc(x, speed_step);
  end;
end;

procedure TGraphLinesForm.redraw_chanels(avrg_mode:boolean);
var
 pos : integer;
begin
 for pos := 0 to length(lines) - 1 do
  begin
   if not ctrl.line_enabled[pos] then continue;
   //if pos = ctrl.line_marked then continue; //disabled for chanel by color pickup detector

   redraw_chanel(pos, 1, ctrl.line_colors[pos], avrg_mode);
  end;
end;

procedure TGraphLinesForm.redraw_selection;
begin
 if not selection_enabled then exit;
 if selection_x1 < 0 then exit;
 if selection_x2 < 0 then exit;

 bitmap.Canvas.Pen.style := pssolid;
 bitmap.Canvas.Brush.style := bssolid;
 bitmap.Canvas.Brush.Color := rgb(0, 0, 100);
 bitmap.Canvas.Pen.Color := rgb(0, 0, 250);
 bitmap.Canvas.Pen.Width := 1;
 bitmap.Canvas.Rectangle(selection_x1, -1, selection_x2, bitmap.Height+1);
end;

procedure TGraphLinesForm.redraw_infoline;
begin
 if not info_line_enbled then exit;

 bitmap.Canvas.Pen.Color := rgb(0, 100, 125);
 bitmap.Canvas.Pen.Width := 1;
 bitmap.Canvas.MoveTo(info_line_x, 0);
 bitmap.Canvas.LineTo(info_line_x, bitmap.Height);
 recalc_info_line;
end;

procedure TGraphLinesForm.redraw_gird;
var
 pos : integer;
 time_shift : integer;
 speed : double;
 ofs : integer;
 y_lift : integer;
 amp : integer;
 y : integer;
begin
 speed := calc_speed;
 ofs := calc_ofs;
 amp := calc_amp;
 y_lift := calc_lift_full;

 bitmap.Canvas.Pen.style := pssolid;
 bitmap.Canvas.Pen.Color := rgb(50, 50, 50);
 bitmap.Canvas.Pen.Width := 1;
 bitmap.Canvas.Brush.style := bsclear;

 time_shift := 0;
 repeat
  pos := round((((lines[0].stat_total + ofs) mod GRAPH_GIRD_STEP_X) + time_shift) / speed);
  inc(time_shift, GRAPH_GIRD_STEP_X);
  bitmap.Canvas.MoveTo(bitmap.Width - pos, 0);
  bitmap.Canvas.LineTo(bitmap.Width - pos, bitmap.Height);
 until pos >= bitmap.Width;

 y := GRAPH_CHANNEL_MIN;
 while y < GRAPH_CHANNEL_MAX do
  begin
   if y = 0 then
    bitmap.Canvas.Pen.Color := rgb(100, 100, 100)
   else
    bitmap.Canvas.Pen.Color := rgb(50, 50, 50);

   pos := lines[0].calc_y(y, bitmap.Height-1, amp, y_lift);
   inc(y, GRAPH_GIRD_STEP_Y);
   bitmap.Canvas.MoveTo(0, pos);
   bitmap.Canvas.LineTo(bitmap.Width, pos);
  end;
end;

procedure TGraphLinesForm.redraw_marked(avrg_mode:boolean);
begin
 if ctrl.line_marked < 0 then
  exit;

 redraw_chanel(ctrl.line_marked, 7, rgb(0, 0, 0), avrg_mode);
 redraw_chanel(ctrl.line_marked, 3, rgb(255, 255, 255), avrg_mode);
end;


procedure TGraphLinesForm.redraw_all;
begin
 bitmap.Canvas.Pen.style := psclear;
 bitmap.Canvas.Brush.style := bssolid;
 bitmap.Canvas.Brush.Color := rgb(0,0,0);
 bitmap.Canvas.Rectangle(-1, -1, bitmap.Width + 1, bitmap.Height + 1);

 if last_screenshot_show then
  begin
   bitmap.LoadFromFile(last_screenshot);
   PaintBox.Canvas.Draw(0,0, bitmap);
   inc(stat_fps);
   exit;
  end;

 redraw_selection;
 redraw_gird;
 redraw_infoline;
 redraw_chanels(AvrgModeCheckBox.Checked);
 redraw_marked(AvrgModeCheckBox.Checked);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.PaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if PauseCheckBox.Checked then
  if button = mbright then
   begin
    selection_enabled := true;
    selection_x1 := x;
    selection_x2 := -1;
   end;

 if button = mbleft then
  begin
   base_mouse_y := y;
   base_mouse_x := x;
   base_scrol_y := ScrollBarY.Position;
   base_scrol_x := XScrollBar.Position;
   selection_time := GetTickCount;
  end
 else
  base_mouse_y := -1;
 info_line_enbled := false;
end;

procedure TGraphLinesForm.onMenuCopyText(Sender: TObject);
var
 list : tstringlist;
 str : string;
 x1 : integer;
 x2 : integer;
begin
 x1 := (bitmap.Width - selection_x1) div calc_speed_step;
 x2 := (bitmap.Width - selection_x2) div calc_speed_step;

 list := text_log.import_strings(x1, x2, calc_ofs, calc_speed_mult);
 if list <> nil then
  if list.Count > 0 then
   begin
    str := list.GetText;
    clipboard_write(str);
   end;
 FreeAndNil(list);
end;

procedure TGraphLinesForm.onMenuCopySelected(Sender: TObject);
var
 items : tLineItems_integers;
 list : tstringlist;
 str : string;
 x1 : integer;
 x2 : integer;
 pos : integer;
begin
 if ctrl.line_marked < 0 then
  exit;

 x1 := (bitmap.Width - selection_x1) div calc_speed_step;
 x2 := (bitmap.Width - selection_x2) div calc_speed_step;

 items := lines[ctrl.line_marked].import_integers(x1, x2, calc_ofs, calc_speed_mult);

 list := TStringList.Create;
 for pos := 0 to length(items) - 1 do
  if items[pos].info <> nil then
   list.Add(IntToStr(items[pos].value))
  else
   list.Add('???');
 setlength(items, 0);

 if list <> nil then
  if list.Count > 0 then
   begin
    str := list.GetText;
    clipboard_write(str);
   end;
 FreeAndNil(list);
end;

procedure TGraphLinesForm.PaintBoxMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 point : tpoint;

 i,j : integer;
begin
 if selection_enabled then
 if button = mbright then
  if selection_enabled then
   if selection_x1 > -1 then
    if selection_x2 > -1 then
     begin
      selection_enabled := false;
      item_copy_selected.Enabled := (ctrl.line_marked >= 0);

      GetCursorPos(point);
      menu.Popup(point.x, point.y);
     end;

 if button = mbleft then
  if (GetTickCount - selection_time) < 250 then
   begin
    if ctrl.line_marked >= 0 then
     redraw_chanels(AvrgModeCheckBox.Checked);

    ctrl.pickup_start;
    for i := -3 to +3 do
     for j := -3 to +3 do
      ctrl.pickup_add(bitmap.Canvas.Pixels[x + i, y + j]);
    ctrl.pickup_end;
   end;
end;

procedure TGraphLinesForm.PaintBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
 val : double;
begin
 mouse_old_client.X := x;
 mouse_old_client.Y := y;
 mouse_old_screen := ClientToScreen(mouse_old_client);

 if selection_enabled then
  if ssright in shift then
   selection_x2 := x;

  if ssLeft in shift then
   if base_mouse_y >= 0 then
    begin
     val := -(y - base_mouse_y);
     val := val / (bitmap.Height - 1);
     val := val * ScrollBarY.PageSize;
     val := val + base_scrol_y;
     val := math.max(val, ScrollBarY.Min);
     val := math.min(val, ScrollBarY.Max - ScrollBarY.PageSize);
     ScrollBarY.Position := round(val);

     if PauseCheckBox.Checked then
      begin
       val := -(x - base_mouse_x);
       val := val / (bitmap.Width - 1);
       val := val * XScrollBar.PageSize;
       val := val + base_scrol_x;
       val := math.max(val, XScrollBar.Min);
       val := math.min(val, XScrollBar.Max - XScrollBar.PageSize);
       XScrollBar.Position := round(val);
      end;
    end;

 info_line_enbled := (shift = []) and PauseCheckBox.Checked and (not selection_enabled);
 if info_line_enbled then
  begin
   info_line_x := x;
   update_fft;
  end
end;

procedure TGraphLinesForm.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
var
 direction : integer;
 val : double;
 zoom_x : boolean;
 zoom_y : boolean;
 mouse_pos : tpoint;
begin
 if Msg.message = WM_MOUSEWHEEL then
 if mouse.CursorPos.X = mouse_old_screen.X then
 if mouse.CursorPos.Y = mouse_old_screen.Y then
  begin
   zoom_x := true;
   zoom_y := true;
   if isCtrlDown then zoom_x := false;
   if isAltDown then zoom_y := false;

   direction := math.Sign(SmallInt(HiWord(cardinal(Msg.wParam))) div 2);
   if direction < 0 then
    begin
     if zoom_y then AmpRadioGroup.ItemIndex   := math.max(AmpRadioGroup.ItemIndex - 1, 0);
     if zoom_x then SpeedRadioGroup.ItemIndex := math.Min(SpeedRadioGroup.ItemIndex + 1, SpeedRadioGroup.Items.Count);
    end
   else
    begin
       begin
        GetCursorPos(mouse_pos);

        if zoom_x then
         begin
          SpeedRadioGroup.ItemIndex := math.max(SpeedRadioGroup.ItemIndex - 1, 0);
          val := (mouse_old_client.x - (bitmap.Width / 2.0));
          val := val / (bitmap.Width / 2.0);
          val := XScrollBar.Position + (val * XScrollBar.PageSize / 1.0);
          val := math.Max(0, math.Min(val, XScrollBar.Max - XScrollBar.PageSize));
          mouse_pos.x := round(mouse_pos.x - (val - XScrollBar.Position)* bitmap.Width / XScrollBar.PageSize / 2.0);
          XScrollBar.Position := round(val);
         end;

        if zoom_y then
         begin
          AmpRadioGroup.ItemIndex := math.Min(AmpRadioGroup.ItemIndex + 1, AmpRadioGroup.Items.Count);
          val := (mouse_old_client.y - (bitmap.Height / 2.0));
          val := val / (bitmap.Height / 2.0);
          val := ScrollBarY.Position + (val * ScrollBarY.PageSize / 1.0);
          val := math.Max(0, math.Min(val, ScrollBarY.Max - ScrollBarY.PageSize));
          mouse_pos.y := round(mouse_pos.y - (val - ScrollBarY.Position)* (bitmap.Height-2) / ScrollBarY.PageSize / 2.0);
          ScrollBarY.Position := round(val);
         end;
         
        SetCursorPos(mouse_pos.x, mouse_pos.y);
       end;
    end;
   handled := true;
  end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.recalc_info_line;
var
 pos : integer;
 speed_step : integer;
 speed_mult : integer;
 x : integer;
begin
 speed_step := math.Max(1, round(1 / calc_speed));
 speed_mult := math.Max(1, round(calc_speed));
 x := bitmap.Width - info_line_x;

 for pos := 0 to length(lines)-1 do
  begin
   ctrl.last_values[pos] :=
    round(lines[pos].get_value_avrg(x div speed_step, calc_ofs, speed_mult, ctrl.last_valid[pos]));
  end;
 ctrl.color_probe := rgb(200, 200, 255); 
 CtrlPaintBox.Repaint;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.reinit_bmp;
begin
 FreeAndNil(bitmap);
 bitmap := TBitmap.Create;
 bitmap.Width := PaintBox.Width;
 bitmap.height := PaintBox.height;
 bitmap.PixelFormat := pf24bit;

 reinit_scroller_x;
 reinit_scroller_y;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

function  TGraphLinesForm.calc_speed_step:integer;
begin
 result := math.Max(1, round(1 / calc_speed));
end;

function  TGraphLinesForm.calc_speed_mult:integer;
begin
 result := math.Max(1, round(calc_speed));
end;


function  TGraphLinesForm.calc_speed:double;
begin
 result := (1 shl math.Max(0, SpeedRadioGroup.ItemIndex)) / 8.0;
end;

function  TGraphLinesForm.calc_amp:integer;
begin
 result := (1 shl math.Max(0, AmpRadioGroup.ItemIndex));
end;

function  TGraphLinesForm.calc_ofs:integer;
begin
 result := math.min(XScrollBar.max, XScrollBar.Position + XScrollBar.PageSize);
end;

function  TGraphLinesForm.calc_lift:integer;
begin
 result := math.min(ScrollBarY.max, ScrollBarY.Position + ScrollBarY.PageSize) - ScrollBarY.PageSize;
end;

function  TGraphLinesForm.calc_lift_full:integer;
begin
 if ScrollBarY.Max - ScrollBarY.PageSize > 0 then
  begin
   result := (int64(calc_lift()) * int64(ScrollBarY.Max)) div int64(ScrollBarY.Max - ScrollBarY.PageSize);
   result := ScrollBarY.Max - result + GRAPH_CHANNEL_MIN;
  end
 else
  result := 0;
end;

procedure TGraphLinesForm.reinit_scroller_x;
var
 ofs : integer;
 page_size : integer;
begin
 XScrollBar.Min := 0;
 XScrollBar.Max := LINE_BUFFER_SIZE - 1;

 ofs := calc_ofs - round(XScrollBar.PageSize / 2) + zoom_shift_x;
 page_size := math.Min(XScrollBar.Max, round((bitmap.Width - 1) * calc_speed));
 ofs := ofs - (page_size div 2);

 XScrollBar.PageSize := page_size;
 XScrollBar.Position := ofs;
 XScrollBar.SmallChange := math.Max(1, page_size div 100);
 XScrollBar.LargeChange := math.Max(1, page_size div 2);
 zoom_shift_x := 0;
end;

procedure TGraphLinesForm.reinit_scroller_y;
var
 ofs : integer;
 page_size : integer;
begin
 ofs := calc_lift + round(ScrollBarY.PageSize / 2) + zoom_shift_y;
 page_size := round((GRAPH_CHANNEL_MAX - GRAPH_CHANNEL_MIN) / calc_amp);

 ScrollBarY.Min := 0;
 ScrollBarY.Max := GRAPH_CHANNEL_MAX - GRAPH_CHANNEL_MIN;

 ofs := ofs - (page_size div 2);
 ofs := math.Max(ofs, ScrollBarY.Min);
 ofs := math.Min(ofs, ScrollBarY.Max);

 ScrollBarY.Position := ScrollBarY.Min;
 ScrollBarY.PageSize := page_size;
 ScrollBarY.Position := ofs;

 ScrollBarY.SmallChange := math.Max(1, page_size div 100);
 ScrollBarY.LargeChange := math.Max(1, page_size div 2);
 zoom_shift_y := 0;
end;

procedure TGraphLinesForm.FormResize(Sender: TObject);
begin
 reinit_bmp;
end;

procedure TGraphLinesForm.SpeedRadioGroupClick(Sender: TObject);
begin
 reinit_scroller_x;
end;

procedure TGraphLinesForm.AmpRadioGroupClick(Sender: TObject);
begin
 reinit_scroller_y;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.PauseCheckBoxClick(Sender: TObject);
begin
 XScrollBar.Enabled := PauseCheckBox.Checked;

 if not PauseCheckBox.Checked then
  begin
   info_line_enbled := false;
   XScrollBar.Position := XScrollBar.Max - XScrollBar.PageSize;
   if fifo.ratio_free <= 1 then
    ShowMessage('Warning: Connection overfulled!');
  end;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.YZeroButtonClick(Sender: TObject);
begin
 ScrollBarY.Position := ((ScrollBarY.max - ScrollBarY.min) div 2) - (ScrollBarY.PageSize div 2);
end;

procedure TGraphLinesForm.YMinButtonClick(Sender: TObject);
begin
 ScrollBarY.Position := ScrollBarY.Max - ScrollBarY.PageSize;
end;

procedure TGraphLinesForm.YMaxButtonButtonClick(Sender: TObject);
begin
 ScrollBarY.Position := ScrollBarY.min;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.ScreenShotButtonClick(Sender: TObject);
var
 fn : string;
 add : string;
begin
 add := InputBox('Screenshot caption', 'Screenshot caption', '');
 add := normalize_filename(add);
 if add <> '' then
  add := '_' + add;
{$i-}
 fn := ExtractFilePath(paramstr(0))+ SCREENSHOT_DIR;
 MkDir(fn);
 IOResult;
{$i+}
 fn := fn + '\' + date_time_filename + add + '.bmp';
 try
  bitmap.SaveToFile(fn);
 except
  ShowMessage('ERROR: Can''t save screenshot to file'#13 + fn);
  exit;
 end;
 ShowMessage('Saved screenshot to file'#13 + fn);
 last_screenshot := fn;
 LastScreenshotLabel3.Caption := LastScreenshotLabel2.Caption;
 LastScreenshotLabel2.Caption := LastScreenshotLabel1.Caption;
 LastScreenshotLabel1.Caption := ExtractFileName(fn);
end;

procedure TGraphLinesForm.ScreenShotButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 last_screenshot := ExtractFilePath(paramstr(0))+ SCREENSHOT_DIR + '\' +(sender as TLabel).Caption;
 last_screenshot_show := (last_screenshot <> '') and FileExists(last_screenshot);
end;

procedure TGraphLinesForm.ScreenShotButtonMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 last_screenshot_show := false;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

function TGraphLinesForm.bmpX_to_index(x:integer):integer;
var
 speed : double;
 speed_step : integer;
 speed_mult : integer;
begin
 speed := calc_speed;
 speed_step := math.Max(1, round(1 / speed));
 speed_mult := math.Max(1, round(speed));

 x := bitmap.Width - x;
 result := lines[0].calc_ofs(x div speed_step, calc_ofs, speed_mult);
end;

procedure TGraphLinesForm.FFTCheckBoxClick(Sender: TObject);
begin
 if FFTCheckBox.Checked then
  ArmkaFFT_Form.Show
 else
  ArmkaFFT_Form.hide;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TGraphLinesForm.update_fft;
var
 x_center : integer;
 window : integer;
 x1 : integer;
 x2 : integer;
 data : tLineItems_doubles;
 chanel : integer;
begin
 if ArmkaFFT_Form.Visible then
  if (ctrl.line_marked >= 0) or (ctrl.enabled_count = 1) then
   begin
    x_center := (bitmap.Width - info_line_x) div calc_speed_step;
    window := round((1 shl ArmkaFFT_Form.fft.get_power) / calc_speed);

    x1 := x_center - (window div 2);
    x2 := x_center + (window div 2);
    if x1 < 0 then
     begin
      x2 := x2 + (-x1) - 1;
      x1 := 0;
     end;

    chanel := ctrl.line_marked;
    if chanel < 0 then
     chanel := ctrl.enabled_last;

    data := Lines[chanel].import_doubles(x1, x2, calc_ofs, calc_speed_mult);
    if Length(data) > 0 then
     begin
      ArmkaFFT_Form.calc_data(@data[0], length(data));
      ArmkaFFT_Form.redraw;
     end;
    SetLength(data, 0);
   end;
end;

procedure TGraphLinesForm.WndProc(var Message : TMessage);
begin
  if (Message.Msg = WM_SYSCOMMAND) and
     (Message.WParam = SC_KEYMENU) then
   Exit;

  inherited WndProc(Message);
end;
end.


