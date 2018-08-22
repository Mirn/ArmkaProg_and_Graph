program ARMka_Graph;

uses
  Forms,
  windows,
  umutex,
  umap_file,
  ufifo_map,
  dialogs,
  uFileFIFOSender,
  GraphLinesForm in 'GraphLinesForm.pas' {GraphLinesForm},
  uArmkaFFT_Form in 'uArmkaFFT_Form.pas' {ArmkaFFT_Form};

{$R *.res}

var
 fifo_name : string;
 hnd : thandle;
begin
  open_mutex_local := true;
  open_map_local := true;

  fifo_name := 'tArmka_graph_fifo_01076A6B';

  if paramcount = 1 then fifo_name := paramstr(1);
  if paramcount > 1 then fifo_name := file_fifo_sender_start(paramstr(1), paramstr(2), paramstr(3));
  if fifo_name = '' then
   begin
    ShowMessage('USAGE: ' + #13+
     'ARMka_Graph (fifoname)' + #13 +
     'or ' + #13 +
     'ARMka_Graph (cvs_filename) (speed in bytes per sec) [loop]');
    exit;
   end;

  hnd := CreateEvent(nil, false, false, pchar(fifo_name + '_only_one_mark'));

  if GetLastError = ERROR_ALREADY_EXISTS then
   begin
    SetEvent(hnd);
    Exit;
   end;

  Application.Initialize;
  Application.CreateForm(TGraphLinesForm, LinesForm);
  Application.CreateForm(TArmkaFFT_Form, ArmkaFFT_Form);
  LinesForm.fifo := tFIFO_map.create(fifo_name, $200000, nil);
  LinesForm.bringup_event := hnd;
  LinesForm.close_event := CreateEvent(nil, false, false, pchar(fifo_name + '_close'));

  if not LinesForm.fifo.open_as_reader then
   begin
    showmessage('Error open_as_reader on open fifo chanel:' +#13 +fifo_name);
    exit;
   end;

  if LinesForm.fifo.is_created then
   begin
    showmessage('Error is_created on open fifo chanel:' +#13 +fifo_name);
    exit;
   end;

 Application.Run;
end.


