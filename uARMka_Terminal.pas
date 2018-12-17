unit uARMka_Terminal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, math, ComCtrls, registry, StdCtrls,
  //My_StdCtrls,
  comclient,
  linkclient,
  ulog_viewer,
  uFifo_map,
  uMAP_File,
  uMutex,
  uSimple_speed,
  shellapi,
  Unit_Win7Taskbar;

type
 tTerminal = class(tcomclient) end;

  TARMka_Terminal = class(TForm)
    SecondTimer: TTimer;
    ms100Timer: TTimer;
    ConnectButton: TButton;
    SendEdit: TEdit;
    StatusLabel: TLabel;
    SpeedComboBox: TComboBox;
    F1RadioButton: TRadioButton;
    F2RadioButton: TRadioButton;
    F3RadioButton: TRadioButton;
    F4RadioButton: TRadioButton;
    F5RadioButton: TRadioButton;
    F6RadioButton: TRadioButton;
    F7RadioButton: TRadioButton;
    F8RadioButton: TRadioButton;
    F9RadioButton: TRadioButton;
    F10RadioButton: TRadioButton;
    EvenComboBox: TComboBox;
    ProgressBar: TProgressBar;
    SendFileButton: TButton;
    ClearButton: TButton;
    SendButton: TButton;
    ms1Timer: TTimer;
    PaintBox1: TPaintBox;
    SmoothCheckBox: TCheckBox;
    DTRCheckBox: TCheckBox;
    RTSCheckBox: TCheckBox;
    StatusRNGLabel: TLabel;
    StatusDCDLabel: TLabel;
    StatusCTSLabel: TLabel;
    StatusDSRLabel: TLabel;
    GraphButton: TButton;
    DemoCheckBox: TCheckBox;
    FileOpenCheckBox: TCheckBox;
    t13incCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure SecondTimerTimer(Sender: TObject);
    procedure ms100TimerTimer(Sender: TObject);
    procedure ConnectButtonClick(Sender: TObject);
    procedure F10RadioButtonClick(Sender: TObject);
    procedure SendEditKeyPress(Sender: TObject; var Key: Char);
    procedure SpeedComboBoxChange(Sender: TObject);
    procedure EvenComboBoxChange(Sender: TObject);
    procedure SendEditKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SendFileButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure SendEditDblClick(Sender: TObject);
    procedure ms1TimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SmoothCheckBoxClick(Sender: TObject);
    procedure DTRCheckBoxClick(Sender: TObject);
    procedure GraphButtonClick(Sender: TObject);
    procedure t13incCheckBoxClick(Sender: TObject);
  private
   macros_old_index : integer;
   viewer : tlog_viewer;

  public
   connect_old_caption : string;

   device : tTerminal;
   device_info_name : string;

   data_file : file;
   data_file_enable : boolean;

   stat_readed : integer;

   data_main : TMemoryStream;
   data_new  : TMemoryStream;

   macros_list : tstringlist;
   reconnect : boolean;
   reconnect_close : boolean;
   reconnect_open  : boolean;

   sending      : boolean;
   sending_wait : boolean;
   sending_file : file;
   sending_size : int64;
   sending_pos  : int64;
   sending_start : int64;

   graph_fifo : tFIFO_map;
   graph_fifo_name : string;

   speeder : tSimple_speed;

   file_rx_sign : int64;
   file_rx_state : (file_rx_state_find = 0, file_rx_state_body);
   file_rx_pos  : integer;
   file_rx_name : ansistring;
   file_rx_size : cardinal;
   file_rx_info : array [0..127] of byte;
   file_rx_data : array of byte;

   t13inc_last : byte;
   t13inc_norm : int64;
   t13inc_err  : int64;

   procedure data_add(data:pbyte; size:integer);
   procedure data_add_string(s:string);

   procedure device_rx(sender:tLinkClient; data:pbyte; size:integer);
   function  device_onFastRx(sender:tLinkClient; data:pbyte; size:integer):boolean;
   procedure device_connect(sender:tLinkClient);
   procedure device_disconnect(sender:tLinkClient);

   procedure file_rx_reset;
   procedure file_rx_save_reset;
   procedure file_rx_process(data:pbyte; size:integer; nd:pbyte; var ns:integer);

   procedure macross_save;
   function  macross_load:boolean;

   procedure send_str(str:string);
   procedure send_start;
   procedure send_stop;
   procedure send_update;

   procedure hints_update;
   procedure StatusUpdate;
   procedure make_demo_str;
   procedure check_demo;
  end;

var
  ARMka_Terminal: TARMka_Terminal;

implementation

uses
 uARMka_prog_form,
 uARMka_log_form;

{$R *.dfm}

const
 LOG_NAME = 'ARMkaTerminal.log';
 MACROSS_PATH  = '\Software\ARMka\Terminal\Macross';
 MACROSS_ITEM_NAME  = 'F';

 CUT_NOTIFY_STRING1 = '========= Cutted for perfomance ========';
 CUT_NOTIFY_STRING2 = 'Full log in file: ';
 CUT_NOTIFY_STRING3 = '========================================';

procedure _INFO(var v);
begin
end;

function  cmd_str_conv(s:ansistring):ansistring;
var
 stop:boolean;
 c,c1,c2:byte;
 p:integer;

function get_c:byte;
begin
{ result:=0;
{ if length(s)<p then
  begin
   stop:=true;
   exit;
  end;}
 result:=ord(s[p]);
 if p<length(s) then inc(p) else stop:=true;
end;

procedure add_b(cc:byte);
begin
 result:=result+chr(cc);
end;

begin
 result:='';
 if s='' then exit;
 p:=pos(' // ',s);
 if p>0 then
  s:=copy(s,1,p-1);
 if s='' then exit;
 p:=1;
 stop:=false;
 repeat
  c:=get_c;
  if c=ord('$') then
   begin
    c1:=get_c;
    if c1<>ord('$') then
     begin
      c2:=get_c;
      if (chr(c1) in ['0'..'9','A'..'F'])and(chr(c2) in ['0'..'9','A'..'F']) then
       begin
        c:=0;
        if c1<ord('A') then c:=c+(c1-ord('0')) shl 4 else c:=c+(c1-ord('A')+10) shl 4;
        if c2<ord('A') then c:=c+(c2-ord('0')) shl 0 else c:=c+(c2-ord('A')+10) shl 0;
       end
      else
       begin
        add_b(c);
        add_b(c1);
        c:=c2;
       end;
     end;
   end;
  add_b(c);
 until stop;
end;

procedure TARMka_Terminal.send_str(str:string);
begin
 if device.state <> link_establish then exit;

 if sending then
  begin
   ShowMessage('ERROR: Can''t send command while sending file');
   exit;
  end;

 str := cmd_str_conv(str);
 if str<>'' then
  device.Write(@(str[1]), length(str));
end;

procedure TARMka_Terminal.data_add(data:pbyte; size:integer);
begin
 if size = 0 then exit;
 data_new.Write(data^, size);
end;

procedure TARMka_Terminal.data_add_string(s:string);
begin
 s:=s+#13;
 dec(stat_readed, length(s));
 data_add(@(s[1]), length(s));
end;

function nowtime_filename:ansistring;
var
 t : TDateTime;
 h,m,s,ms : word;
 yy, mm, dd : word;
begin
 t := now;
 DecodeTime(t, h, m, s, ms);
 DecodeDate(t, yy, mm, dd);
 result := '';
 result := result + format('%.4d', [yy]) + '-';
 result := result + format('%.2d', [mm]) + '-';
 result := result + format('%.2d', [dd]) + ' ';
 result := result + format('%.2d', [h]) + '_';
 result := result + format('%.2d', [m]) + '_';
 result := result + format('%.2d', [s]) ;
end;

procedure TARMka_Terminal.file_rx_reset;
begin
 file_rx_state := file_rx_state_find;
 ZeroMemory(@file_rx_info, sizeof(file_rx_info));
 SetLength(file_rx_data, 0);
 file_rx_pos := 0;
 file_rx_size := 0;
 file_rx_name := '';
 file_rx_sign := 0;
end;

procedure TARMka_Terminal.file_rx_save_reset;
var
 fn : ansistring;
begin
 if file_rx_state = file_rx_state_body then
  if file_rx_size > 0 then
   begin
    {$I-}
    MkDir('log_files');
    ioresult;
    {$I+}
    fn := 'log_files\' +nowtime_filename + ' ' + file_rx_name;
    stm32_save_file(fn, @file_rx_data[0], file_rx_size);
    if FileOpenCheckBox.Checked then
     ShellExecute(self.Handle, 'open', pchar(fn), nil, nil, SW_SHOWNORMAL) ;
    data_add_string('');
    data_add_string('--------------------------');
    data_add_string('Saved to:  '#09 + fn);
    data_add_string('File size: '#09 + inttostr(file_rx_size));
    if file_rx_pos < file_rx_size then
     data_add_string('ERROR: received only:'#09 + inttostr(file_rx_pos));
    data_add_string('--------------------------');
   end;
 file_rx_reset;
end;

procedure TARMka_Terminal.file_rx_process(data:pbyte; size:integer; nd:pbyte; var ns:integer);
var
 b : byte;
begin
 ns := 0;
 if file_rx_state = file_rx_state_find then
  begin
   while (size > 0) do
    begin
     if byte(t13inc_last + 13) = data^ then
      begin
      inc(t13inc_norm);
      if (t13inc_norm = 1) and (t13inc_err = 1) then
       t13inc_err := 0;
      end
     else
      inc(t13inc_err);
     t13inc_last := data^;

     file_rx_sign := (file_rx_sign shl 8) or data^;
     nd^ := data^;
     inc(nd);
     inc(ns);
     inc(data);
     dec(size);

     if file_rx_sign = $1298347650FDECAB then
      begin
       file_rx_reset;
       file_rx_state := file_rx_state_body;
       break;
      end;
    end;
  end;

 if size = 0 then exit;
 if file_rx_state <> file_rx_state_body then exit;

 while (size > 0) do
  begin
   b := data^;
   inc(data);
   dec(size);

   if file_rx_size = 0 then
    begin
     file_rx_info[file_rx_pos] := b;
     inc(file_rx_pos);

     if ((file_rx_pos > 4) and (b = 0)) then
      begin
       file_rx_pos := 0;
       file_rx_name := pansichar(@file_rx_info[4]);
       file_rx_size := (cardinal(file_rx_info[0]) shl  0)
                    or (cardinal(file_rx_info[1]) shl  8)
                    or (cardinal(file_rx_info[2]) shl 16)
                    or (cardinal(file_rx_info[3]) shl 24);

       if (file_rx_size <= 0) or (file_rx_size > 1000000000) then
        begin
         file_rx_reset;
         file_rx_process(data, size, nd, ns);
         exit;
        end
       else
        SetLength(file_rx_data, file_rx_size);
      end;
    end
   else
    begin
     file_rx_data[file_rx_pos] := b;
     inc(file_rx_pos);

     if (file_rx_pos >= file_rx_size) then
      begin
       file_rx_save_reset;
       file_rx_process(data, size, nd, ns);
       exit;
      end;
    end;
  end;
end;

procedure TARMka_Terminal.device_rx(sender:tLinkClient; data:pbyte; size:integer);
var
 nd : pbyte;
 ns : integer;
begin
 if data_file_enable then
  begin
   {$I-}
   BlockWrite(data_file, data^, size);
   {$I+}
   if ioresult <> 0 then
    begin
     ARMka_prog_form.log('Terminal log file write error');
     data_file_enable := false;
    end;
  end;

 //linesform.onRX(data, size);

 ns := 0;
 GetMem(nd, size);
 //data_add(data, size);
 file_rx_process(data, size, nd, ns);
 data_add(nd, ns);
 FreeMemory(nd);
end;

procedure TARMka_Terminal.device_connect(sender:tLinkClient);
begin
 data_add_string('================== Connect ===================');
 DTRCheckBoxClick(self);
 graph_fifo.reset;
 DemoCheckBox.Enabled := false;
 DemoCheckBox.Checked := false;
 file_rx_reset;
end;

procedure TARMka_Terminal.device_disconnect(sender:tLinkClient);
var
 c : ansichar;
 s : string;
begin
 ConnectButton.Caption := connect_old_caption;

 send_stop;
 file_rx_save_reset;
 s:='================= Disconnect =================';
 c:=' ';
 if data_main.Size > 0 then
  begin
   data_main.Seek(-1, soFromEnd);
   data_main.ReadBuffer(c, 1);
  end;
 if (c <> #13) and (c <> #10) then
   s:=#13+s;
 data_add_string(s);
 data_add_string('Date Time  : ' + DateToStr(Date)+' '+TimeToStr(Time));
 data_add_string('Device name: ' + device_info_name);
 data_add_string('');
 graph_fifo.reset;
 DemoCheckBox.Enabled := true;
end;

procedure TARMka_Terminal.FormCreate(Sender: TObject);
var
 k:integer;
begin
 ARMka_prog_form.Main_init;

 viewer := tLog_Viewer.create(PaintBox1, ARMka_log_form.ApplicationEvents1);
 viewer.colors_script_fname := ExtractFilePath(ParamStr(0)) + 'armka_terminal_colors_script.txt';
 SmoothCheckBoxClick(self);

 data_main := TMemoryStream.Create;
 data_new  := TMemoryStream.Create;

 device := tTerminal.Create($10000, $80000, $8000, $20000);
 device.no_activate := true;
 device.open_simple_fast := true;

 device.onLog      := ARMka_prog_form.log_add;
 device.onLogBegin := ARMka_prog_form.log_begin;
 device.onLogEnd   := ARMka_prog_form.log_end;

 device.onRX         := self.device_rx;
 device.onFastRx     := self.device_onFastRx;
 device.onConnect    := self.device_connect;
 device.onDisconnect := self.device_disconnect;

 data_file_enable := false;
 AssignFile(data_file, LOG_NAME);
 {$I-}
 Rewrite(data_file, 1);
 if IOResult<>0 then
  ARMka_prog_form.log(LOG_NAME+' file create error')
 else
  data_file_enable := true;
 {$I-}

 //Constraints.MinWidth := self.Width;

 macros_list := TStringList.Create;
 if not macross_load then
  begin
   macros_list.Add(SendEdit.Text);
   for k := 1 to 9 do
    macros_list.Add('void #'+inttostr(k+1));
  end
 else
  SendEdit.Text := macros_list.Strings[0];

 ProgressBar.DoubleBuffered := true;

 SendEdit.Hint := 'text for sending,'#13+'for unprinting charchers type in hex with $,'#13+'example ATD1234$0D';
{  'Текст для отправки в устройство'#13+
  'Для того чтоб отправить не текстовые символы,'#13+
  'Запишите их в 16 ричном виде через знак доллара $'#13+
  #13+
  'Например:'#13+
  'ATD1234$0D'#13+
  'текст "ATD1234" и символ с десятичным кодом 13 (перевод строки)';}

 hints_update;

 speeder := tSimple_speed.create;

 open_mutex_local := true;
 open_map_local := true;
 graph_fifo_name := 'tArmka_graph_fifo_' + inttohex(GetTickCount, 8);
 graph_fifo := tFIFO_map.create(graph_fifo_name, $200000, ARMka_prog_form.log);
 if not graph_fifo.create_writer then
  begin
   ARMka_prog_form.log('ERROR: not created: ' + graph_fifo_name);
   FreeAndNil(graph_fifo);
  end
 else
  ARMka_prog_form.log('Create: '+graph_fifo_name+' OK');
 ARMka_prog_form.graph_close_event := CreateEvent(nil, false, false, pchar(graph_fifo_name + '_close'));
end;

procedure TARMka_Terminal.SecondTimerTimer(Sender: TObject);
const
 post_init : integer = 0;
begin
 if ARMka_prog_form.device.State = link_idle then
  begin
   if post_init=1 then
    begin
     post_init := 2;
     if ARMka_prog_form.AutoTermCheckBox.Checked and (not self.Showing) then
      begin
       if not ARMka_Terminal.Showing then
        ARMka_Terminal.Show;
       ARMka_Terminal.SetFocus;
       ARMka_Terminal.ConnectButtonClick(nil);
      end
    end
   else
    inc(post_init);
  end;

 if device.State = link_establish then
  begin
   StatusLabel.Enabled := true;
   StatusLabel.Caption := 'RD : '+inttostr(round(speeder.read_reset))+' bps';
   if (file_rx_state = file_rx_state_body) then
    StatusLabel.Caption := StatusLabel.Caption + ' FileRX: ' + inttostr(file_rx_pos) + ' / ' + inttostr(file_rx_size);
   //StatusLabel.Caption := 'RD : '+inttostr(stat_readed)+' bps';
   if sending then
    StatusLabel.Caption := StatusLabel.Caption + ', sending : '+inttostr(sending_size)+' / '+IntToStr(sending_pos);
  end
 else
  begin
   StatusLabel.Enabled := False;
   StatusLabel.Caption := 'Disconnected';
  end;

 if (t13incCheckBox.Checked) then
  t13incCheckBox.caption := 'E:' + inttostr(t13inc_err) + ' N:' + inttostr(t13inc_norm)
 else
  t13incCheckBox.caption := 't13inc';

 stat_readed := 0;
end;

function SendTextMessage(Handle: HWND; Msg: UINT; WParam: WPARAM; LParam: pointer): LRESULT;
begin
  Result := SendMessageW(Handle, Msg, WParam, Windows.LPARAM(PWideChar(LParam)));
end;

procedure TARMka_Terminal.ms100TimerTimer(Sender: TObject);
var
 cnt : integer;
 pos : integer;
 a   : array[0 .. 1000000] of ansichar;
 s   : string;

 buf : array[0..255] of byte;
 readed : integer;

begin
 viewer.redraw;
 //check_demo;

 if sending then
  if sending_wait then
   begin
    if device.tx_fifo.data_count > 0 then
     begin
      sending_pos := device.stat_writed - sending_start;
      send_update;
     end
    else
     send_stop;
   end
  else
   begin
    while (device.tx_fifo.data_free >= sizeof(buf)) and (device.tx_fifo.blocks_free >= 1) do
     begin
      {$I-}
      readed := 0;
      BlockRead(sending_file, buf, sizeof(buf), readed);
      if IOResult <> 0 then
       begin
        ARMka_prog_form.log('ERROR: can''t read from sending file');
        send_stop;
        break;
       end
      else
       begin
        if readed = 0 then
         break;
        device.Write(@buf[0], readed);
        sending_pos := device.stat_writed - sending_start;
        send_update;
       end;
      {$I+}
     end;

    if readed < sizeof(buf) then
     sending_wait := true;
   end;
   
 if sending then
  begin
   SetTaskbarProgressValue(ProgressBar.Position, ProgressBar.Max);
   SetTaskbarProgressState(tbpsPaused);
  end;

 if reconnect then
  begin
   reconnect := false;
   reconnect_close := device.State <> link_idle;
  end;

 if reconnect_close then
  if device.State <> link_idle then
   begin
    ConnectButtonClick(ms100timer);
    reconnect_close := false;
    reconnect_open  := true;
   end;

 if reconnect_open then
  if device.State = link_idle then
   begin
    ConnectButtonClick(ms100timer);
    reconnect_open  := false;
   end;

 speeder.add_value(data_new.Size);

 if data_new.Size=0 then exit;

 inc(stat_readed, data_new.Size);
 data_new.SaveToStream(data_main);
 data_new.Clear;

 cnt := math.min(length(a)-1, data_main.Size);
 pos := data_main.Size - cnt;

 data_main.Seek(pos, soFromBeginning);
 data_main.Read(a[0], cnt);
 data_main.Clear;
 data_main.Write(a[0], cnt);
 data_main.Seek(0, soFromEnd);

 if cnt = length(a)-1 then
  begin
   s := CUT_NOTIFY_STRING1+#13+
        CUT_NOTIFY_STRING2+#13+
        ARMka_prog_form.current_dir+'\'+LOG_NAME+#13+
        CUT_NOTIFY_STRING3+#13;
   Move(s[1], a[0], length(s));
  end;

 viewer.text_update(a, cnt);
end;

procedure TARMka_Terminal.ConnectButtonClick(Sender: TObject);
var
 name : string;
begin
 send_stop;

 if connect_old_caption = '' then
  connect_old_caption :=ConnectButton.Caption;

 if ConnectButton.Caption = connect_old_caption then
  begin
   name := ARMka_prog_form.device_actual_name;
   device_info_name := ARMka_prog_form.DeviceSelectComboBox.Text;

   data_add_string('');
   data_add_string('Date Time  : ' + DateToStr(Date)+' '+TimeToStr(Time));
   data_add_string('Device name: ' + device_info_name);
   if name = '' then
    begin
     if sender <> nil then
      if sender.ClassName = tbutton.ClassName then
       showmessage('ERROR, device "'+ARMka_prog_form.DeviceSelectComboBox.Text+'" don''t connected');
     exit;
    end;

   device.port_name := name;

   try
    device.port_speed := strtoint(SpeedComboBox.text);
   except
    device.port_speed := CBR_115200;
   end;


   if EvenComboBox.ItemIndex = 0 then device.port_parity := NOPARITY;
   if EvenComboBox.ItemIndex = 1 then device.port_parity := EVENPARITY;
   if EvenComboBox.ItemIndex = 2 then device.port_parity := ODDPARITY;
   if EvenComboBox.ItemIndex = 3 then device.port_parity := MARKPARITY;
   if EvenComboBox.ItemIndex = 4 then device.port_parity := SPACEPARITY;

   device.no_activate := true;
   device.Open;

   ConnectButton.Caption := 'Disconnect';
  end
 else
  begin
   ConnectButton.Caption := connect_old_caption;
   device.Close;
  end;
end;

procedure TARMka_Terminal.F10RadioButtonClick(Sender: TObject);
var
 index : integer;
begin
 index := -1;
 macross_save;

 if Sender = F1RadioButton then index := 0;
 if Sender = F2RadioButton then index := 1;
 if Sender = F3RadioButton then index := 2;
 if Sender = F4RadioButton then index := 3;
 if Sender = F5RadioButton then index := 4;
 if Sender = F6RadioButton then index := 5;
 if Sender = F7RadioButton then index := 6;
 if Sender = F8RadioButton then index := 7;
 if Sender = F9RadioButton then index := 8;
 if Sender = F10RadioButton then index := 9;

 if index < 0 then exit;

 macros_list.Strings[macros_old_index] := SendEdit.Text;
 SendEdit.Text := macros_list.Strings[index];

 macros_old_index := index;
end;

procedure TARMka_Terminal.SendEditKeyPress(Sender: TObject; var Key: Char);
begin
 if key <> #13 then exit;

 send_str(SendEdit.Text);
end;

procedure TARMka_Terminal.SpeedComboBoxChange(Sender: TObject);
begin
 reconnect := true;
end;

procedure TARMka_Terminal.EvenComboBoxChange(Sender: TObject);
begin
 reconnect := true;
end;

procedure TARMka_Terminal.macross_save;
var
 reg:TRegistry;
 k : integer;
begin
 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_ALL_ACCESS;

 if not reg.OpenKey(MACROSS_PATH, True) then
  begin
   reg.CloseKey;
   reg.Free; reg := nil;

   ARMka_prog_form.log('ERROR: Can''t create '+MACROSS_PATH);
   ShowMessage('ERROR: Can''t create '+MACROSS_PATH);
   exit;
  end;

 for k:=0 to macros_list.Count-1 do
  reg.WriteString(MACROSS_ITEM_NAME+inttostr(k), macros_list.Strings[k]);

 reg.CloseKey;
 reg.Free; reg := nil;
end;

function  TARMka_Terminal.macross_load:boolean;
var
 reg:TRegistry;
 k : integer;
begin
 result := false;
 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_READ;

 if not reg.OpenKey(MACROSS_PATH, false) then
  begin
   ARMka_prog_form.log('INFO: macross in registry not found');
   reg.CloseKey;
   reg.Free; reg := nil;
   exit;
  end;

 macros_list.Clear;
 for k:=0 to 9 do
  macros_list.Add('load error from key'+MACROSS_PATH+'\'+MACROSS_ITEM_NAME+inttostr(k));

 for k:=0 to 9 do
  if reg.ValueExists(MACROSS_ITEM_NAME+inttostr(k)) then
   begin
    macros_list.Strings[k] := reg.ReadString(MACROSS_ITEM_NAME + inttostr(k));
    result := true;
   end;

 reg.CloseKey;
 reg.Free; reg := nil;
end;

procedure TARMka_Terminal.SendEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 macros_list.Strings[macros_old_index] := SendEdit.Text;
 hints_update;
end;

procedure TARMka_Terminal.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 if data_file_enable then
  begin
   {$I-}
   CloseFile(data_file);
   ioresult;
   {$I+}
   data_file_enable := false;
  end;
 //FreeAndNil(graph_fifo);
end;

procedure TARMka_Terminal.send_start;
var
 OpenDialog : TOpenDialog;
 current_dir : string;
 old_mode : integer;
begin
 if device.state <> link_establish then
  begin
   ShowMessage('ERROR: device dont present');
   exit;
  end;

 current_dir := GetCurrentDir;

 OpenDialog := TOpenDialog.Create(self);
 OpenDialog.FileName := '*.*';
 opendialog.Options  := [ofHideReadOnly,ofEnableSizing];

 //Sleep(2000);

 if not OpenDialog.Execute then
  begin
   {$I-}
   ChDir(current_dir);
   if IOResult<>0 then
    ARMka_prog_form.log('ERROR: Can''t change dir to '+current_dir);
   {$I+}
   OpenDialog.Free;
   exit;
  end;

 sleep(32);
 if device.state <> link_establish then
  begin
   ShowMessage('ERROR: device not connected');
   exit;
  end;

 {$I-}
 ChDir(current_dir);
 if IOResult<>0 then
  ARMka_prog_form.log('ERROR: Can''t change dir to '+current_dir);

 AssignFile(sending_file, openDialog.FileName);
 old_mode := FileMode;
 FileMode := fmOpenRead;
 Reset(sending_file, 1);
 if IOResult<>0 then
  begin
   ARMka_prog_form.log('ERROR: Can''t open sending file '+openDialog.FileName);
   {$I+}
   exit;
  end;
 FileMode := old_mode;

 sending := true;
 sending_wait := false;
 sending_size := filesize(sending_file);
 sending_pos  := 0;
 sending_start := device.stat_writed;
 {$I+}

 ProgressBar.Position := sending_pos;
 ProgressBar.Max      := sending_size;
 ProgressBar.Min      := 0;

 SendFileButton.Caption  := 'Stop ...';
 //SendFileButton.Hint     := 'Немедленно прервать отправку файла и сбросить буферы уарта.';

 ProgressBar.Visible := true;
 SendEdit.Visible    := false;
 SendButton.Visible  := false;
end;

procedure tarmka_terminal.send_update;
begin
 ProgressBar.Position := sending_pos;
end;

procedure TARMka_Terminal.send_stop;
begin
 if not sending then exit;

 {$I-}
 CloseFile(sending_file);
 if IOResult<>0 then
  ARMka_prog_form.log('ERROR: Can''t close sending file');
 {$I+}

 device.tx_fifo.reset;

 sending := false;
 sending_wait := false;
 sending_size := 1;
 sending_pos  := 0;

 SendFileButton.Caption  := 'Send file';
 //SendFileButton.Hint     := 'Отправка содержимого произвольного выбранного файла';

 ProgressBar.Visible := false;
 SendEdit.Visible   := true;
 SendButton.Visible := true;

 SetTaskbarProgressValue(1, 1);
 SetTaskbarProgressState(tbpsNormal);
end;

procedure TARMka_Terminal.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if key = vk_F1 then begin send_str(macros_list.Strings[0]); key := 0; end;
 if key = vk_F2 then begin send_str(macros_list.Strings[1]); key := 0; end;
 if key = vk_F3 then begin send_str(macros_list.Strings[2]); key := 0; end;
 if key = vk_F4 then begin send_str(macros_list.Strings[3]); key := 0; end;
 if key = vk_F5 then begin send_str(macros_list.Strings[4]); key := 0; end;
 if key = vk_F6 then begin send_str(macros_list.Strings[5]); key := 0; end;
 if key = vk_F7 then begin send_str(macros_list.Strings[6]); key := 0; end;
 if key = vk_F8 then begin send_str(macros_list.Strings[7]); key := 0; end;
 if key = vk_F9 then begin send_str(macros_list.Strings[8]); key := 0; end;
 if key = vk_F10 then begin send_str(macros_list.Strings[9]); key := 0; end;
end;

procedure TARMka_Terminal.SendFileButtonClick(Sender: TObject);
begin
 if sending then
  send_stop
 else
  send_start;
end;

procedure TARMka_Terminal.FormShow(Sender: TObject);
const
 first_show : boolean = true;
begin

 if first_show then
  begin
   first_show := false;
   self.Left := ARMka_prog_form.Left + ARMka_prog_form.Width;
   self.Top := ARMka_prog_form.Top;
  end;
end;

procedure TARMka_Terminal.ClearButtonClick(Sender: TObject);
begin
 data_main.Clear;
 viewer.text_update(nil, 0);
 self.repaint;
end;

procedure TARMka_Terminal.hints_update;
var
 k : integer;
 s : string;
begin
 s:='=== Macroses ===';
 for k:=0 to min(9, macros_list.Count-1) do
  s:=s+#13+'F'+inttostr(k+1)+' = '+macros_list.Strings[k];

 s := s + #13 + #13 +
 'Special prefix: '+ #13 +
 '['+GATE_LIB_SERIAL_PERFIX+']';

 F1RadioButton.Hint := s;
 F2RadioButton.Hint := s;
 F3RadioButton.Hint := s;
 F4RadioButton.Hint := s;
 F5RadioButton.Hint := s;
 F6RadioButton.Hint := s;
 F7RadioButton.Hint := s;
 F8RadioButton.Hint := s;
 F9RadioButton.Hint := s;
 F10RadioButton.Hint := s;
end;


procedure TARMka_Terminal.SendButtonClick(Sender: TObject);
begin
 send_str(SendEdit.Text);
end;

procedure TARMka_Terminal.SendEditDblClick(Sender: TObject);
begin
 send_str(SendEdit.Text);
end;

procedure TARMka_Terminal.ms1TimerTimer(Sender: TObject);
var
 dlt_pos : TPoint;
 new_pos : TPoint;
 s2n_len : integer;
 s2o_len : integer;
 n2o_len : integer;
const
 old_pos : TPoint = (x:0; y:0);
begin
 check_demo;
 viewer.onTimer(sender);
 StatusUpdate;

 new_pos.X := ARMka_prog_form.Left + ARMka_prog_form.Width;
 new_pos.Y := ARMka_prog_form.top;
 dlt_pos.X := new_pos.x - old_pos.X;
 dlt_pos.Y := new_pos.y - old_pos.y;

 n2o_len := round(sqrt(sqr(old_pos.x - new_pos.x) + sqr(old_pos.y - new_pos.y)));
 s2n_len := round(sqrt(sqr(self.Left - new_pos.x) + sqr(self.top  - new_pos.y)));
 s2o_len := round(sqrt(sqr(self.Left - old_pos.x) + sqr(self.top  - old_pos.y)));

 if (s2n_len < 20) and (s2n_len > 0) then
  begin
   self.Left := ARMka_prog_form.Left + ARMka_prog_form.Width;
   self.Top := ARMka_prog_form.Top;
  end;

 if (s2o_len = 0) and (n2o_len > 0) then
  begin
   self.Left := ARMka_prog_form.Left + ARMka_prog_form.Width;
   self.Top := ARMka_prog_form.Top;
  end;

 old_pos := new_pos;
end;

procedure TARMka_Terminal.FormResize(Sender: TObject);
begin
 if viewer = nil then exit;
 viewer.onResize(self);
 self.repaint;
end;

procedure TARMka_Terminal.SmoothCheckBoxClick(Sender: TObject);
begin
 if viewer = nil then exit;
 viewer.auto_scroll_smooth := SmoothCheckBox.Checked;
 viewer.auto_update_scroll := not SmoothCheckBox.Checked;
 self.Repaint;
end;

procedure TARMka_Terminal.DTRCheckBoxClick(Sender: TObject);
begin
 if device.state <> link_establish then exit;
 device.DTR := DTRCheckBox.Checked;
 device.RTS := RTSCheckBox.Checked;
end;

procedure TARMka_Terminal.StatusUpdate;
begin
 if device.state <> link_establish then
  begin
   StatusRNGLabel.Font.Color := rgb(100, 100, 100);
   StatusDCDLabel.Font.Color := rgb(100, 100, 100);
   StatusCTSLabel.Font.Color := rgb(100, 100, 100);
   StatusDSRLabel.Font.Color := rgb(100, 100, 100);
  end
 else
  begin
   if device.RNG then
    StatusRNGLabel.Font.Color := rgb(200, 0, 0)
   else
    StatusRNGLabel.Font.Color := rgb(0, 0, 0);

   if device.DCD then
    StatusDCDLabel.Font.Color := rgb(200, 0, 0)
   else
    StatusDCDLabel.Font.Color := rgb(0, 0, 0);

   if device.CTS then
    StatusCTSLabel.Font.Color := rgb(200, 0, 0)
   else
    StatusCTSLabel.Font.Color := rgb(0, 0, 0);

   if device.DSR then
    StatusDSRLabel.Font.Color := rgb(200, 0, 0)
   else
    StatusDSRLabel.Font.Color := rgb(0, 0, 0);

  end
end;

function  TARMka_Terminal.device_onFastRx(sender:tLinkClient; data:pbyte; size:integer):boolean;
begin
 if graph_fifo <> nil then
  graph_fifo.write(data, size);
 result := true;
end;

procedure TARMka_Terminal.GraphButtonClick(Sender: TObject);
begin
 ShellExecute(self.Handle, 'open', 'ARMka_Graph.exe', pchar(graph_fifo_name), nil, SW_SHOW);
end;

procedure TARMka_Terminal.check_demo;
var
 cnt : integer;
begin
 if not DemoCheckBox.Checked then exit;
 if device.State = Link_establish then exit;

 for cnt := 0 to 100 do
// while device.rx_fifo.free_ratio > 10 do
  make_demo_str;
end;

procedure TARMka_Terminal.make_demo_str;
const
 cnt : int64 = 0;
 dir : integer = +17;
 pp : integer = 0;
 rnd : integer = 0;
 stream_sample_freq_real = 32000.0;
var
 chanels : array[0..23] of smallint;
 pos : integer;
 str : string;
 amp : double;

begin
 inc(cnt);
 chanels[0] := -$8000 + random(256);
 chanels[1] :=  $7FFF - random(256);
 chanels[2] :=  $0000 - random(256);
 chanels[3] :=  $0FFF - random(256);
 chanels[4] :=  $1FFF + random(256);

 chanels[5] := -$8000;
 chanels[6] :=  $0000;
 chanels[7] := +$7fff;

 chanels[8] := round(1000*sin(cnt / 100));
 chanels[9] := round(1000*sin(cnt / 111));
 chanels[10] := round(1000*sin(cnt / 77));

 chanels[11] := -chanels[8] + random(1000);
 chanels[12] := -chanels[9] + random(100);
 chanels[13] := -chanels[10] + random(10000);

 chanels[14] := chanels[11] + chanels[12];
 chanels[15]:= chanels[11] + chanels[12] + chanels[13];

 if (pp + dir) >= +$8000 then dir := dir * -1;
 if (pp + dir) <  -$8000 then dir := dir * -1;
 pp := pp + dir;
 chanels[16] := pp;
 chanels[17] := ((-pp*9) div 10)+ random(1000);

 rnd := math.min(+$7FFF, math.Max(-$8000, (rnd + random(1000) - 500)));
 chanels[18] := rnd;
 chanels[19] := math.min(+$7FFF, math.Max(-$8000, chanels[18] + chanels[17]));

 chanels[20] := round($4000*sin((cnt)/stream_sample_freq_real*1234.56789*2*pi));
 chanels[21] := (smallint(word((round(32000.0*sin(cnt/stream_sample_freq_real*1000.0*2.0*pi+0.0001*pi*2*sin(cnt/stream_sample_freq_real*40.0*2.0*pi))) and $FFC0)))) + random(16)+(cnt and 1) shl 7;

 amp := math.Max(0, 100*cos(cnt/10000*2*pi));
 if (cnt div 10000) mod 2 = 0 then
  amp := 100;
 chanels[22] := round(chanels[20] * amp / 1000);
 chanels[23] := round(3000*(2+sin(cnt/23))*sin((cnt)/stream_sample_freq_real * 1234.5678 *2*pi)) +
                 round(1000*(2+sin(cnt/100))*sin((cnt)/stream_sample_freq_real * 237 *2*pi)) +
                 round(4000*(2+sin(cnt/1000))*sin((cnt)/stream_sample_freq_real * 50 *2*pi)) ;

 str := '';
 for pos := 0 to length(chanels)-1 do
  str := str + #9 + inttostr(chanels[pos]);
 delete(str, 1, 1);

 graph_fifo.write_string(str);
 str := str + #13;
 device.rx_fifo.write_str(str);
end;

procedure TARMka_Terminal.t13incCheckBoxClick(Sender: TObject);
begin
 t13inc_last := 0;
 t13inc_norm := 0;
 t13inc_err := 0;
end;

end.
