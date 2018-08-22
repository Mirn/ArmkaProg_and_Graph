unit uSimpleLog;

interface

function date_time_filename : string;
function normalize_filename(str:string):string;

procedure logfile_create(var f:file; name:string);
procedure logfile_close(var f:file);
procedure logfile_write_str(var f:file; str:ansistring);
procedure logfile_write_data(var f:file; data:pointer; size:cardinal);

implementation
uses sysutils;

function normalize_filename(str:string):string;
begin
 result := str;
 result := StringReplace(result, '.', '', [rfReplaceAll]);
 result := StringReplace(result, ':', '', [rfReplaceAll]);
 result := StringReplace(result, '\', '_', [rfReplaceAll]);
 result := StringReplace(result, '.', '_', [rfReplaceAll]);
 result := StringReplace(result, '/', '_', [rfReplaceAll]);
 result := StringReplace(result, ':', '_', [rfReplaceAll]);
end;

function date_time_filename : string;
begin
 result := DateToStr(Now) + '_' + TimeToStr(now);
 result := normalize_filename(result);
end;

procedure logfile_create(var f:file; name:string);
begin
{$I-}
 AssignFile(f, name);
 rewrite(f, 1);
 IOResult;
{$I+}
end;

procedure logfile_close(var f:file);
begin
{$I-}
 CloseFile(f);
 IOResult;
{$I+}
end;

procedure logfile_write_str(var f:file; str:ansistring);
begin
 //if str = '' then exit;
 str := str + #13;
{$I-}
 BlockWrite(f, str[1], length(str));
 IOResult;
{$I+}
end;

procedure logfile_write_data(var f:file; data:pointer; size:cardinal);
begin
{$I-}
 BlockWrite(f, data^, size);
 IOResult;
{$I+}
end;

end.
