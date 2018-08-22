unit ChanelCtrl;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms;

type
 tline_ctrl = class
 private
  bmp : tbitmap;
  paintbox : tpaintbox;
  line_count : integer;
  base_colors : array of cardinal;

  procedure onPaintBoxPaint(Sender: TObject);


 public
  line_colors : array of cardinal;
  line_marked : integer;

  constructor create(cnt:integer; pb:tpaintbox);
 end;


implementation

constructor tline_ctrl.create(cnt:integer; pbox:tpaintbox);
var
 pos : integer;
begin
 chanel_count := cnt;
 paintbox := pbox;

 setlength(base_colors, chanel_count);
 setlength(line_colors, chanel_count);

 line_marked := -1;
 for pos := 0 to length(lines) - 1 do
  begin
   line_colors[pos] := HSV(pos / length(line_colors), 1, 255);
   base_colors[pos] := line_colors[pos];
  end;

 box := sender as TPaintBox;
 bmp := TBitmap.Create;
 bmp.Width := box.Width;
 bmp.Height := box.Height;
end;

procedure tline_ctrl.onPaintBoxPaint(Sender: TObject);
begin
end;

end.
 