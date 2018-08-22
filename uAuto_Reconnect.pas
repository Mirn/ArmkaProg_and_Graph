unit uAuto_Reconnect;

interface
uses windows, sysutils;

type
 tAuto_ReConnect_onlog = procedure(msg:string) of object;

 tAuto_ReConnect = class
 private
  event_begin : thandle;
  event_end   : thandle;

  old_connected : boolean;
  onLog : tAuto_ReConnect_onlog;

  procedure log(msg:string);
  function connect_one_event(name:string):thandle;
  function connect_all_events(name:string):thandle;

 public
  constructor create(name:string; v_onLog:tAuto_ReConnect_onlog = nil);
  destructor destroy;override;

  procedure send_begin;
  procedure send_end;

  function check_begin(connected:boolean):boolean;
  function check_end:boolean;
 end;


implementation
uses AccCtrl, AclAPI;

procedure tAuto_ReConnect.log(msg:string);
begin
 if self = nil then exit;
 if @onlog = nil then exit;
 onLog(self.ClassName + #9 + msg);
end;

function tAuto_ReConnect.connect_one_event(name:string):thandle;
var
 error : cardinal;
begin
 result := CreateEvent(nil, true, false, pchar(name));
 error := GetLastError;
 if result = 0 then
  log('ERROR: CreateEvent(nil, true, false, "' + name + '") return error: '+
      '[' + inttohex(error,8) + '] "'+SysErrorMessage(error)+'"')
 else
  if (error = 0) or (error = ERROR_ALREADY_EXISTS) then
   begin
    if error = 0 then
     log('CreateEvent(nil, true, false, "' + name + '") return OK')
    else
     log('CreateEvent(nil, true, false, "' + name + '") return ALREADY_EXISTS');
   end
  else
   log('WARNING: CreateEvent(nil, true, false, "' + name + '") return: '+
       '[' + inttohex(error,8) + '] "' + SysErrorMessage(error)+'"');

 if result = 0 then exit;

 error:= SetSecurityInfo(result,
        SE_KERNEL_OBJECT,
        DACL_SECURITY_INFORMATION,
        nil,
        nil,
        nil,
        nil);
 if error <> ERROR_SUCCESS then
  log('WARNING: Event of "' + name + '" SetSecurityInfo return: '+
      '[' + inttohex(error,8) + '] "'+SysErrorMessage(error) + '"');
end;

function tAuto_ReConnect.connect_all_events(name:string):thandle;
begin
 result := connect_one_event('Global\' + name);
 if result <> 0 then exit;

 result := connect_one_event('Local\' + name);
 if result <> 0 then exit;

 result := connect_one_event(name);
 if result <> 0 then exit;
end;

constructor tAuto_ReConnect.create(name:string; v_onLog:tAuto_ReConnect_onlog = nil);
begin
 inherited create;

 old_connected := false;
 onLog := v_onLog;

 event_begin := connect_all_events(tAuto_ReConnect.classname + '_' + name + '_evBegin');
 event_end   := connect_all_events(tAuto_ReConnect.classname + '_' + name + '_evEnd');
end;

destructor tAuto_ReConnect.destroy;
begin
 if self = nil then exit;

 if event_begin <> 0 then CloseHandle(event_begin);
 if event_end   <> 0 then CloseHandle(event_end);
end;

procedure tAuto_ReConnect.send_begin;
begin
 if self = nil then exit;
 if event_begin = 0 then exit;
 if event_end   = 0 then exit;

 ResetEvent(event_end);
 SetEvent(event_begin);
 log('send_begin');
end;

procedure tAuto_ReConnect.send_end;
begin
 if self = nil then exit;
 if event_begin = 0 then exit;
 if event_end   = 0 then exit;

 ResetEvent(event_begin);
 SetEvent(event_end);
 log('send_end');
end;

function tAuto_ReConnect.check_begin(connected:boolean):boolean;
var
 timeout : cardinal;
begin
 result := false;
 if self = nil then exit;
 if event_begin = 0 then exit;

 timeout := WaitForSingleObject(event_begin, 0);

 if timeout = WAIT_FAILED then
  begin
   log('ERROR: WaitForSingleObject(event_begin, 0) return WAIT_FAILED');
   event_begin := 0;
  end;

 if timeout = WAIT_OBJECT_0 then
  begin
   ResetEvent(event_begin);
   result := connected;
   old_connected := connected;
   log('SIGNAL: BEGIN');
  end;
end;

function tAuto_ReConnect.check_end:boolean;
var
 timeout : cardinal;
begin
 result := false;
 if self = nil then exit;
 if event_end = 0 then exit;

 timeout := WaitForSingleObject(event_end, 0);

 if timeout = WAIT_FAILED then
  begin
   log('ERROR: WaitForSingleObject(event_end, 0) return WAIT_FAILED');
   event_end := 0;
  end;

 if timeout = WAIT_OBJECT_0 then
  begin
   ResetEvent(event_end);
   result := old_connected;
   old_connected := false;
   log('SIGNAL: END');
  end;
end;


end.
