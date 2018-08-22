unit uFileFIFOSender;

interface

uses sysutils;

function file_fifo_sender_start(p1,p2,p3:string):string;

implementation

////////////////////////////////////////////////////////////////////////////////////////////////////

{$I-}

uses
 classes,
 windows,
 math,
 ufifo_map;

type
 tfifo_sender = class(tthread)
 private
  send_counter : int64;
  send_adder : int64;

  f : file;

 protected
  procedure Execute; override;

 public
  file_name : string;
  speed : integer;
  loop : boolean;
  fifo : tFIFO_map;

  constructor create;
  function open_start:boolean;
 end;

var
 sender : tfifo_sender;

////////////////////////////////////////////////////////////////////////////////////////////////////

constructor tfifo_sender.create;
begin
 inherited create(true);
end;

procedure tfifo_sender.Execute;
var
 buf : array of byte;
 freq : int64;
 t_begin : int64;
 t_end : int64;
 usec : integer;
 block_size : int64;
 readed : integer;
 rd_need : integer;
 total_rd : integer;
label
 finish_all;
begin
 SetLength(buf, speed*2);
 QueryPerformanceCounter(t_begin);

 while not Terminated do
  begin
   sleep(2);
   QueryPerformanceCounter(t_end);
   QueryPerformanceFrequency(freq);

   usec := round((t_end - t_begin) / (freq / 1000000.0));
   t_begin := t_end;

   send_counter := send_counter + (send_adder * usec);
   send_counter := send_counter and $7FFFFFFFFFFFFFFF;

   total_rd := 0;
   block_size := send_counter div $100000000;
   while block_size > 0 do
    begin
     rd_need := math.Min(block_size, length(buf));
     rd_need := math.min(rd_need, fifo.bytes_free);
     if rd_need = 0 then
      break;

     readed := 0;
     BlockRead(f, buf[0], rd_need, readed);
     if IOResult <> 0 then
      goto finish_all;
     fifo.write(@buf[0], readed);
     inc(total_rd, readed);
     block_size := block_size - readed;
     send_counter := send_counter - (readed * $100000000);

     if readed <> rd_need then
      begin
       if not loop then
        goto finish_all
       else
        Seek(f, 0);
      end;
    end;
   //fifo.write_string(inttostr(usec) + #9 + inttostr(block_size) + #9 + inttostr(total_rd));
  end;

finish_all:
 self.FreeOnTerminate := true;
 SetLength(buf, 0);
 CloseFile(f);
end;

function tfifo_sender.open_start:boolean;
var
 old_mode : integer;
begin
 result := false;
 if file_name = '' then exit;
 if not FileExists(file_name) then exit;
 if speed = 0 then exit;

 old_mode := FileMode;
 FileMode := fmOpenRead;
 AssignFile(f, file_name);
 reset(f, 1);
 FileMode := old_mode;
 if IOResult <> 0 then exit;

 send_counter := 0;
 send_adder := round((speed / 1000000.0) * $100000000);

 self.Resume;
 result := true;
end;

////////////////////////////////////////////////////////////////////////////////////////////////////

function file_fifo_sender_start(p1,p2,p3:string):string;
var
 p2_int : integer;
 p2_err : integer;
begin
 result := '';

 p2_int := 0;
 p2_err := 1;
 val(p2, p2_int, p2_err);
 if (p2_err <> 0) then
  exit;

 result := '__file_fifo_sender__';
 sender := tfifo_sender.create;

 sender.fifo := tFIFO_map.create(result, $200000, nil);;
 sender.fifo.create_writer;

 sender.file_name := p1;
 sender.speed := p2_int;
 sender.loop := (system.Pos('LOOP', UpperCase(p2)) > 0) or (system.Pos('LOOP', UpperCase(p3)) > 0);

 if not sender.open_start then
  begin
   FreeAndNil(sender);
   result := '';
  end;
end;

end.