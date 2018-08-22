unit hsv2rgb;
interface

uses math, windows;


procedure HSVToRGB(const H, S, V: Single; out R, G, B: Integer);
function HSV(const H, S, V: Single):cardinal;

implementation

function HSV(const H, S, V: Single):cardinal;
var
 r,g,b:integer;
begin
 HSVToRGB(h, s, v,   r, g, b);
 r:=max(0, min(255,r));
 g:=max(0, min(255,g));
 b:=max(0, min(255,b));
 result := rgb(r, g, b);
end;

procedure HSVToRGB(const H, S, V: Single; out R, G, B: Integer);
const
  SectionSize = 60/360;
var
  Section: Single;
  SectionIndex: Integer;
  f: single;
  p, q, t: Single;
begin
  if H < 0 then
  begin
    R:= round(V);
    G:= round(R);
    B:= round(R);
  end
  else
  begin
    Section:= H/SectionSize;
    SectionIndex:= Floor(Section);
    f:= Section - SectionIndex;
    p:= V * ( 1 - S );
    q:= V * ( 1 - S * f );
    t:= V * ( 1 - S * ( 1 - f ) );
    case SectionIndex of
      0:
        begin
          R:= round(V);
          G:= round(t);
          B:= round(p);
        end;
      1:
        begin
          R:= round(q);
          G:= round(V);
          B:= round(p);
        end;
      2:
        begin
          R:= round(p);
          G:= round(V);
          B:= round(t);
        end;
      3:
        begin
          R:= round(p);
          G:= round(q);
          B:= round(V);
        end;
      4:
        begin
          R:= round(t);
          G:= round(p);
          B:= round(V);
        end;
    else
      R:= round(V);
      G:= round(p);
      B:= round(q);
    end;
  end;
end;
end.
