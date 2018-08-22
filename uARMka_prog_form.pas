unit uARMka_prog_form;
//--áèòû çàùèòû

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, registry, ComCtrls, ShellApi, mmsystem,
  CP2102_classes,
  dev_msg_const,
  comclient,
  linkclient,
  Unit_Win7Taskbar,
  CRCunit,
  uAuto_Reconnect,
  SLABHIDtoUART;

const
 WM_USER_DEVICE_SELECT = WM_USER + 3413;

type
  tSTM32Boot = class(tComClient) end;

  TARMka_prog_form = class(TForm)
    DeviceSelectComboBox: TComboBox;
    DeviceSelectLabel: TLabel;
    Timer32ms: TTimer;
    LogButton: TButton;
    DeviceConnectedLabel: TLabel;
    SpeedComboBox: TComboBox;
    Label1: TLabel;
    FilenameEdit: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    OpenFileButton: TButton;
    SelectorARMkaRadioButton: TRadioButton;
    SelectorATMRadioButton: TRadioButton;
    SelectorGateRadioButton: TRadioButton;
    AutoWriteCheckBox: TCheckBox;
    HistoryListBox: TListBox;
    HistoryClearLabel: TLabel;
    SettingsRadioGroup: TRadioGroup;
    WriteButton: TButton;
    ProgressBar: TProgressBar;
    ReadButton: TButton;
    EraseButton: TButton;
    VerifyButton: TButton;
    StatusLabel: TLabel;
    LastNormalLabel: TLabel;
    ReadedInfoLabel: TLabel;
    TestCheckBox: TCheckBox;
    InfoLabel: TLabel;
    AutoBeepCheckBox: TCheckBox;
    DeviceLockedLabel: TLabel;
    ResetButton: TButton;
    TerminalButton: TButton;
    AutoTermCheckBox: TCheckBox;
    RDLockCheckBox: TCheckBox;
    UnLockCheckBox: TCheckBox;
    SelectorSFURadioButton: TRadioButton;
    procedure DeviceSelectComboBoxDropDown(Sender: TObject);
    procedure Timer32msTimer(Sender: TObject);
    procedure LogButtonClick(Sender: TObject);
    procedure DeviceSelectComboBoxChange(Sender: TObject);
    procedure OpenFileButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure HistoryClearLabelClick(Sender: TObject);
    procedure SettingsRadioGroupClick(Sender: TObject);
    procedure ReadButtonClick(Sender: TObject);
    procedure HistoryListBoxKeyPress(Sender: TObject; var Key: Char);
    procedure HistoryListBoxDblClick(Sender: TObject);
    procedure FilenameEditKeyPress(Sender: TObject; var Key: Char);
    procedure WriteButtonClick(Sender: TObject);
    procedure VerifyButtonClick(Sender: TObject);
    procedure EraseButtonClick(Sender: TObject);
    procedure AutoWriteCheckBoxClick(Sender: TObject);
    procedure InfoLabelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DeviceLockedLabelClick(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TerminalButtonClick(Sender: TObject);

  public
   refresh_timeout : int64;
   cp_list : tCP210x_enum;
   settings_old_index : integer;
   settings_lock : boolean;
   device : tSTM32Boot;
   last_10sec : cardinal;
   current_dir : string;

   debug_log_file : textfile;
   debug_log_enable : boolean;

   auto_lock : boolean;

   auto_data : array of byte;
   auto_crc  : integer;
   auto_time : integer;
   auto_size : integer;
   auto_name : string;

   auto_prepare_data : array of byte;
   auto_prepare_crc  : integer;
   auto_prepare_time : integer;
   auto_prepare_size : integer;
   auto_prepare_name : string;

   swarm_app_hwnd : cardinal;
   swarm_win_hwnd : cardinal;
   map_device : thandle;
   map_settings : thandle;

   form_initialized : boolean;
   showing_timeout : cardinal;

   terminal_reconnect : boolean;

   Auto_Reconnect : tAuto_Reconnect;

   graph_close_event : thandle;

   procedure log(s:string);
   procedure log_add(sender:tobject; s:string);
   procedure log_begin(sender:tlinkclient);
   procedure log_end(sender:tlinkclient);
   procedure ShowMessage(msg:string);

   procedure devices_update(set_name:string);

   procedure dbt_decode(ptr:cardinal);
   procedure DevChange(var Message: TMessage); message WM_DEVICECHANGE;

   procedure cp_list_update(log_event:tCP210x_log_event);
   procedure connected_check(correct : boolean);
   procedure connected_set(v:boolean);

   procedure history_save;
   procedure history_load;
   procedure history_add(s:string);
   procedure history_reset;

   function  settings_to_string:string;
   procedure settings_from_string(settings : string);
   procedure settings_save_reg;
   procedure settings_save_file;
   function  settings_load_reg:boolean;
   function  settings_load_file:boolean;

   function  device_actual_name : string;
   function  device_actual_speed : integer;
   procedure device_task(read, rdlock, unlock, erase, write, verify:boolean; fn:string; new:boolean);

   procedure auto_init;
   function  auto_check : boolean;
   procedure auto_commit_prepare_event(sender:tCOMClient; name:string; data:pointer; size:integer);
   procedure auto_commit_prepare(fn:string);
   procedure auto_commit_set;

   function  swarm_check(map_hnd : phandle; find_name : string):boolean;
   function  swarm_check_settings:boolean;
   function  swarm_check_device(find_name : string):boolean;
   function  swarm_check_device_again:boolean;
   procedure swarm_device_select(var Message: TMessage); message WM_USER_DEVICE_SELECT;
   procedure swarm_send_message(handle : HWND);

   procedure main_init;
  end;

var
  ARMka_prog_form: TARMka_prog_form;

const
 GATE_LIB_SERIAL_PERFIX = '#GateSN:';


implementation

uses uARMka_log_form, uARMka_Terminal;

procedure _inf(var v);
begin
end;

{$R *.dfm}
const
 DEVICES_UPDATE_FIRST = '<first>';
 DEVICES_UPDATE_VOID  = 'Please connect any CP21xx device';
 DEVICE_ARMKA_TITLE = 'ARMKA';
 LOG_NAME = 'ARMkaPROG.log';
 READED_FILE_NAME = 'readed.bin';

 SETTINGS_PATH = '\Software\ARMka\Prog\Settings';
 SETTINGS_NAME = 'ARMkaPROG.cfg';
 SETTINGS_FILE_NAME       = 'File';
 SETTINGS_DEVICE_NAME     = 'Device';
 SETTINGS_SPEED_NAME      = 'Speed';
 SETTINGS_AUTOPROG_NAME   = 'AutoProg';
 SETTINGS_ACTIVEMODE_NAME = 'ActiveMode';
 SETTINGS_AUTOBEEP_NAME   = 'AutoBeep';
 SETTINGS_AUTODATE_NAME   = 'AutoDate';
 SETTINGS_AUTOSIZE_NAME   = 'AutoSize';
 SETTINGS_AUTOCRC_NAME    = 'AutoCRC';
 SETTINGS_LOCK_NAME       = 'Lock';
 SETTINGS_UNLOCK_NAME     = 'UnLock';
 SETTINGS_TERM_SPEED_NAME  = 'Term_Speed';
 SETTINGS_TERM_PARITY_NAME = 'Term_Parity';
 SETTINGS_TERM_AUTO_NAME   = 'Term_Auto';


 SETTINGS_MODE_ARMKA_NAME = 'ARMka';
 SETTINGS_MODE_ATM_NAME   = 'ATM';
 SETTINGS_MODE_GATE_NAME  = 'GATE';
 SETTINGS_MODE_SFU_NAME   = 'SFU';

 HISTORY_PATH  = '\Software\ARMka\Prog\History';
 HISTORY_COUNT_NAME = 'Count';
 HISTORY_ITEM_NAME  = 'File_';

 PARAM_STR_SINGLE = 'SINGLE';
 PARAM_STR_HIDE   = 'HIDE';

 HIMITSU_PATH = 'Software\ARMka\KasukanaHimitsu';
 BAKA_PATH = 'Software\ARMka\BAKAHimitsu';
 APPEND_PATH  = 'Software\ARMka\Prog\DebugFileAppend';

 AUTO_WRITE_TIMEOUT = 3000;

function is_armka(name:string):boolean;
begin
 result:=pos(DEVICE_ARMKA_TITLE, name)>0;
end;

function is_com_port(name:string):boolean;
begin
 result:=pos('COM', name)=1;
end;

function next_dev_name(var names:string):string;
const
 name_set : set of char = ['A'..'Z', 'a'..'z', '_', '&', '#', '@', '%', '-', '0'..'9', 'à'..'ÿ', 'À'..'ß'];
begin
 result:='';

 while (length(names)>0) and (not (names[1] in name_set)) do
  begin
   if names[1]='[' then
    while (length(names)>0) and (names[1]<>']') do
     delete(names, 1, 1)
   else
    delete(names, 1, 1);
  end;

 while (length(names)>0) and (names[1] in name_set) do
  begin
   result:=result+names[1];
   delete(names, 1, 1);
  end;
end;

function find_device(cp:tCP210x_enum; names:string):integer;
var
 k : integer;
 n : string;
begin
 result:=-1;
 if cp = nil then exit;
 if cp.count < 1 then exit;

 while names <> '' do
  begin
   n := next_dev_name(names);

   if is_com_port(n) then
    for k:=0 to cp.count-1 do
     if cp.list[k].com_name = n then
      begin
       result:=k;
       exit;
      end;

    for k:=0 to cp.count-1 do
     if UpperCase(cp.list[k].serial) = UpperCase(n) then
      begin
       result:=k;
       exit;
      end;
  end;
end;

function find_cp2114(names:string):string;
var
 k : integer;
 n : string;
 list : tstringlist;
begin
 result:='';
 list := HidUart_ALL_serials(nil);
 //while names <> '' do
  begin
   n := names;
   //n := next_dev_name(names);

   for k:=0 to list.count-1 do
    if UpperCase(list.strings[k]) = UpperCase(n) then
     begin
      result := list.strings[k];
      FreeAndNil(list);
      exit;
     end;
  end;
 FreeAndNil(list);
end;

function find_com(names:string):string;
var
 k : integer;
 n : string;
 com_list:TStringList;
begin
 result:='';
 com_list := connected_com_ports(nil);

 while names <> '' do
  begin
   n := next_dev_name(names);

   for k:=0 to com_list.count-1 do
    if UpperCase(com_list.strings[k]) = UpperCase(n) then
     begin
      result:=com_list.strings[k];
      com_list.Free;
      com_list := nil;
      exit;
     end;
  end;

 com_list.Free;
 com_list := nil;
end;

function append_check:boolean;
var
 reg:tregistry;
begin
 reg := nil;
 try
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  reg.Access := KEY_READ;
  if not reg.OpenKey(APPEND_PATH, false) then
   begin
    reg.Free;
    reg := nil;
    result := false;
    exit;
   end;
 except
  if reg<>nil then
   reg.Free;
  reg := nil;
  result := false;
  exit;
 end;

 reg.Free;
 reg := nil;
 result := true;
 exit;
end;

procedure TARMka_prog_form.log(s:string);
begin
 s := DateToStr(Date)+' '+TimeToStr(Time)+#9+s;
 {$I-}
 if debug_log_enable then
  begin
   writeln(debug_log_file, s);
   if IOResult<>0 then
    debug_log_enable := false;
  end;

 if (not debug_log_enable) or (ARMka_log_form.Showing) then
  ARMka_log_form.add_log(s);
 {$I+}
end;

procedure TARMka_prog_form.ShowMessage(msg:string);
begin
 dialogs.ShowMessage(msg);
 log('ShowMessage : '+msg);
end;

var
 very_dirty_trick : boolean;

procedure TARMka_prog_form.log_add(sender:tobject; s:string);
begin
 log(s);
end;

procedure TARMka_prog_form.log_begin(sender:tlinkclient);
begin
 if not ARMka_log_form.Showing then exit;

 very_dirty_trick := true;
 ARMka_log_form.update_block := true;
end;

procedure TARMka_prog_form.log_end(sender:tlinkclient);
begin
 if not very_dirty_trick then
  if not ARMka_log_form.Showing then exit;

 very_dirty_trick := false;
 ARMka_log_form.update_block := false;
 ARMka_log_form.viewer_update;
end;

procedure TARMka_prog_form.cp_list_update(log_event:tCP210x_log_event);
begin
 if cp_list<>nil then
  begin
   cp_list.free;
   cp_list:=nil;
  end;

 cp_list:= tCP210x_enum.create(log_event);
end;

procedure TARMka_prog_form.dbt_decode(ptr:cardinal);
var
 broadcast_hdr  : ^_DEV_BROADCAST_HDR absolute ptr;
 broadcast_port : ^_DEV_BROADCAST_PORT absolute ptr;
begin
 if broadcast_hdr^.dbch_devicetype = DBT_DEVTYP_DEVICEINTERFACE then
  log(#9'DBT_DEVTYP_DEVICEINTERFACE') else
 if broadcast_hdr^.dbch_devicetype = DBT_DEVTYP_HANDLE then
  log(#9'DBT_DEVTYP_HANDLE') else
 if broadcast_hdr^.dbch_devicetype = DBT_DEVTYP_OEM then
  log(#9'DBT_DEVTYP_OEM') else
 if broadcast_hdr^.dbch_devicetype = DBT_DEVTYP_VOLUME then
  log(#9'DBT_DEVTYP_VOLUME') else
 if broadcast_hdr^.dbch_devicetype = DBT_DEVTYP_PORT then
  begin
   log(#9'DBT_DEVTYP_PORT');
   log(#9+string(broadcast_port^.dbcp_name));
  end;
end;

procedure TARMka_prog_form.DevChange(var Message: TMessage);
begin
 Message.Result:=1;
 log('');

 if (message.WParam=DBT_CONFIGCHANGECANCELED) then
  log('DBT_CONFIGCHANGECANCELED') else
 if (message.WParam=DBT_CONFIGCHANGED) then
  log('DBT_CONFIGCHANGED') else
 if (message.WParam=DBT_CUSTOMEVENT) then
  log('DBT_CUSTOMEVENT') else
 if (message.WParam=DBT_DEVICEARRIVAL) then
  begin log('DBT_DEVICEARRIVAL'); dbt_decode(message.LParam); end else
 if (message.WParam=DBT_DEVICEQUERYREMOVE) then
  log('DBT_DEVICEQUERYREMOVE') else
 if (message.WParam=DBT_DEVICEQUERYREMOVEFAILED) then
  log('DBT_DEVICEQUERYREMOVEFAILED') else
 if (message.WParam=DBT_DEVICEREMOVECOMPLETE) then
  begin log('DBT_DEVICEREMOVECOMPLETE'); dbt_decode(message.LParam); end else
 if (message.WParam=DBT_DEVICEREMOVEPENDING) then
  log('DBT_DEVICEREMOVEPENDING') else
 if (message.WParam=DBT_DEVICETYPESPECIFIC) then
  log('DBT_DEVICETYPESPECIFIC') else
 if (message.WParam=DBT_DEVNODES_CHANGED) then
  log('DBT_DEVNODES_CHANGED') else
 if (message.WParam=DBT_QUERYCHANGECONFIG) then
  log('DBT_QUERYCHANGECONFIG') else
 if (message.WParam=DBT_USERDEFINED) then
  log('DBT_USERDEFINED') else
  begin
   log('WParam'+inttohex(message.WParam, 8));
   log('LParam'+inttohex(message.LParam, 8));
  end;

 if (message.WParam=DBT_DEVICEARRIVAL) or
    (message.WParam=DBT_DEVICEREMOVECOMPLETE) or
    (message.WParam=DBT_DEVNODES_CHANGED) then
  refresh_timeout := 256;
end;

procedure TARMka_prog_form.devices_update(set_name:string);
var
 k:integer;
 s:string;

 com_list : TStringList;
 cp2114_list : tstringlist;
 index : integer;
begin
 if cp_list = nil then exit;
 DeviceSelectComboBox.Items.Clear;

 com_list := connected_com_ports(nil);
 for k:=0 to cp_list.count-1 do
  begin
   s:=cp_list.list[k].serial+' ['+cp_list.list[k].com_name+']';
   DeviceSelectComboBox.Items.Add(s);

   if com_list<>nil then
    begin
     index := 0;
     if com_list.Find(cp_list.list[k].com_name, index) then
      com_list.Delete(index);
    end;
  end;

 if com_list<>nil then
  begin
   for k:=0 to com_list.count-1 do
    DeviceSelectComboBox.Items.Add(com_list.Strings[k]);
   com_list.Free;
   com_list := nil;
  end;

 cp2114_list := HidUart_ALL_serials(self.log);
 for k:=0 to cp2114_list.count-1 do
  DeviceSelectComboBox.Items.Add(cp2114_list.Strings[k]);
 FreeAndNil(cp2114_list);

 if (set_name = DEVICES_UPDATE_FIRST) then
  begin
   if cp_list.count>0 then
    begin
     DeviceSelectComboBox.Text := cp_list.list[0].serial+' ['+cp_list.list[0].com_name+']';
     connected_set(true);
    end
   else
    DeviceSelectComboBox.Text := DEVICES_UPDATE_VOID;
  end
 else
  if set_name <> '' then
   DeviceSelectComboBox.Text := set_name;
end;

procedure TARMka_prog_form.DeviceSelectComboBoxDropDown(Sender: TObject);
begin
 devices_update('');
end;

procedure TARMka_prog_form.Main_init;
var
 reg:TRegistry;
 k:integer;
 s:string;

 param_single : boolean;
 param_hide   : boolean;
begin
 if form_initialized then exit;

 current_dir := GetCurrentDir;

 param_hide   := false;
 param_single := false;

 for k:=1 to ParamCount do
  begin
   s := paramstr(k);
   if s='' then exit;

   if length(s)>1 then
    begin
     if s[1]='/' then delete(s,1,1);
     if s[1]='-' then delete(s,1,1);
    end;
    
   if UpperCase(s) = UpperCase(PARAM_STR_HIDE)   then param_hide := true;
   if UpperCase(s) = UpperCase(PARAM_STR_SINGLE) then param_single := true;
  end;

 if not InitializeTaskbarAPI then
  Log('InitializeTaskbarAPI error, may be Win XP or older')
 else
  SetTaskbarProgressState(tbpsNone);

 {$I-}
  AssignFile(debug_log_file, LOG_NAME);

  if append_check then
   begin
    Append(debug_log_file);
    if IOResult=0 then
     debug_log_enable := true
    else
     begin
      rewrite(debug_log_file);
      if IOResult=0 then
       debug_log_enable := true;
     end;
   end
  else
   begin
    rewrite(debug_log_file);
    if IOResult=0 then
     debug_log_enable := true;
   end;
 {$I+}

 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_READ;
 if not reg.OpenKey(HIMITSU_PATH, false) then
  begin
   //SelectorARMkaRadioButton.Checked := true;
   //SelectorARMkaRadioButton.Visible := false;
   //SelectorATMRadioButton.Visible   := false;
   //SelectorGateRadioButton.Visible  := false;
   TestCheckBox.Visible := false;
  end;
 reg.CloseKey;
 if not reg.OpenKey(BAKA_PATH, false) then
  begin
   //SelectorARMkaRadioButton.Checked := false;
   //SelectorATMRadioButton.Checked   := false;
   //SelectorGateRadioButton.Checked  := true;
//   SelectorGateRadioButton.Enabled  := false;
//   SelectorATMRadioButton.Enabled   := false;
//   SelectorARMkaRadioButton.Enabled := false;
//   SelectorSFURadioButton.Enabled := false;
   //RDLockCheckBox.Checked := true;
   //UnLockCheckBox.Checked := true;
//   RDLockCheckBox.Enabled := false;
//   UnLockCheckBox.Enabled := false;
  end;                 
 reg.CloseKey;
 reg.Free;
 reg := nil;

 Timer32ms.Enabled := true;

 history_load;
 cp_list_update(log);

 settings_lock := true;
 if not settings_load_file then
  begin
   settings_old_index := 0;
   SettingsRadioGroup.ItemIndex := 0;
   if settings_load_reg then
    begin
     if DeviceSelectComboBox.Text = DEVICES_UPDATE_VOID then
      devices_update(DEVICES_UPDATE_FIRST)
    end
   else
    devices_update(DEVICES_UPDATE_FIRST);
  end
 else
  begin
   settings_old_index := 1;
   SettingsRadioGroup.ItemIndex := 1;
  end;
 settings_old_index := SettingsRadioGroup.ItemIndex;
 settings_lock := false;
 //connected_check(true);
 connected_check(false);

 if not swarm_check_settings then
  if (ParamCount>=1) and (param_single) then
   begin
    if not param_hide then
     swarm_send_message(swarm_win_hwnd);
    self.Close;
    exit;
   end
  else
   begin
    settings_lock := true;
    SettingsRadioGroup.ItemIndex := 2;
    settings_old_index := SettingsRadioGroup.ItemIndex;
    settings_lock := false;
    swarm_check_settings;
   end;

 device := tSTM32Boot.Create();
 device.onLog := self.log_add;
 device.onLogBegin := self.log_begin;
 device.onLogEnd := self.log_end;

 device.evWR_loaded := self.auto_commit_prepare_event;
 device.stm32_task_enable := true;
 device.cw_mini_detect_mode := true;

{ SettingsRadioGroup.Hint :=
  'Íàñòðîéêè ñîõðàíÿþòñÿ ïðè âûõîäå èç ïðîãðàììû'#13+
  'èëè ïðè ïåðåêëþ÷åíèè ìåæäó èñòî÷íèêàìè íàñòðîåê'#13+
  #13+
  'Òåêóùèé ïóòü ê ôàéëó ñ íàñòðîéêàìè:'#13+
  current_dir+'\'+SETTINGS_NAME+#13+
  #13+
  'Âåòêà ðååñòðà äëÿ ñîõðàíåíèÿ:'#13+
  '\\HKEY_CURRENT_USER'+SETTINGS_PATH+#13+
  #13+
  'Ñîäåðæèìîå:'#13+
  settings_to_string
   ;

 DeviceSelectComboBox.Hint :=
  'Ñþäà ìîæíî âïèñàòü:'#13+
  ' - Íîìåð êîì-ïîðòà, íàïðèìåð COM3 èëè ...'#13+
  ' - Ñåðèéíûé íîìåð çàøèòûé â CP2102 (ëþáîé, íå îáÿçàòåëüíî ÀÐÌêó)'#13+
  #13+
  'Ìîæíî âïèñàòü ÷åðåç ïðîáåë â íà÷àëå ñåðèéíèê ïîòîì êîì ïîðò èëè íàîáîðîò,'#13+
  'ïðîãðàììà ïîïûòàåòñÿ â íà÷àëå îòêðûòü ïåðâîå ñëîâî,'#13+
  'åñëè íå äîñòóïíî ïåðâîå òî îòêðîåò âòîðîå è òä ïî ñïèñêó'#13+#13+
  'Âíèìàíèå: Òî ÷òî çàêëþ÷åíî â êâàäðàòíûå ñêîáî÷êè áóäåò ïðîèãíîðèðîâàíî,'#13+
  'íàïðèìåð ARMka_1234 [COM2] - ïîèñê áóäåò ïðîèçâåä¸í òîëüêî ïî ñåðèéíèêó'
  ;

 AutoWriteCheckBox.Hint :=
  'Àâòîïðîøèâêà:'#13+
  #13+
  'Åñëè:'#13+
  ' - ôàéë äëÿ ïðîøèâêè óêàçàí, îí îòêðûâàåòñÿ, ÷èòàåòñÿ è íå ðàâåí 0 áàéò,'#13+
  ' - óñòðîéñòâî óêàçàííîå âûøå ïîäêëþ÷åíî'#13+
  ' - óêàçàííûé ôàéë ïðîøèâêè èçìåíèëñÿ'#13+
  #13+
  'òî:'#13+
  ' - ïûòàåòñÿ ïðîøèòü äî òåõ ïîð ïîêà íå óäàñòñÿ ïðîøèòü è ïðîéòè âåðèôèêàöèþ'#13+
  ' - òàéìàóò ïîïûòîê - 5 ñåêóíä.'
 ;

 SpeedComboBox.Hint :=
  'Ñêîðîñòü â áîäàõ'#13+
  'Äëÿ ïðîøèâêè STM32F1xx:'#13+
  'Ìèíèìàëüíàÿ 1200 áîä'#13+
  'Ðåêîìåíäîâàííàÿ ìàêñèìàëüíàÿ 115200 áîä'#13+
  'Ìîæíî âûøå, íî ãàðàíòèé íå äà¸ì!!!';

 AutoTermCheckBox.hint := 'Àâòîïîäêëþ÷èòü òåðìèíàë ïîñëå ðàáîòû ïðîãðàììàòîðà èëè àâòîïðîøèâêè';

 AutoBeepCheckBox.Hint :=
  'Â ñëó÷àå óäà÷íîé àâòîïðîøèâêè áóäåò ïðîèãðàí çâóê.'#13+
  'Åñëè â ïàïêå ñ ïðîãðàììîé åñòü ôàéë beep.wav, òî èç íåãî'#13+
  'Åñëè íåò òî ñèñòåìíûé çâóê îïîâåùåíèÿ.'#13+
  ' '#13+
  'ôîðìàò ôàéëà beep.wav : íåñæàòûé PCM 16 áèò ñòåðåî';

 ReadButton.Hint :=
  'Ïðîøèâêà áóäåò ñîõðàíåíà â ôàéë:'+#13+
  current_dir+'\readed.bin';

 FilenameEdit.Hint := 'ÂÍÈÌÀÍÈÅ!!! Ïîääåðæèâàþòñÿ òîëüêî:'+#13+
 'áèíàðíûå ôàéëû *.bin' + #13+
 'è Intel-HEX *.hex ôàéëû';

 HistoryListBox.Hint := 'Ðàíåå âûáðàííûå ôàéëû'+#13+
 'ñîðòèðîâêà ïî äàòå ïîñëåäíåãî èñïîëüçîâàíèÿ';

 OpenFileButton.Hint := 'Âûáðàòü ôàéë ...';
}
 log('================================================================================================================ ');
 log('program start');
 log(' ');
 log(self.Caption);
 log('Version 1.0');
 log(' ');
 log('Copyright (c) 2012, www.armka.ru');
 log(' ');
 log('Permission is hereby granted, free of charge, to any person obtaining a copy');
 log('of this software and associated documentation files (the "Software"), to deal');
 log('in the Software without restriction, including without limitation the rights');
 log('to use, copy, modify, merge, publish, distribute, sublicense, and/or sell');
 log('copies of the Software, and to permit persons to whom the Software is');
 log('furnished to do so, subject to the following conditions:');
 log(' ');
 log('The above copyright notice and this permission notice shall be included in all');
 log('copies or substantial portions of the Software.');
 log(' ');
 log('THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR');
 log('IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,');
 log('FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE');
 log('AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER');
 log('LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,');
 log('OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE');
 log('SOFTWARE.');
 log(' ');
 log('|Russian license| ');
 log('Ðàçðåøàåòñÿ ïîâòîðíîå ðàñïðîñòðàíåíèå è èñïîëüçîâàíèå êàê â âèäå èñõîäíîãî êîäà,');
 log('òàê è â äâîè÷íîé ôîðìå, ñ èçìåíåíèÿìè èëè áåç, ïðè ñîáëþäåíèè ñëåäóþùèõ óñëîâèé:');
 log(' ');
 log('Ïðè ïîâòîðíîì ðàñïðîñòðàíåíèè èñõîäíîãî êîäà äîëæíî îñòàâàòüñÿ óêàçàííîå âûøå óâåäîìëåíèå îá àâòîðñêîì ïðàâå,');
 log(' ýòîò ñïèñîê óñëîâèé è ïîñëåäóþùèé îòêàç îò ãàðàíòèé.');
 log('Ïðè ïîâòîðíîì ðàñïðîñòðàíåíèè äâîè÷íîãî êîäà äîëæíà ñîõðàíÿòüñÿ óêàçàííàÿ âûøå èíôîðìàöèÿ îá àâòîðñêîì ïðàâå,');
 log(' ýòîò ñïèñîê óñëîâèé è ïîñëåäóþùèé îòêàç îò ãàðàíòèé â äîêóìåíòàöèè è/èëè â äðóãèõ ìàòåðèàëàõ,');
 log(' ïîñòàâëÿåìûõ ïðè ðàñïðîñòðàíåíèè.');
 log('Íè íàçâàíèå ARMka èëè ÀÐÌêà (íà êèðèëèöå), íè èìåíà åå ñîòðóäíèêîâ íå ìîãóò áûòü èñïîëüçîâàíû â êà÷åñòâå ïîääåðæêè');
 log(' èëè ïðîäâèæåíèÿ ïðîäóêòîâ, îñíîâàííûõ íà ýòîì ÏÎ áåç ïðåäâàðèòåëüíîãî ïèñüìåííîãî ðàçðåøåíèÿ.');
 log('ÝÒÀ ÏÐÎÃÐÀÌÌÀ ÏÐÅÄÎÑÒÀÂËÅÍÀ ÂËÀÄÅËÜÖÀÌÈ ÀÂÒÎÐÑÊÈÕ ÏÐÀÂ È/ÈËÈ ÄÐÓÃÈÌÈ ÑÒÎÐÎÍÀÌÈ «ÊÀÊ ÎÍÀ ÅÑÒÜ»');
 log(' ÁÅÇ ÊÀÊÎÃÎ-ËÈÁÎ ÂÈÄÀ ÃÀÐÀÍÒÈÉ, ÂÛÐÀÆÅÍÍÛÕ ßÂÍÎ ÈËÈ ÏÎÄÐÀÇÓÌÅÂÀÅÌÛÕ, ÂÊËÞ×Àß, ÍÎ ÍÅ ÎÃÐÀÍÈ×ÈÂÀßÑÜ ÈÌÈ,');
 log(' ÏÎÄÐÀÇÓÌÅÂÀÅÌÛÅ ÃÀÐÀÍÒÈÈ ÊÎÌÌÅÐ×ÅÑÊÎÉ ÖÅÍÍÎÑÒÈ È ÏÐÈÃÎÄÍÎÑÒÈ ÄËß ÊÎÍÊÐÅÒÍÎÉ ÖÅËÈ.');
 log('ÍÈ Â ÊÎÅÌ ÑËÓ×ÀÅ ÍÈ ÎÄÈÍ ÂËÀÄÅËÅÖ ÀÂÒÎÐÑÊÈÕ ÏÐÀÂ È ÍÈ ÎÄÍÎ ÄÐÓÃÎÅ ËÈÖÎ,');
 log(' ÊÎÒÎÐÎÅ ÌÎÆÅÒ ÈÇÌÅÍßÒÜ È/ÈËÈ ÏÎÂÒÎÐÍÎ ÐÀÑÏÐÎÑÒÐÀÍßÒÜ ÏÐÎÃÐÀÌÌÓ, ÊÀÊ ÁÛËÎ ÑÊÀÇÀÍÎ ÂÛØÅ, ÍÅ ÍÅÑ¨Ò ÎÒÂÅÒÑÒÂÅÍÍÎÑÒÈ,');
 log(' ÂÊËÞ×Àß ËÞÁÛÅ ÎÁÙÈÅ, ÑËÓ×ÀÉÍÛÅ, ÑÏÅÖÈÀËÜÍÛÅ ÈËÈ ÏÎÑËÅÄÎÂÀÂØÈÅ ÓÁÛÒÊÈ,');
 log(' ÂÑËÅÄÑÒÂÈÅ ÈÑÏÎËÜÇÎÂÀÍÈß ÈËÈ ÍÅÂÎÇÌÎÆÍÎÑÒÈ ÈÑÏÎËÜÇÎÂÀÍÈß ÏÐÎÃÐÀÌÌÛ (ÂÊËÞ×Àß, ÍÎ ÍÅ ÎÃÐÀÍÈ×ÈÂÀßÑÜ ÏÎÒÅÐÅÉ ÄÀÍÍÛÕ,');
 log(' ÈËÈ ÄÀÍÍÛÌÈ, ÑÒÀÂØÈÌÈ ÍÅÏÐÀÂÈËÜÍÛÌÈ, ÈËÈ ÏÎÒÅÐßÌÈ ÏÐÈÍÅÑÅÍÍÛÌÈ ÈÇ-ÇÀ ÂÀÑ ÈËÈ ÒÐÅÒÜÈÕ ËÈÖ,');
 log(' ÈËÈ ÎÒÊÀÇÎÌ ÏÐÎÃÐÀÌÌÛ ÐÀÁÎÒÀÒÜ ÑÎÂÌÅÑÒÍÎ Ñ ÄÐÓÃÈÌÈ ÏÐÎÃÐÀÌÌÀÌÈ), ÄÀÆÅ ÅÑËÈ ÒÀÊÎÉ ÂËÀÄÅËÅÖ');
 log(' ÈËÈ ÄÐÓÃÎÅ ËÈÖÎ ÁÛËÈ ÈÇÂÅÙÅÍÛ Î ÂÎÇÌÎÆÍÎÑÒÈ ÒÀÊÈÕ ÓÁÛÒÊÎÂ.');
 log(' ');
 log('HWND = '+inttohex(Self.Handle, 8));
 log(' ');

 Application.HintHidePause := 60000;

 Self.Constraints.MinHeight := Self.Height;
 Self.Constraints.MaxHeight := Self.Height;
 Self.Constraints.MinWidth := Self.Width;

 form_initialized := true;
 Application.ShowMainForm := true;
 Visible:=true;
 self.Show;

 Auto_Reconnect := tAuto_Reconnect.create('UniConsole', self.log);
end;

procedure TARMka_prog_form.Timer32msTimer(Sender: TObject);
const
 last_time : int64 = 0;
 last_prog : boolean = false;
 last_name : string = '';
 div16 : cardinal = 0;

 old_max : integer = 0;
 old_pos : integer = 0;

 single : boolean = false;

var
 new_max : integer;
 new_pos : integer;

 cur_time : int64;
 dlt_time : int64;
 prog : boolean;
 ProgressBarColor : tcolor;
 s:string;
begin
 if not form_initialized then exit;
 if single then exit;
 single := true;

 if IsIconic(Application.Handle) then
  showing_timeout := GetTickCount+500;

  
 inc(div16);
 if (div16 >= 16) then
  begin
   div16 := 0;

   if DeviceLockedLabel.Visible then
    if swarm_check_device_again then
     DeviceLockedLabel.Visible := false;
  end;

 if device <> nil then
  begin
   StatusLabel.Caption := 'State : '+device.stm32_info_string;

   new_max := device.stm32_info_progress_total;
   new_pos := device.stm32_info_progress_current;

   if (new_max<>old_max) or (new_pos <> old_pos) then
    begin
     ProgressBar.Max      := new_max;
     ProgressBar.Position := new_pos;
    end;

   old_max := new_max;
   old_pos := new_pos;

   prog := device.State <> link_idle;

   if prog then
    if device.stm32_info_progress_total < 10 then
     SetTaskbarProgressState(tbpsIndeterminate)
    else
     begin
      SetTaskbarProgressValue(device.stm32_info_progress_current, device.stm32_info_progress_total);
      SetTaskbarProgressState(tbpsPaused);
     end;


   if (last_prog = false) and (prog = true) then
    begin
     last_name := WriteButton.Caption;
     WriteButton.Caption := 'STOP';
     WriteButton.Font.Color := clMaroon;

     ReadButton.Enabled   := false;
     VerifyButton.Enabled := false;
     EraseButton.Enabled  := false;
     ResetButton.Enabled  := false;

     LastNormalLabel.Enabled := false;
     StatusLabel.font.Color  := clWindowText;
     StatusLabel.Enabled     := true;

     ProgressBar.Enabled := true;
     ProgressBar.Visible := true;

     ProgressBarColor:=GetSysColor(clHighlight and $FFFFFF);
     PostMessage(ProgressBar.Handle, $0409, 0, ProgressBarColor);
    end;

   if (last_prog = true) and (prog = false) then
    begin
     log(' ');
     log('End of task');
     Auto_Reconnect.send_end;

     if terminal_reconnect or AutoTermCheckBox.Checked then
      begin
       if AutoTermCheckBox.Checked then
        begin
         Application.Minimize;
         sleep(16); Application.ProcessMessages;
         sleep(16); Application.ProcessMessages;
         sleep(16); Application.ProcessMessages;
         sleep(16); Application.ProcessMessages;
         Application.Restore;

         if not ARMka_Terminal.Showing then
          ARMka_Terminal.Show;
         ARMka_Terminal.SetFocus;

         //Application.ProcessMessages; sleep(100); Application.ProcessMessages;
        end;

       terminal_reconnect := false;
       ARMka_Terminal.ConnectButtonClick(self);
      end;

     if last_name<>'' then
      WriteButton.Caption := last_name
     else
      WriteButton.Caption := 'WRITE';
     WriteButton.Font.Color := clWindowText;

     WriteButton.Enabled  := true;
     ReadButton.Enabled   := true;
     VerifyButton.Enabled := true;
     EraseButton.Enabled  := true;
     ResetButton.Enabled  := true;

     ProgressBar.Enabled := false;
     ProgressBarColor:=GetSysColor(clGrayText and $FFFFFF);
     PostMessage(ProgressBar.Handle, $0409, 0, ProgressBarColor);
     SetTaskbarProgressValue(1,1);
     SetTaskbarProgressState(tbpsNormal);

     if (device.stm32_info_result<>'') and (device.stm32_task_stop = false) then
      begin
       if device.stm32_task_read then
        begin
         ProgressBar.Visible := false;
         ReadedInfoLabel.Caption := 'Firmware saved in '+READED_FILE_NAME;
        end;

       if device.stm32_task_write and AutoWriteCheckBox.Checked then
        begin
         auto_commit_set;
        end;

       LastNormalLabel.Caption := 'Last: '+device.stm32_info_result +' OK';
       LastNormalLabel.Enabled := true;

       device.stm32_info_result := '';

       StatusLabel.Enabled    := false;
       StatusLabel.font.Color := clWindowText;

       if AutoWriteCheckBox.Checked and device.stm32_task_write and AutoBeepCheckBox.Checked then
        begin
         s:=ExtractFilePath(Application.ExeName)+'beep.wav';
         if not sndPlaySound(pchar(s), SND_ASYNC) then
          Beep;
        end;
      end
     else
      begin
       last_10sec := GetTickCount;

       StatusLabel.Enabled     := true;
       StatusLabel.font.Color  := clMaroon;
       LastNormalLabel.Enabled := false;
       SetTaskbarProgressState(tbpsError);
      end;
    end;

   last_prog := prog;
  end;

 if TestCheckBox.Checked and TestCheckBox.Visible then
  if VerifyButton.Enabled then
   VerifyButton.Click;

 if AutoWriteCheckBox.Checked and
   (GetTickCount - last_10sec >= AUTO_WRITE_TIMEOUT) and
   (device.State = link_idle) and
   (VerifyButton.Enabled)
 then
  begin
   last_10sec := GetTickCount;
   if auto_check then
    begin
     SetTaskbarProgressState(tbpsNone);
     WriteButton.Click;
    end;
  end;

 if cp_list = nil then
  begin
   single := false;
   exit;
  end;

 cur_time  := GetTickCount;
 dlt_time  := cur_time - last_time;
 last_time := cur_time;

 if refresh_timeout <= 0 then
  begin
   single := false;
   exit;
  end;
 refresh_timeout := refresh_timeout - dlt_time;
 if refresh_timeout > 0 then
  begin
   single := false;
   exit;
  end;

 cp_list_update(log);

 if DeviceSelectComboBox.Text = DEVICES_UPDATE_VOID then
  devices_update(DEVICES_UPDATE_FIRST)
 else
  connected_check(false);

 single := false;
end;

procedure TARMka_prog_form.LogButtonClick(Sender: TObject);
begin
 if ARMka_log_form.Showing then
  begin
   ARMka_log_form.Hide;
   if debug_log_enable then
    begin
     ARMka_log_form.log.Clear;
     ARMka_log_form.viewer_update;
    end
  end
 else
  begin
   if debug_log_enable then
    begin
     {$I-}
     CloseFile(debug_log_file);

     ARMka_log_form.log.LoadFromFile(LOG_NAME);
     ARMka_log_form.viewer_update;
     ARMka_log_form.viewer.scroll_bar_y.Position := ARMka_log_form.viewer.scroll_bar_y.max;

     append(debug_log_file);
     if IOResult<>0 then
      debug_log_enable := false;
     {$I+}

    end;
   ARMka_log_form.Show;
  end;
end;

procedure TARMka_prog_form.connected_check(correct : boolean);
var
 names    : string;
 num      : integer;
 com_name : string;
 cur_name : string;
const
 old_title : string = '';
begin
 if cp_list = nil then exit;

 if old_title = '' then
  old_title := self.caption;

 names := DeviceSelectComboBox.Text;
 if next_dev_name(names)='' then exit;

 num := find_device(cp_list, DeviceSelectComboBox.Text);
 if num<0 then
  begin
   com_name := find_com(DeviceSelectComboBox.Text);
   cur_name := com_name;
  end
 else
  cur_name := cp_list.list[num].serial;

 self.caption := old_title+' '+DeviceSelectComboBox.Text;//cur_name;
 Application.Title := self.Caption;

 if swarm_check_device(DeviceSelectComboBox.Text) then
  DeviceLockedLabel.Visible := false
 else
  DeviceLockedLabel.Visible := true;

 if is_cp2114(DeviceSelectComboBox.Text) then
  com_name := find_cp2114(DeviceSelectComboBox.Text);

 connected_set((num >= 0) or (com_name<>''));

 if correct and (num >= 0) then
  DeviceSelectComboBox.Text := cp_list.list[num].serial+' ['+cp_list.list[num].com_name+']';;
end;

procedure TARMka_prog_form.connected_set(v:boolean);
begin
 if v then
  begin
   DeviceConnectedLabel.Caption := 'Device present';
   DeviceConnectedLabel.Font.Color:=rgb(0,100,20);
  end
 else
  begin
   DeviceConnectedLabel.Caption := 'Device NOT PRESENT';
   DeviceConnectedLabel.Font.Color:=rgb(100,20,0);
  end;
end;

procedure TARMka_prog_form.DeviceSelectComboBoxChange(Sender: TObject);
begin
 connected_check(false);
 ARMka_Terminal.reconnect := true
end;

procedure TARMka_prog_form.OpenFileButtonClick(Sender: TObject);
var
 OpenDialog : TOpenDialog;
begin
 OpenDialog := TOpenDialog.Create(self);
 OpenDialog.DefaultExt := 'bin';
 OpenDialog.FileName := '';
 OpenDialog.Filter   := '(*.bin; *.hex)|*.bin;*.hex';
// OpenDialog.Filter   := 'binary file (*.bin)|*.bin Intel HEX (*.hex)|*.hex';
 opendialog.Options  := [ofHideReadOnly,ofEnableSizing];

 if not OpenDialog.Execute then
  begin
   {$I-}
   ChDir(current_dir);
   if IOResult<>0 then
    log('ERROR: Can''t change dir to '+current_dir);
   {$I+}
   OpenDialog.Free;
   exit;
  end;

 {$I-}
 ChDir(current_dir);
 if IOResult<>0 then
  log('ERROR: Can''t change dir to '+current_dir);
 {$I+}

 FilenameEdit.Text := openDialog.FileName;
 FilenameEdit.SelStart  := length(FilenameEdit.Text);
 FilenameEdit.SelLength := 0;

 history_add(FilenameEdit.Text);

 OpenDialog.Free;
end;

procedure TARMka_prog_form.history_add(s:string);
var
 k : integer;
 v : integer;
 max : integer;
 old_font : tfont;
begin
 for k:=0 to HistoryListBox.Items.Count-1 do
  if s=HistoryListBox.Items.Strings[k] then
   begin
    HistoryListBox.Items.Delete(k);
    self.history_add(s);
    HistoryListBox.ItemIndex := 0;
    exit;
   end;

 HistoryListBox.Items.Insert(0, s);

 max := 0;
 old_font := TFont.Create();
 old_font.Assign(HistoryListBox.Canvas.Font);

 HistoryListBox.Canvas.Font.Assign(HistoryListBox.Font);
 for k :=0 to HistoryListBox.Items.Count-1 do
  begin
   v := HistoryListBox.Canvas.TextWidth(HistoryListBox.Items.Strings[k]);
   if v>max then
    max:=v;
  end;

 HistoryListBox.Canvas.Font.Assign(old_font);
 old_font.Free;
 old_font:=nil;

 HistoryListBox.ScrollWidth := max+5;
end;

procedure TARMka_prog_form.history_load;
var
 reg:TRegistry;
 k : integer;
 count : integer;
begin
 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_READ;

 if not reg.OpenKey(HISTORY_PATH, false) then
  begin
   log('INFO: history in registry not found');
   reg.CloseKey;
   reg.Free; reg := nil;
   exit;
  end;

 if not reg.ValueExists(HISTORY_COUNT_NAME) then
  begin
   log('Warning: HISTORY_COUNT_NAME not found');
   reg.CloseKey;
   reg.Free; reg := nil;
   exit;
  end;
 count := reg.ReadInteger(HISTORY_COUNT_NAME);

 HistoryListBox.Items.Clear;

 for k:=0 to Count-1 do
  if reg.ValueExists(HISTORY_ITEM_NAME+inttostr(k)) then
   history_add(reg.ReadString(HISTORY_ITEM_NAME+inttostr(k)));

 reg.CloseKey;
 reg.Free; reg := nil;
end;

procedure TARMka_prog_form.history_save;
var
 reg:TRegistry;
 k : integer;
begin
 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_ALL_ACCESS;

 if not reg.OpenKey(HISTORY_PATH, True) then
  begin
   reg.CloseKey;
   reg.Free; reg := nil;

   ShowMessage('ERROR: Can''t create '+HISTORY_PATH);
   log('ERROR: Can''t create '+HISTORY_PATH);
   exit;
  end;

 reg.WriteInteger(HISTORY_COUNT_NAME, HistoryListBox.Items.Count);

 for k:=0 to HistoryListBox.Items.Count-1 do
  reg.WriteString(HISTORY_ITEM_NAME+inttostr(k), HistoryListBox.Items.Strings[HistoryListBox.Items.Count-1-k]);

 reg.CloseKey;
 reg.Free; reg := nil;
end;

procedure TARMka_prog_form.history_reset;
var
 reg:TRegistry;
begin
 HistoryListBox.Items.Clear;
 HistoryListBox.ScrollWidth := 0;

 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_ALL_ACCESS;

 if not reg.DeleteKey(HISTORY_PATH) then
  begin
   ShowMessage('ERROR: Can''t delete registry key '+HISTORY_PATH);
   reg.CloseKey;
   reg.Free; reg := nil;
   exit;
  end;

 reg.CloseKey;
 reg.Free; reg := nil;
end;


procedure TARMka_prog_form.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
 CanClose:=true;
 if not form_initialized then exit;

 if device <> nil then
  begin
   device.Close;
   device.Terminate;
  end;
 freeandnil(Auto_Reconnect); 

 history_save;
 ARMka_Terminal.macross_save;
 if SettingsRadioGroup.ItemIndex = 0 then settings_save_reg;
 if SettingsRadioGroup.ItemIndex = 1 then settings_save_file;
end;

procedure TARMka_prog_form.HistoryClearLabelClick(Sender: TObject);
begin
 if MessageDlg('Clear history?', mtConfirmation, mbOKCancel, 0) = mrOK then
  history_reset;
end;

function  TARMka_prog_form.settings_to_string:string;
var
 mode : string;
begin
 mode := '';
 if SelectorARMkaRadioButton.Checked then mode := SETTINGS_MODE_ARMKA_NAME;
 if SelectorATMRadioButton.Checked   then mode := SETTINGS_MODE_ATM_NAME;
 if SelectorGateRadioButton.Checked  then mode := SETTINGS_MODE_GATE_NAME;
 if SelectorSFURadioButton.Checked   then mode := SETTINGS_MODE_SFU_NAME;

 result :=
  SETTINGS_FILE_NAME+'        = ' + FilenameEdit.Text+#13#10+
  SETTINGS_DEVICE_NAME+'      = ' + DeviceSelectComboBox.Text+#13#10+
  SETTINGS_SPEED_NAME+'       = ' + SpeedComboBox.Text+#13#10+
  SETTINGS_ACTIVEMODE_NAME+'  = ' + mode+#13#10+
  SETTINGS_AUTOPROG_NAME+'    = ' + BoolToStr(AutoWriteCheckBox.Checked, true)+#13#10+
  SETTINGS_AUTOBEEP_NAME+'    = ' + BoolToStr(AutoBeepCheckBox.Checked, true)+#13#10+
  SETTINGS_LOCK_NAME+'        = ' + BoolToStr(RDLockCheckBox.Checked, true)+#13#10+
  SETTINGS_UNLOCK_NAME+'      = ' + BoolToStr(UnLockCheckBox.Checked, true)+#13#10+
  SETTINGS_AUTODATE_NAME+'    = ' + IntToStr(auto_time) +#13#10+
  SETTINGS_AUTOSIZE_NAME+'    = ' + IntToStr(auto_size) +#13#10+
  SETTINGS_AUTOCRC_NAME+'     = ' + IntToStr(auto_crc) +#13#10+
  SETTINGS_TERM_SPEED_NAME+'  = ' + ARMka_Terminal.SpeedComboBox.Text +#13#10+
  SETTINGS_TERM_PARITY_NAME+' = ' + ARMka_Terminal.EvenComboBox.Text +#13#10+
  SETTINGS_TERM_AUTO_NAME+'   = ' + BoolToStr(AutoTermCheckBox.Checked, true)
  ;
end;

procedure TARMka_prog_form.settings_from_string;
var
 p : integer;
 k : integer;
 line  : string;
 name  : string;
 value : string;
 prog_speed : string;
 term_speed : string;
 parity     : string;
 err : integer;
 num : integer;

function delete_end_spaces(s:string):string;
begin
 result:='';
 if s='' then exit;
 while (s<>'') and (s[length(s)] in [' ',#9]) do
  delete(s, length(s), 1);
 while (s<>'') and (s[1] in [' ',#9]) do
  delete(s, 1, 1);
 result := s;
end;

begin
 prog_speed := '';
 term_speed := '';
 parity     := '';

 while settings<>'' do
  begin
   line := '';
   while (settings<>'') and (settings[1]<>#13) and (settings[1]<>#10) do
    begin
     line := line + settings[1];
     delete(settings, 1, 1);
    end;

   while (settings<>'') and ((settings[1]=#13) or (settings[1]=#10)) do
    delete(settings, 1, 1);

   p:=pos('=', line);
   if p=0 then continue;

   name  := delete_end_spaces(copy(line, 1, p-1));
   value := delete_end_spaces(copy(line, p+1, 1024));

   if name='' then continue;

   if UpperCase(name) = UpperCase(SETTINGS_FILE_NAME)   then FilenameEdit.Text := value;
   if UpperCase(name) = UpperCase(SETTINGS_DEVICE_NAME) then DeviceSelectComboBox.Text := value;
   if UpperCase(name) = UpperCase(SETTINGS_SPEED_NAME)  then prog_speed := value;
   if UpperCase(name) = UpperCase(SETTINGS_TERM_SPEED_NAME)  then term_speed := value;
   if UpperCase(name) = UpperCase(SETTINGS_TERM_PARITY_NAME)  then parity := value;

   if UpperCase(name) = UpperCase(SETTINGS_AUTOPROG_NAME) then
    begin
     AutoWriteCheckBox.Checked := false;
     if pos('TRUE', UpperCase(value))<>0 then
      begin
       auto_lock := true;
       AutoWriteCheckBox.Checked := true;
       auto_lock := false;
      end;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_AUTOBEEP_NAME) then
    begin
     AutoBeepCheckBox.Checked := false;
     if pos('TRUE', UpperCase(value))<>0 then
      AutoBeepCheckBox.Checked := true;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_LOCK_NAME) then
    begin
     RDLockCheckBox.Checked := false;
     if pos('TRUE', UpperCase(value))<>0 then
      RDLockCheckBox.Checked := true;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_UNLOCK_NAME) then
    begin
     UNLockCheckBox.Checked := false;
     if pos('TRUE', UpperCase(value))<>0 then
      UNLockCheckBox.Checked := true;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_TERM_AUTO_NAME) then
    begin
     AutoTermCheckBox.Checked := false;
     if pos('TRUE', UpperCase(value))<>0 then
      AutoTermCheckBox.Checked := true;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_AUTODATE_NAME) then
    begin
     err := -1;
     val(value, num, err);
     if err = 0 then
      auto_time := num;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_AUTOSIZE_NAME) then
    begin
     err := -1;
     val(value, num, err);
     if err = 0 then
      auto_size := num;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_AUTOCRC_NAME) then
    begin
     err := -1;
     val(value, num, err);
     if err = 0 then
      auto_crc := num;
    end;

   if UpperCase(name) = UpperCase(SETTINGS_ACTIVEMODE_NAME) then
    begin
     if UpperCase(value) = UpperCase(SETTINGS_MODE_ARMKA_NAME) then SelectorARMkaRadioButton.Checked := true;
     if UpperCase(value) = UpperCase(SETTINGS_MODE_ATM_NAME)   then SelectorATMRadioButton.Checked   := true;
     if UpperCase(value) = UpperCase(SETTINGS_MODE_GATE_NAME)  then SelectorGateRadioButton.Checked  := true;
     if UpperCase(value) = UpperCase(SETTINGS_MODE_SFU_NAME)   then SelectorSFURadioButton.Checked   := true;
    end;
  end;

 if prog_speed<>'' then
  begin
   for k:=0 to SpeedComboBox.Items.Count-1 do
    if SpeedComboBox.Items.Strings[k] = prog_speed then
     begin
      SpeedComboBox.ItemIndex:=k;
      break;
     end;
   if k >= SpeedComboBox.Items.Count then
    log('Warning: Prog_Speed = '+prog_speed+' can''t found ');
  end;

 if term_speed<>'' then
  begin
   for k:=0 to ARMka_Terminal.SpeedComboBox.Items.Count-1 do
    if ARMka_Terminal.SpeedComboBox.Items.Strings[k] = term_speed then
     begin
      ARMka_Terminal.SpeedComboBox.ItemIndex:=k;
      break;
     end;
   if k >= ARMka_Terminal.SpeedComboBox.Items.Count then
    log('Warning: Term_Speed = '+term_speed+' can''t found ');
  end;

 if parity<>'' then
  begin
   for k:=0 to ARMka_Terminal.EvenComboBox.Items.Count-1 do
    if ARMka_Terminal.EvenComboBox.Items.Strings[k] = parity then
     begin
      ARMka_Terminal.EvenComboBox.ItemIndex:=k;
      break;
     end;
   if k >= ARMka_Terminal.EvenComboBox.Items.Count then
    log('Warning: Parity = '+Parity+' can''t found ');
  end;
end;

procedure TARMka_prog_form.settings_save_file;
var
 s : tstringlist;
begin
 s := tstringlist.Create;
 s.Text := settings_to_string;
 s.Insert(0,'ARMka configuration file');
 s.Insert(1,'');

 log('settings_save_file to path '+current_dir+'\'+SETTINGS_NAME);

 try
  s.SaveToFile(current_dir+'\'+SETTINGS_NAME);
 except
  ShowMessage('ERROR in save configuration file:'#13+current_dir+'\'+SETTINGS_NAME);
 end;
 s.Free;
 s:=nil;
end;

function TARMka_prog_form.settings_load_file;
var
 s : tstringlist;
 k:integer;
begin
 result := false;
 if not FileExists(SETTINGS_NAME) then exit;

 log('settings_load_file from path '+current_dir+'\'+SETTINGS_NAME);

 s := tstringlist.Create;
 try
  s.LoadFromFile(current_dir + '\' + SETTINGS_NAME);
 except
  log('INFO: local settings not found');
  s.Free;
  s:=nil;
  exit;
 end;
 log('Loaded settings:');
 log('=================================');
 for k:=0 to s.Count-1 do
  log(s.Strings[k]);
 log('=================================');
 settings_from_string(s.Text);
 s.Free;
 s:=nil;

 result := true;
end;

procedure TARMka_prog_form.settings_save_reg;
var
 reg:TRegistry;
begin
 reg := nil;
 try
   reg:=TRegistry.Create;
   reg.RootKey := HKEY_CURRENT_USER;
   reg.Access := KEY_ALL_ACCESS;

   if not reg.OpenKey(SETTINGS_PATH, True) then
    begin
     reg.CloseKey;
     reg.Free; reg := nil;

     ShowMessage('ERROR: Can''t create ' + SETTINGS_PATH);
     exit;
    end;

   log('settings_save_reg');

   reg.WriteString(SETTINGS_FILE_NAME,   FilenameEdit.text);
   reg.WriteString(SETTINGS_DEVICE_NAME, DeviceSelectComboBox.text);
   reg.WriteString(SETTINGS_SPEED_NAME,  SpeedComboBox.text);
   reg.WriteBool(SETTINGS_AUTOPROG_NAME, AutoWriteCheckBox.Checked);
   reg.WriteBool(SETTINGS_AUTOBEEP_NAME, AutoBeepCheckBox.Checked);
   reg.WriteBool(SETTINGS_LOCK_NAME,     RDLOCKCheckBox.Checked);
   reg.WriteBool(SETTINGS_UNLOCK_NAME,   UnlockCheckBox.Checked);

   reg.WriteString(SETTINGS_TERM_SPEED_NAME,  ARMka_Terminal.SpeedComboBox.text);
   reg.WriteString(SETTINGS_TERM_PARITY_NAME, ARMka_Terminal.EvenComboBox.text);
   reg.WriteBool(SETTINGS_TERM_AUTO_NAME,     AutoTermCheckBox.Checked);

   reg.WriteInteger(SETTINGS_AUTODATE_NAME, auto_time);
   reg.WriteInteger(SETTINGS_AUTOSIZE_NAME, auto_size);
   reg.WriteInteger(SETTINGS_AUTOCRC_NAME,  auto_crc);

   if SelectorARMkaRadioButton.Checked then reg.WriteString(SETTINGS_ACTIVEMODE_NAME, 'ARMka');
   if SelectorATMRadioButton.Checked   then reg.WriteString(SETTINGS_ACTIVEMODE_NAME, 'ATM');
   if SelectorGateRadioButton.Checked  then reg.WriteString(SETTINGS_ACTIVEMODE_NAME, 'GATE');
   if SelectorSFURadioButton.Checked   then reg.WriteString(SETTINGS_ACTIVEMODE_NAME, 'SFU');

 except
  log('ERROR : Registry settings write');
  if reg <> nil then
   begin
    reg.CloseKey;
    reg.Free; reg := nil;
   end;
  exit;
 end;

 reg.CloseKey;
 reg.Free; reg := nil;
end;

function TARMka_prog_form.settings_load_reg;
var
 reg : TRegistry;
 k   : integer;

 prog_speed : string;
 term_speed : string;
 parity     : string;

 mode  : string;
begin
 reg:=TRegistry.Create;
 reg.RootKey := HKEY_CURRENT_USER;
 reg.Access := KEY_READ;

 prog_speed := '';
 term_speed := '';
 parity     := '';

 log('settings_load_reg');

 try
  if not reg.OpenKey(SETTINGS_PATH, false) then
   begin
    log('INFO: '+SETTINGS_PATH+' not found in registry');
    reg.CloseKey;
    reg.Free; reg := nil;
    result := false;
    exit;
   end;

  if reg.ValueExists(SETTINGS_FILE_NAME)        then FilenameEdit.text         := reg.ReadString(SETTINGS_FILE_NAME);
  if reg.ValueExists(SETTINGS_DEVICE_NAME)      then DeviceSelectComboBox.text := reg.ReadString(SETTINGS_DEVICE_NAME);
  if reg.ValueExists(SETTINGS_SPEED_NAME)       then prog_speed                := reg.ReadString(SETTINGS_SPEED_NAME);
  if reg.ValueExists(SETTINGS_TERM_SPEED_NAME)  then term_speed                := reg.ReadString(SETTINGS_TERM_SPEED_NAME);
  if reg.ValueExists(SETTINGS_TERM_PARITY_NAME) then parity                    := reg.ReadString(SETTINGS_TERM_PARITY_NAME);

  if reg.ValueExists(SETTINGS_AUTOPROG_NAME)  then AutoWriteCheckBox.Checked := reg.ReadBool(SETTINGS_AUTOPROG_NAME);
  if reg.ValueExists(SETTINGS_AUTOBEEP_NAME)  then AutoBeepCheckBox.Checked  := reg.ReadBool(SETTINGS_AUTOBEEP_NAME);
  if reg.ValueExists(SETTINGS_LOCK_NAME)      then RDLockCheckBox.Checked    := reg.ReadBool(SETTINGS_LOCK_NAME);
  if reg.ValueExists(SETTINGS_UNLOCK_NAME)    then UnLockCheckBox.Checked    := reg.ReadBool(SETTINGS_UNLOCK_NAME);

  if reg.ValueExists(SETTINGS_TERM_AUTO_NAME) then AutoTermCheckBox.Checked  := reg.ReadBool(SETTINGS_TERM_AUTO_NAME);

  if reg.ValueExists(SETTINGS_AUTODATE_NAME) then auto_time  := reg.ReadInteger(SETTINGS_AUTODATE_NAME);
  if reg.ValueExists(SETTINGS_AUTOSIZE_NAME) then auto_size  := reg.ReadInteger(SETTINGS_AUTOSIZE_NAME);
  if reg.ValueExists(SETTINGS_AUTOCRC_NAME)  then auto_crc   := reg.ReadInteger(SETTINGS_AUTOCRC_NAME);

  if reg.ValueExists(SETTINGS_ACTIVEMODE_NAME)    then
   begin
    mode := reg.ReadString(SETTINGS_ACTIVEMODE_NAME);

    if mode = 'ARMka' then SelectorARMkaRadioButton.Checked := true;
    if mode = 'SFU'   then SelectorSFURadioButton.Checked   := true;
    if mode = 'ATM'   then SelectorATMRadioButton.Checked   := true;
    if mode = 'GATE'  then SelectorGateRadioButton.Checked  := true;
   end;

  if prog_speed<>'' then
   for k:=0 to SpeedComboBox.Items.Count-1 do
    if SpeedComboBox.Items.Strings[k] = prog_speed then
     begin
      SpeedComboBox.ItemIndex:=k;
      break;
     end;

  if term_speed<>'' then
   for k:=0 to ARMka_Terminal.SpeedComboBox.Items.Count-1 do
    if ARMka_Terminal.SpeedComboBox.Items.Strings[k] = term_speed then
     begin
      ARMka_Terminal.SpeedComboBox.ItemIndex:=k;
      break;
     end;

  if parity<>'' then
   for k:=0 to ARMka_Terminal.EvenComboBox.Items.Count-1 do
    if ARMka_Terminal.EvenComboBox.Items.Strings[k] = parity then
     begin
      ARMka_Terminal.EvenComboBox.ItemIndex:=k;
      break;
     end;

 except
  log('ERROR : Registry settings read');
  reg.CloseKey;
  reg.Free; reg := nil;
  result := false;
  exit;
 end;

 reg.CloseKey;
 reg.Free; reg := nil;
 result := true;
end;


procedure TARMka_prog_form.SettingsRadioGroupClick(Sender: TObject);
begin
 log('SettingsRadioGroupClick = '+inttostr(SettingsRadioGroup.ItemIndex)+', old = '+inttostr(settings_old_index)+', self = '+inttohex(cardinal(self), 8));

 if settings_lock then exit;
 if settings_old_index = SettingsRadioGroup.ItemIndex  then exit;
 if GetTickCount < showing_timeout then
  begin
   SettingsRadioGroup.ItemIndex := settings_old_index;
   exit;
  end;
 settings_lock := true;

 if not swarm_check_settings then
  begin
   DeviceSelectComboBox.SetFocus; //for prevent SettingsRadioGroup click when restore window!

   SettingsRadioGroup.ItemIndex := settings_old_index;
   swarm_check_settings;

   swarm_send_message(swarm_win_hwnd);
   Application.Minimize;

   settings_lock := false;
   exit;
  end;

 if settings_old_index = 0 then settings_save_reg;
 if settings_old_index = 1 then settings_save_file;

 if SettingsRadioGroup.ItemIndex = 0 then settings_load_reg;
 if SettingsRadioGroup.ItemIndex = 1 then settings_load_file;

 connected_check(false);

 settings_old_index := SettingsRadioGroup.ItemIndex;
 settings_lock := false;
end;

function  TARMka_prog_form.device_actual_name : string;
var
 num : integer;
 com_name : string;
begin
 if is_cp2114(DeviceSelectComboBox.Text) then
  begin
   result := DeviceSelectComboBox.Text;
   exit;
  end;

 cp_list_update(nil);
 num := find_device(cp_list, DeviceSelectComboBox.Text);
 if num<0 then
  begin
   com_name := find_com(DeviceSelectComboBox.Text);
   if com_name<>'' then
    result := com_name
   else
    result := '';
  end
 else
  begin
   result :=cp_list.list[num].com_path;
   if result = '' then
    result :=cp_list.list[num].usb_path;
  end;
end;

function  TARMka_prog_form.device_actual_speed : integer;
var
 speed : integer;
 error : integer;
begin
 speed:=0;

 val(SpeedComboBox.Text, speed, error);
 if (error <> 0) or (speed = 0) then
  speed := CBR_115200;

 result := speed;
end;

function run_program(exe_name:pchar; param_str:pchar; wait_ms:integer=INFINITE):boolean;
var
 si : STARTUPINFO;
 pi : PROCESS_INFORMATION;

begin
 ZeroMemory( @si, sizeof(si) );
 si.cb := sizeof(si);
 ZeroMemory( @pi, sizeof(pi) );

 si.dwFlags := STARTF_USESHOWWINDOW;
 si.wShowWindow := SW_HIDE;
 
 if  not CreateProcess(exe_name,
        param_str,
        nil,        // Process handle not inheritable
        nil,        // Thread handle not inheritable
        FALSE,      // Set handle inheritance to FALSE
        CREATE_NO_WINDOW,          // No creation flags
        nil,        // Use parent's environment block
        nil,        // Use parent's starting directory
        si,         // Pointer to STARTUPINFO structure
        pi )        // Pointer to PROCESS_INFORMATION structure
 then
  result := false
 else
  result := true;

 if wait_ms <> 0 then
  WaitForSingleObject(pi.hProcess, INFINITE);

 CloseHandle(pi.hProcess);
 CloseHandle(pi.hThread);
end;

procedure TARMka_prog_form.device_task(read, rdlock, unlock, erase, write, verify:boolean; fn:string; new:boolean);
var
 old_mode : cardinal;
 f : file;
 name : string;
 bin_name : string;
 str : string;
begin
 if device = nil then exit;
 if cp_list = nil then exit;
 if device.State <> link_idle then exit;

 Auto_Reconnect.send_begin;

 if ExtractFileExt(fn) = '.hex' then
  begin
   bin_name := ChangeFileExt(fn, '.bin');
   {$I-} ChDir(ExtractFilePath(ParamStr(0))); ioresult; {$I+}
   {$I-} DeleteFile(bin_name); ioresult; {$I+}

   if not run_program(nil, pchar('cmd.exe /c hex2bin.exe "'+fn+'"'), 500) then
    begin
     device.stm32_info_string := 'ERROR, utility bin2hex not found';
     log(device.stm32_info_string+' : '+DeviceSelectComboBox.Text);
     StatusLabel.font.Color   := clWindowText;
     StatusLabel.Enabled      := true;
     LastNormalLabel.Enabled  := false;
     last_10sec := GetTickCount;
     SetTaskbarProgressState(tbpsPaused);
     exit;
    end;

   if not FileExists(bin_name) then
    begin
     device.stm32_info_string := 'ERROR, convertating into bin';
     log(device.stm32_info_string+' : '+DeviceSelectComboBox.Text);
     StatusLabel.font.Color   := clWindowText;
     StatusLabel.Enabled      := true;
     LastNormalLabel.Enabled  := false;
     last_10sec := GetTickCount;
     SetTaskbarProgressState(tbpsPaused);
     exit;
    end;

   fn := bin_name;
  end;

 if armka_terminal.device.State <> link_idle then
  begin
   terminal_reconnect := true;
   armka_terminal.ConnectButtonClick(self);
   sleep(100);
  end
 else
  terminal_reconnect := false;

 SetTaskbarProgressState(tbpsIndeterminate);

 history_add(FilenameEdit.Text);

 name := device_actual_name;
 if name = '' then
  begin
   device.stm32_info_string := 'ERROR, device not found';
   log(device.stm32_info_string+' : '+DeviceSelectComboBox.Text);
   StatusLabel.font.Color   := clWindowText;
   StatusLabel.Enabled      := true;
   LastNormalLabel.Enabled  := false;
   last_10sec := GetTickCount;
   SetTaskbarProgressState(tbpsPaused);
   exit;
  end;
 device.port_name := name;


 if fn<>'' then
  if new then
   begin
    {$I-}
    AssignFile(f, fn);
    Rewrite(f,1);
    if IOResult <> 0 then
     begin
      device.stm32_info_string := 'ERROR, cant create firmware file';
      log(device.stm32_info_string);
      StatusLabel.font.Color   := clWindowText;
      StatusLabel.Enabled      := true;
      LastNormalLabel.Enabled  := false;
      last_10sec := GetTickCount + AUTO_WRITE_TIMEOUT;
      SetTaskbarProgressState(tbpsPaused);
      exit;
     end;
    closefile(f);
    IOResult;
    {$I+};
   end
  else
   begin
    {$I-}
    AssignFile(f, fn);
    old_mode := FileMode;
    FileMode := fmOpenRead;
    Reset(f,1);

    if (IOResult <> 0) then
     begin
      device.stm32_info_string := 'ERROR, cant open firmware file';
      log(device.stm32_info_string);
      StatusLabel.font.Color   := clWindowText;
      StatusLabel.Enabled      := true;
      LastNormalLabel.Enabled  := false;
      last_10sec := GetTickCount;
      FileMode := old_mode;
      SetTaskbarProgressState(tbpsPaused);
      exit;
     end;

    if FileSize(f)=0 then
     begin
      device.stm32_info_string := 'ERROR, firmware file is void';
      log(device.stm32_info_string);
      StatusLabel.font.Color   := clWindowText;
      StatusLabel.Enabled      := true;
      LastNormalLabel.Enabled  := false;
      last_10sec := GetTickCount - AUTO_WRITE_TIMEOUT;
      FileMode := old_mode;
      SetTaskbarProgressState(tbpsPaused);
      exit;
     end;
    closefile(f);
    IOResult;
    FileMode := old_mode;
    {$I+};
   end;

 device.port_speed := device_actual_speed;

 device.stm32_task_filename := fn;
 device.stm32_task_read   := read;
 device.stm32_task_RDlock := rdlock;
 device.stm32_task_UNlock := unlock;
 device.stm32_task_erase  := erase;
 device.stm32_task_write  := write;
 device.stm32_task_verify := verify;

 device.stm32_find_disable_atm    := true;
 device.stm32_find_disable_armka  := true;
 device.stm32_find_disable_spgate := true;
 device.SFU_mode := false;

 device.stm32_task_stop := false;

 if ARMka_Terminal.macros_list.Count >= 1 then
  begin
   str := ARMka_Terminal.macros_list.Strings[0];
   if pos(GATE_LIB_SERIAL_PERFIX, str) = 1 then
    begin
     delete(str, 1, length(GATE_LIB_SERIAL_PERFIX));
     device.gate_lib_serial := str;
    end;
  end;

 if SelectorATMRadioButton.Checked   then device.stm32_find_disable_atm    := false;
 if SelectorARMkaRadioButton.Checked then device.stm32_find_disable_armka  := false;
 if SelectorGateRadioButton.Checked  then device.stm32_find_disable_spgate := false;

 if SelectorSFURadioButton.Checked   then
  begin
   if write then
    begin
     auto_commit_prepare(fn);
     device.SFU_mode := true;
    end
   else
    begin
     device.SFU_mode := false;
     device.stm32_task_read   := false;
     device.stm32_task_RDlock := false;
     device.stm32_task_UNlock := false;
     device.stm32_task_erase  := false;
     device.stm32_task_write  := false;
     device.stm32_task_verify := false;
     device.stm32_find_disable_armka  := false;
    end;
  end;

 log(' ');
 device.Open;

 InfoLabel.Hide;
end;

procedure TARMka_prog_form.HistoryListBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
 if key = #13 then
  FilenameEdit.Text := HistoryListBox.Items.Strings[HistoryListBox.ItemIndex];
end;

procedure TARMka_prog_form.HistoryListBoxDblClick(Sender: TObject);
var
 item : string;
 index : integer;
begin
 index := HistoryListBox.ItemIndex;
 item  := HistoryListBox.Items.Strings[HistoryListBox.ItemIndex];

 FilenameEdit.Text := item;
 HistoryListBox.Items.Delete(index);
 history_add(item);
 HistoryListBox.ItemIndex := 0;
end;

procedure TARMka_prog_form.FilenameEditKeyPress(Sender: TObject;
  var Key: Char);
begin
 if key = #13 then
  begin
   history_add(FilenameEdit.Text);
   WriteButton.SetFocus;
  end;
 last_10sec := GetTickCount;
end;

procedure TARMka_prog_form.WriteButtonClick(Sender: TObject);
begin
 if RDLockCheckBox.Checked then
  log('WriteButtonClick with RDLock')
 else
 log('WriteButtonClick without lock');

 if device.State <> link_idle then
  begin
   WriteButton.Enabled  := false;
   device.stm32_task_stop := true;
   auto_commit_set;
  end
 else
  device_task(false, RDLockCheckBox.Checked, UnLockCheckBox.Checked, false, true, false, FilenameEdit.Text, false);
end;

procedure TARMka_prog_form.ReadButtonClick(Sender: TObject);
begin
 log('ReadButtonClick');
 device_task(True, false, false, false, false, false, READED_FILE_NAME, true);
end;

procedure TARMka_prog_form.VerifyButtonClick(Sender: TObject);
begin
 log('VerifyButtonClick');
 device_task(false, false, false, false, false, true, FilenameEdit.Text, false);
end;

procedure TARMka_prog_form.EraseButtonClick(Sender: TObject);
begin
 log('EraseButtonClick');
 device_task(false, false, UnLockCheckBox.Checked, true, false, false, '', false);
end;

procedure TARMka_prog_form.ResetButtonClick(Sender: TObject);
begin
 log('RSTButtonClick');
 device_task(false, false, UnLockCheckBox.Checked, false, false, false, '', false);
end;

procedure TARMka_prog_form.auto_init;
begin
 SetLength(auto_data, 0);
 auto_crc  := 0;
 auto_time := 0;
 auto_size := 0;
end;

function  TARMka_prog_form.auto_check : boolean;
var
 k   : integer;
 res : integer;
 buf : array of byte;
 readed : cardinal;
 search : TSearchRec;
const
 first_start:boolean = true;
begin
 result := false;

 res := FindFirst(FilenameEdit.Text, faAnyFile, search);
 FindClose(search);
 if res <> 0 then exit;

 if (search.Size <> auto_size) then
  begin
   result := true;
   _inf(auto_size);
   exit;
  end;

 if first_start then
  begin
   first_start:=false;
   auto_name := FilenameEdit.Text;
  end
 else
  if (auto_name <> FilenameEdit.Text) then
   begin
    result := true;
    exit;
   end;

 if search.Time = auto_time then exit;

 setlength(buf, search.Size);
 if not stm32_load_file(FilenameEdit.Text, @(buf[0]), length(buf), @readed) then
  begin
   SetLength(buf, 0);
   result := false;
   exit;
  end;

 if readed <> search.Size then
  begin
   SetLength(buf, 0);
   result := true;
   exit;
  end;

 if length(auto_data)<>readed then
  begin
   if length(auto_data)<>0 then
    begin
     SetLength(buf, 0);
     result := true;
     exit;
    end
   else
    if CRCGet(@(buf[0]), readed) <> auto_crc then
     begin
      SetLength(buf, 0);
      result := true;
      exit;
     end
    else
     begin
      SetLength(auto_data, readed);
      Move(buf[0], auto_data[0], readed);
      auto_time := search.Time;

      SetLength(buf, 0);
      result := false;
      exit;
     end;
  end;

 for k:=0 to readed-1 do
  if buf[k] <> auto_data[k] then
   begin
    SetLength(buf, 0);
    result := true;
    exit;
   end;

 auto_time := search.Time;
 SetLength(buf, 0);
 result := false;
end;

procedure TARMka_prog_form.auto_commit_set;
begin
 setlength(auto_data, 0);
 setlength(auto_data, length(auto_prepare_data));
 if length(auto_prepare_data) > 0 then
  Move(auto_prepare_data[0], auto_data[0], length(auto_prepare_data));
 SetLength(auto_prepare_data, 0);

 auto_crc  := auto_prepare_crc;
 auto_time := auto_prepare_time;
 auto_size := auto_prepare_size;
 auto_name := auto_prepare_name;
end;

procedure TARMka_prog_form.auto_commit_prepare_event(sender:tCOMClient; name:string; data:pointer; size:integer);
begin
 auto_commit_prepare(FilenameEdit.Text);
end;

procedure TARMka_prog_form.auto_commit_prepare(fn:string);
var
 res : integer;
 search : TSearchRec;
begin
 res := FindFirst(fn, faAnyFile, search);
 FindClose(search);
 if res <> 0 then exit;

 auto_prepare_name := fn;
 auto_prepare_time := search.Time;

 setlength(auto_prepare_data, search.Size);
 if search.Size = 0 then exit;
 stm32_load_file(auto_prepare_name, @(auto_prepare_data[0]), length(auto_prepare_data), @auto_prepare_size);
 if auto_prepare_size <> search.Size then
  begin
   SetLength(auto_prepare_data, 0);
   auto_prepare_size := 0;
   auto_prepare_crc  := 0;
   exit;
  end
 else
  auto_prepare_crc := CRCGet(@(auto_prepare_data[0]), length(auto_prepare_data));
end;

{procedure TARMka_prog_form.auto_commit;
var
 res : integer;
 search : TSearchRec;
begin
 res := FindFirst(FilenameEdit.Text, faAnyFile, search);
 FindClose(search);
 if res <> 0 then exit;

 auto_name := FilenameEdit.Text;
 auto_time := search.Time;
 setlength(auto_data, search.Size);
 stm32_load_file(auto_name, @(auto_data[0]), length(auto_data), @auto_size);
 if auto_size <> search.Size then
  begin
   SetLength(auto_data, 0);
   auto_size := 0;
   auto_crc  := 0;
   exit;
  end
 else
  auto_crc := CRCGet(@(auto_data[0]), length(auto_data));
end;                       }


procedure TARMka_prog_form.AutoWriteCheckBoxClick(Sender: TObject);
begin
 if auto_lock then exit;
 auto_init;
end;

procedure TARMka_prog_form.InfoLabelClick(Sender: TObject);
begin
 ShellExecute(Handle, 'open', 'http://www.armka.ru', nil, nil, SW_SHOWNORMAL);
end;

procedure TARMka_prog_form.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 SetEvent(graph_close_event);
 {$I-}
 if debug_log_enable then
  CloseFile(debug_log_file);

 ioresult();
 {$I+}
end;

function to_global_name(s:string):string;
begin
 result := '';
 while length(s)<>0 do
  begin
   if s[1] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
    result := result+s[1]
   else
    result := result+inttohex(ord(s[1]),2);
   delete(s,1,1);
  end;
end;

function  TARMka_prog_form.swarm_check(map_hnd : phandle; find_name : string):boolean;
const
 old_name : string = '';

type
 tmap_record = packed record
  handle_app : HWND;
  handle_win : HWND;
  check  : cardinal;
 end;

var
 rec : ^tmap_record;
 name : string;
begin
 name := find_name;
 if map_hnd = @map_device then
  begin
   if (name = '') then
    name := old_name
   else
    old_name := name;
  end;

 name := to_global_name(self.classname + '_'+name);

 if map_hnd^ <> 0 then
  begin
   try
    closehandle(map_hnd^);
   except
    log('Error to close mapping file, hnd = '+inttohex(map_hnd^, 8));
   end;
   map_hnd^ := 0;
  end;

 map_hnd^ := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 4096, pchar(name));

 if map_hnd^ = 0 then
  Log('Swarm_register_deivce_name : CreateFileMapping : '+SysErrorMessage(GetLastError))
 else
  if GetLastError = ERROR_ALREADY_EXISTS then
   begin
    swarm_app_hwnd := 0;
    swarm_win_hwnd := 0;
    rec :=  MapViewOfFile(map_hnd^, FILE_MAP_READ, 0, 0, sizeof(tmap_record));
    if Assigned(rec) then
     begin
      if (rec^.handle_app xor rec^.handle_win xor rec^.check) <> $FFFFFFFF then
       log('Swarm_register_deivce_name : (rec^.handle xor rec^.handle) <> $FFFFFFFF')
      else
       begin
        swarm_app_hwnd := rec^.handle_app;
        swarm_win_hwnd := rec^.handle_win;
       end;
      UnMapViewOfFile(rec);
     end
    else
     log('Swarm_register_deivce_name : ERROR in MapViewOfFile(map_hnd, FILE_MAP_READ, 0, 0, sizeof(tmap_record))');

    if find_name<>'' then
     log('"'+name+'" alredy selected, hwnd = '+inttohex(swarm_app_hwnd, 8)+', app_hnd = '+inttohex(swarm_win_hwnd,8));
    closehandle(map_hnd^);
    map_hnd^ := 0;
    result := false;
    exit;
   end;

 rec :=  MapViewOfFile(map_hnd^, FILE_MAP_WRITE, 0, 0, sizeof(tmap_record));
 if Assigned(rec) then
  begin
   rec^.handle_win := self.Handle;
   rec^.handle_app := Application.Handle;
   rec^.check  := rec^.handle_win xor rec^.handle_app xor $FFFFFFFF;
   UnMapViewOfFile(rec);
  end
 else
  log('Swarm_register_deivce_name : ERROR in MapViewOfFile(map_hnd, FILE_MAP_WRITE, 0, 0, sizeof(tmap_record))');

 result := true;
end;

function  TARMka_prog_form.swarm_check_settings:boolean;
var
 name : string;
begin
 name := 'Settings_';
 if SettingsRadioGroup.ItemIndex = 0 then name := name + 'Registry';
 if SettingsRadioGroup.ItemIndex = 1 then name := name + current_dir;
 if SettingsRadioGroup.ItemIndex = 2 then name := name + 'No_Safe';

 result := swarm_check(@map_settings, name);
 result := result or (SettingsRadioGroup.ItemIndex = 2);
end;

function  TARMka_prog_form.swarm_check_device(find_name : string):boolean;
var
 name, s:string;
 k:integer;
begin
 result := true;
 if find_name = DEVICES_UPDATE_VOID then
  exit;

 name := '';
 if find_name<>'' then
  begin
   s:='';
   for k:=0 to 100 do
    begin
     s := next_dev_name(find_name);
     if s='' then break;
     name := name + s;
    end;
   if name='' then
    name := '<none>';
  end;
 result := swarm_check(@map_device, name);
end;

function  TARMka_prog_form.swarm_check_device_again:boolean;
begin
 result := swarm_check_device('');
end;

procedure send_device_focus_result(hwnd : cardinal; msg : cardinal; data : pointer; result:LRESULT); stdcall;
begin
 ARMka_prog_form.log('send_device_focus_result, result = '+inttohex(result, 8));
end;

procedure TARMka_prog_form.swarm_send_message(handle : HWND);
begin
 log('swarm_send_message('+inttohex(handle,8)+');');
 SendMessageCallback(handle, WM_USER_DEVICE_SELECT, $1DADBEEF, $12345678, @send_device_focus_result, 0);
 sleep(16);
end;

procedure TARMka_prog_form.DeviceLockedLabelClick(Sender: TObject);
begin
 log('DeviceLockedLabelClick');
 swarm_send_message(swarm_win_hwnd);
end;

procedure TARMka_prog_form.swarm_device_select(var Message: TMessage);
begin
 if (message.WParam <> $1DADBEEF) or (message.lParam <> $12345678) then
  begin
   message.Result := 0;
   log(' ');
   log('WARNING: Unknow WinAPI Message : ');
   log(#9'Msg'#9+inttohex(Message.Msg, 8));
   log(#9'WParam'#9+inttohex(Message.WParam, 8));
   log(#9'LParam'#9+inttohex(Message.LParam, 8));
   log(' ');
   exit;
  end;

 sleep(64);

 Application.Minimize;
 sleep(16); Application.ProcessMessages;
 sleep(16); Application.ProcessMessages;
 Application.Restore;

 message.Result := Self.Handle;
 log('WM_USER_DEVICE_SELECT');
 DeviceSelectComboBox.SetFocus;
end;

procedure TARMka_prog_form.FormCreate(Sender: TObject);
begin
 ProgressBar.DoubleBuffered := true;
end;

procedure TARMka_prog_form.TerminalButtonClick(Sender: TObject);
begin
 if ARMka_Terminal.Showing then
  ARMka_Terminal.Hide
 else
  ARMka_Terminal.show;
end;


end.
