unit XScallerViewer;

interface
uses ExtCtrls, controls, classes;

type
 tminmax=record
  min:double;
  max:double;
 end;

 tXScallerViewer=class
 private
  view_stack:array[0..128]of tminmax;
  view_stack_pos:integer;

  window_max:integer;

  procedure view_reset;
  procedure SlowFFTPaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure SlowFFTPaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure SlowFFTPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);


 public
  cursor_old:integer;
  cursor_current:integer;

  view_min:double;
  view_max:double;

  constructor create(v_window_max:integer);
  procedure connect_to_paintbox(paintbox:tpaintbox);
 end;

implementation

constructor tXScallerViewer.create;
begin
 inherited create;

 window_max:=v_window_max;
 cursor_old:=-1;
 view_stack_pos:=-1;

 view_reset;
end;

procedure tXScallerViewer.view_reset;
begin
 view_min:=0;
 view_max:=window_max;
end;

procedure tXScallerViewer.connect_to_paintbox;
begin
 if self=nil then exit;
 if paintbox=nil then exit;

{ assert(@paintbox.OnMouseDown=nil);
 assert(@paintbox.OnMouseMove=nil);
 assert(@paintbox.OnMouseUp=nil);}

 paintbox.OnMouseDown:=Self.SlowFFTPaintBoxMouseDown;
 paintbox.OnMouseMove:=Self.SlowFFTPaintBoxMouseMove;
 paintbox.OnMouseUp:=Self.SlowFFTPaintBoxMouseUp;
end;

procedure tXScallerViewer.SlowFFTPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if self=nil then exit;

 if Button=mbLeft then
   cursor_old:=x;
end;

procedure tXScallerViewer.SlowFFTPaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
 new_max:double;
 new_min:double;
begin
 if self=nil then exit;
 if not (sender is tpaintbox) then exit;

 if Button=mbLeft then
  begin
     if abs(cursor_old-x)>2 then
      begin
       if cursor_old<0 then cursor_old:=0;
       if x>=(sender as tpaintbox).Width then x:=(sender as tpaintbox).Width;
       if x<0 then x:=0;

       if view_stack_pos<length(view_stack) then
        inc(view_stack_pos);
       view_stack[view_stack_pos].min:=view_min;
       view_stack[view_stack_pos].max:=view_max;

       new_min:=view_min+cursor_old/(sender as tpaintbox).Width*(view_max-view_min);
       new_max:=view_min+x/(sender as tpaintbox).Width*(view_max-view_min);

       view_max:=new_max;
       view_min:=new_min;
       if view_max<view_min then
        begin
         new_min:=view_min;
         view_min:=view_max;
         view_max:=new_min;
        end;
      end;
  end;

 if Button=mbRight then
  if view_stack_pos>=0 then
   begin
    view_min:=view_stack[view_stack_pos].min;
    view_max:=view_stack[view_stack_pos].max;
    dec(view_stack_pos);
   end
  else
   view_reset;
 cursor_old:=-1;
end;

procedure tXScallerViewer.SlowFFTPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 if self=nil then exit;

 cursor_current:=x;
 if cursor_current>(sender as tpaintbox).Width then cursor_current:=(sender as tpaintbox).Width;
 if cursor_current<0 then     cursor_current:=0;
end;

end.
