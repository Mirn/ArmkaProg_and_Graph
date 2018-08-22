unit fft_math;

interface
uses ExtCtrls, windows, graphics, math, Controls, SysUtils;

type
  tFFTType=double;
  pFFTType=^tFFTType;

  tFFT=class
  private
   samples_count:integer;
   init_power:integer;

   fft_data:array of double;
//   temp_logfile2:file;
   temp_tag:integer;

  protected
   samples:array of tFFTType;
   total_sum:double;
  public
   fft_dOut:array of double;
   normalize : boolean;
   impulse_mode : boolean;

   constructor create(power:integer; tag:integer);
   destructor destroy;override;

   procedure run;virtual;
   procedure add_data(v:pFFTType;cnt:integer);
   procedure reset_data;
   function  get_power:integer;
  end;

  tFFTStat=class(tFFT)
   thd_run:boolean;
   calc_stat_div:integer;

  public
   sample_freq:integer;
   sample_freq_half:integer;

   max_freq_avarage:double;
   max_freq_avarage_alfa:double;
   max_freq:double;
   max_freq_energy:double;
   max_freq_pos:integer;

   thd:double;
   thd_freq_energy:array[0..8] of double;
   thd_freq:array[0..8] of double;

   noise:double;
   amplitude:double;

   constructor create(power:integer; s_freq:integer; tag:integer);

   procedure find_max_freq(a,b:integer);
   procedure calc_max_freq;
   procedure calc_thd;
   procedure calc_noise;
   procedure calc_all_stat;
   procedure calc_amplitude;
   procedure run;override;

   function pos2f(pos:double):double;
   function pos2v(pos:double):double;
   function f2pos(f:double):integer;
   function f2v(f:double):double;
  end;

  tFFTdraw=class(tFFTstat)
   bmp:tbitmap;
   paint_box:TPaintBox;

  public
   counts:array of word;

   win_width:integer;
   win_height:integer;
   win_freq_slow:array of double;
   win_freq_fast:array of double;
   win_freq_min:double;
   win_freq_max:double;
   win_y_shift:integer;
   win_y_mult:integer;
   peak_freq:double;
   peak_value:double;

   constructor create(power:integer; s_freq:integer; paint_in:TPaintBox; tag:integer);
   destructor destroy;override;
   procedure update(w_min,w_max:double; y_shift, y_mult:integer);

   procedure draw_start;
   procedure draw_end;

   procedure draw_gird;
   procedure draw_bars(color1,color2:tcolor);
   procedure draw_select(f_from, f_to:double);
   procedure draw_cursor(cursor_win_pos:integer);
   procedure draw_stat(cursor_win_pos:integer);
   procedure draw_all(cursor_old, cursor_current:integer; color1, color2:tcolor);

   procedure TextOutLeft(px,py:integer;s:string);
   procedure TextOutCenter(px,py:integer;s:string);

   function f2win(f:double):double;
   function win2v(win_pos:double):double;
   function win2f(win_pos:double):double;
   function win2pos(win_pos:double):double;
   function pos2win(pos:double):double;
   function v2y(v:double):integer;
   function win2y(win_pos:double):integer;
   function pos2y(pos:integer):integer;
   function f2y(win_pos:double):integer;
  end;

implementation

function lg_10(v:double):double;
begin
 if v<=10E-30 then
  result:=-1
 else
  result:=math.Log10(v);
end;

constructor tFFTdraw.create;
begin
 inherited create(power, s_freq, tag);

 paint_box:=paint_in;
 win_width:=paint_box.Width;
 win_height:=paint_box.Height;
 bmp:=TBitmap.Create;
 bmp.Width  := win_width;
 bmp.Height := win_height;
// bmp.Width:=1024;
// bmp.Height:=550;//512

 SetLength(win_freq_slow, win_width);
 SetLength(win_freq_fast, win_width);
 SetLength(counts, win_width);
end;

destructor tFFTdraw.destroy;
begin
 SetLength(win_freq_slow, 0);
 SetLength(win_freq_fast, 0);
 SetLength(counts, 0);

 bmp.Free;
 inherited destroy;
end;

procedure tFFTdraw.TextOutLeft(px,py:integer;s:string);
begin
 if self=nil then exit;
 bmp.Canvas.TextOut(px-bmp.Canvas.TextWidth(s), py, s);
end;

procedure tFFTdraw.TextOutCenter(px,py:integer;s:string);
begin
 if self=nil then exit;
 bmp.Canvas.TextOut(px-bmp.Canvas.TextWidth(s) div 2, py, s);
end;

procedure tFFTdraw.draw_start;
begin
 if self=nil then exit;

 with bmp.Canvas do
  begin
   Brush.Color:=0;
   Pen.color:=0;
   brush.Style:=bssolid;
   Rectangle(0,0,win_width, win_height);
  end;
end;

procedure tFFTdraw.draw_end;
begin
 if self=nil then exit;

 paint_box.Canvas.Draw(0,0,bmp);
end;

procedure tFFTdraw.draw_gird;
var
 k:integer;
 y:integer;
begin
 if self=nil then exit;

 with bmp.canvas do
  begin
   Font.Name:='Consolas';
   Font.Size:=12;
   Brush.Style:=bsclear;

   Pen.Color:=rgb(0,0,80);
   pen.Style:=pssolid;
   Font.Color:=rgb(160,0,160);
   for k:=0 downto -20 do
    begin
     y:=v2y(Power(10,k/2));
     if y>win_height+TextHeight(' ') then break;

     TextOutLeft(win_width-1, y+1, inttostr(k*10)+' dB');
     MoveTo(0, y);
     LineTo(win_width, y);
    end;
  end;
end;

procedure tFFTdraw.draw_bars;
var
 k:integer;
 v:double;
begin
 if self=nil then exit;

 with bmp.canvas do
  begin
   pen.Style:=pssolid;
   for k:=0 to win_width-1 do
    begin
     Pen.Color:=color1;
     v:=win_freq_slow[k];
     if v>10E-21 then
      begin
       moveto(k, win_height);
       lineto(k, v2y(v));
      end;

     Pen.Color:=color2;
     v:=win_freq_fast[k];
     if v>10E-21 then
      lineto(k, v2y(v));
    end;
  end;
end;

procedure tFFTDraw.draw_select;
var
 lim_a, lim_b:integer;
 k:integer;
begin
 if self=nil then exit;

 with bmp.Canvas do
  begin
    lim_a:=round(f2win(f_from));
    lim_b:=round(f2win(f_to));
    if lim_b<lim_a then
     begin
      lim_a:=lim_a xor lim_b;
      lim_b:=lim_a xor lim_b;
      lim_a:=lim_a xor lim_b;
     end;
    Pen.Color:=rgb(0,0,50);
    for k:=lim_a-1 to lim_b-1 do
     begin
      moveto(k,0);
      lineto(k,win_height);
     end;
    Pen.Color:=rgb(0,0,200);
    moveto(lim_a, 0);
    lineto(lim_a, win_height);

    moveto(lim_b, 0);
    lineto(lim_b, win_height);
  end;
end;

procedure tFFTdraw.draw_cursor;
var
 lim_a, lim_b:integer;
 current_pos:integer;
 current_dlt:integer;
 max_posx:integer;
 max_posy:integer;
begin
 if self=nil then exit;

 with bmp.Canvas do
  begin
    Pen.Color:=rgb(50,50,00);
    moveto(cursor_win_pos,0);
    lineto(cursor_win_pos,win_height);

    current_pos:=round(win2pos(cursor_win_pos));
    current_dlt:=round(current_pos-win2pos(pos2win(current_pos)-5));
    lim_a:=current_pos-current_dlt;
    lim_b:=current_pos+current_dlt;
    if lim_a<0 then lim_a:=0;
    if lim_b>=length(fft_dout) then lim_b:=length(fft_dout)-1;
    find_max_freq(lim_a, lim_b);

    max_posx:=round(pos2win(max_freq_pos));
    max_posy:=pos2y(max_freq_pos);
    pen.Color:=rgb(255,255,0);
    moveto(max_posx-5, max_posy);
    lineto(max_posx+5, max_posy);

    peak_freq:=pos2f(max_freq_pos);
    peak_value:=pos2v(max_freq_pos);
  end;
end;

procedure tFFTdraw.draw_stat;
var
 current_freq:double;
 k:integer;
begin
 with bmp.Canvas do
  begin
   current_freq:=win2f(cursor_win_pos);

   Font.Name:='Consolas';
   Font.Size:=12;
   Brush.Style:=bsclear;

   Font.Color:=rgb(255,255,255);
   TextOut(0,0, '|<-- '+FloatToStrF(win_freq_min, ffFixed, 6, 2)+' Hz');
   TextOutLeft(bmp.Width, 0, FloatToStrF(win_freq_max, ffFixed, 6, 2)+' Hz -->|');
   TextOutCenter(win_width div 2, 0, IntToStr(round(f2pos(win_freq_max)-f2pos(win_freq_min)))+' Points');

   Font.Color:=rgb(0,255,0);
   TextOut(0, 14*1, 'Max Freq = '+FloatToStrF(max_freq_avarage, ffGeneral, 6, 2)+' Hz ');

   if cursor_win_pos>=0 then
    begin
     Font.Color:=rgb(200,200,0);
     TextOut(0, 14*2, 'Cur Freq = '+FloatToStrF(current_freq, ffGeneral, 6, 1)+' Hz ');
    end;

   Font.Color:=rgb(255,255,0);
   TextOut(0,   14*3, 'Loc Freq = '+FloatToStrF(peak_freq, ffGeneral, 6,1)+' Hz');
   TextOut(210, 14*3, ' Level  = '+FloatToStrF(lg_10(peak_value)*20, ffGeneral, 6, 1)+' dB');

   Font.Color:=rgb(255,0,0);
   TextOut(0, 14*4, 'THD      = '+FloatToStrF(thd, ffGeneral, 6, 2)+'%');
   TextOut(210, 14*4, ' Noise  = '+floattostrf(lg_10(noise)*20, ffGeneral, 4,2)+' dB');

   Font.Color:=rgb(0,0,255);
   for k:=0 to min(length(thd_freq)-1,3) do
    begin
     TextOut(0,   14*(5+k), 'F('+inttostr(k+2)+')     = '+FloatToStrF(thd_freq[k], ffGeneral, 6, 2)+' Hz');
     TextOut(210, 14*(5+k), ' Energy = '+FloatToStrF(lg_10(thd_freq_energy[k])*20, ffGeneral, 4, 2)+' dB');
    end;
  end;
end;

procedure tFFTdraw.draw_all(cursor_old, cursor_current:integer; color1, color2:tcolor);
begin
 draw_start;

 draw_gird;

 if cursor_old>=0 then
  draw_select(win2f(cursor_old), win2f(cursor_current))
 else
  draw_cursor(cursor_current);

 draw_stat(cursor_current);
 draw_bars(color1, color2);
 draw_end;
end;

procedure tFFTdraw.update;
var
 pos, index, i, cnt:integer;
begin
 if self=nil then exit;

{ if (win_freq_min=w_min) and
    (win_freq_max=w_max) and
    (win_y_shift=y_shift) and
    (win_y_mult=y_mult)
 then exit;      }

 fillchar(win_freq_slow[0],     sizeof(win_freq_slow[0])*length(win_freq_slow), 0);
 fillchar(win_freq_fast[0],     sizeof(win_freq_fast[0])*length(win_freq_fast), 0);
 fillchar(counts[0], sizeof(counts[0])*length(counts), 0);
 cnt:=length(fft_dout)-1;
 win_freq_min:=w_min;
 win_freq_max:=w_max;
 win_y_shift:=y_shift;
 win_y_mult:=y_mult;

 for i := 0 to cnt-1 do
  begin
   pos:=round((i*(w_max-w_min)/cnt+w_min)*cnt/(sample_freq div 2));

   index:=round(i/cnt*(length(win_freq_slow)-1));
   if (pos>=0) and (pos<=cnt) then
    begin
     win_freq_slow[index]:=win_freq_slow[index]+fft_dout[pos];
     if win_freq_fast[index]<fft_dout[pos] then
      win_freq_fast[index]:=fft_dout[pos];
     inc(counts[index]);
    end;
  end;

 for i := 0 to length(win_freq_slow)-1 do
  if counts[i]>0 then
   win_freq_slow[i]:=win_freq_slow[i]/counts[i];
end;

function tFFTdraw.f2win(f:double):double;
begin
 result:=0;
 if self=nil then exit;
 if abs(win_freq_min-win_freq_max)>10E-30 then
  result:=((f-win_freq_min)/(win_freq_max-win_freq_min))*win_width;
end;

function tFFTdraw.win2v(win_pos:double):double;
begin
 result:=0;
 if self=nil then exit;
 result:=f2v(win2f(win_pos));
end;

function tFFTdraw.win2f(win_pos:double):double;
begin
 result:=0;
 if self=nil then exit;
 result:=(win_pos/win_width)*(win_freq_max-win_freq_min)+win_freq_min;
end;

function tFFTdraw.win2pos(win_pos:double):double;
begin
 result:=0;
 if self=nil then exit;
 result:=f2pos(win2f(win_pos));
end;

function tFFTdraw.pos2win(pos:double):double;
begin
 result:=0;
 if self=nil then exit;
 result:=f2win(pos2f(pos));
end;

function tFFTdraw.v2y(v:double):integer;
begin
 result:=0;
 if self=nil then exit;
 result:=win_y_shift-round(lg_10(v)*2*win_y_mult);
end;

function tFFTdraw.win2y(win_pos:double):integer;
begin
 result:=0;
 if self=nil then exit;
 result:=v2y(win2v(win_pos));
end;

function tFFTdraw.pos2y(pos:integer):integer;
begin
 result:=0;
 if self=nil then exit;
 result:=v2y(pos2v(pos));
end;

function tFFTdraw.f2y(win_pos:double):integer;
begin
 result:=0;
 if self=nil then exit;
 result:=v2y(f2v(win_pos));
end;

///////////////////////////////////////////////////////////////////////////////////////////////

constructor tFFTstat.create;
begin
 inherited create(power, tag);
 if s_freq<10 then s_freq:=10;
 sample_freq:=s_freq;
 sample_freq_half:=sample_freq div 2;

 max_freq_avarage_alfa:=0.9;
end;

function tFFTstat.pos2f(pos:double):double;
begin
 result:=0;
 if self=nil then exit;
 result:=pos/(length(fft_dout)-1)*sample_freq_half;
end;

function tFFTstat.pos2v(pos:double):double;
var
 i:integer;
begin
 result:=0;
 if self=nil then exit;
 i:=round(pos);
 if (i<0) or (i>=length(fft_dout)) then exit;
 result:=fft_dout[i];
end;

function tFFTstat.f2pos(f:double):integer;
begin
 result:=0;
 if self=nil then exit;
 result:=round(f/sample_freq_half*(length(fft_dout)-1));
end;

function tFFTstat.f2v(f:double):double;
begin
 result:=pos2v(f2pos(f));
end;

procedure tFFTstat.calc_noise;
var
 a:array of double;
 k:integer;
 size:integer;
 lima, limb:integer;
 v:double;

 procedure sort(l,r: integer);
  var
    i,j: integer;
    x,y: double;
  begin
    i:=l; j:=r; x:=a[random(r-l+1)+l]; { x := a[(r+l) div 2]; - для выбора среднего элемента }
    repeat
      while a[i]<x do i:=i+1; { a[i] > x  - сортировка по убыванию}
      while x<a[j] do j:=j-1; { x > a[j]  - сортировка по убыванию}
      if i<=j then
      begin
        if a[i] > a[j] then {это условие можно убрать} {a[i] < a[j] при сортировке по убыванию}
        begin
          y:=a[i]; a[i]:=a[j]; a[j]:=y;
        end;
        i:=i+1; j:=j-1;
      end;
    until i>j;
    if l<j then sort(l,j);
    if i<r then sort(i,r);
  end; {sort}

begin
 if self=nil then exit;
 size:=length(fft_dout);
 if total_sum<10E-24 then exit;

 setlength(a, size);
 for k:=0 to size-1 do
   a[k]:=fft_dout[k];

 sort(0, size-1);

 v:=0;
 lima:=round(size*0.93);
 limb:=round(size*0.95);
 for k:=lima to limb-1 do
  v:=v+a[k];
 v:=v/(limb-lima);
 noise:=v;

 setlength(a, 0);
end;

procedure tFFTstat.find_max_freq;
var
 k:integer;
 max:double;
begin
 if self=nil then exit;
 max_freq_pos:=0;
 if (a<0) or (b>=length(fft_dout)) then exit;

 max:=-10E24;

 for k:=a to b do
  if max<fft_dout[k] then
   begin
    max:=fft_dout[k];
    max_freq_pos:=k;
   end;
end;

procedure tFFTstat.calc_max_freq;
var
 k:integer;
 left,right:integer;
 vm:double;
 vs:double;
begin
 if self=nil then exit;
 max_freq:=0;
 max_freq_energy:=0;
 if (max_freq_pos<10) then find_max_freq(1,length(fft_dout)-1);
 if (max_freq_pos<10) or (max_freq_pos>=length(fft_dout)) then exit;

 left:=max_freq_pos;
 while (left>1) and (fft_dout[left]>fft_dout[left-1]) do dec(left);
 right:=max_freq_pos;
 while (right<(length(fft_dout)-1)) and (fft_dout[right]>fft_dout[right+1]) do inc(right);

 vm:=0;
 vs:=0;
 for k:=left to right-1 do
  begin
   vm:=vm+k*fft_dout[k];
   vs:=vs+fft_dout[k];
  end;

 if vs>10E-24 then
  begin
   max_freq:=pos2f(vm/vs);
//   max_freq:=pos2f(max_freq_pos);
   if not thd_run then
    max_freq_avarage:=max_freq_avarage*max_freq_avarage_alfa+(1-max_freq_avarage_alfa)*max_freq;
   max_freq_energy:=vs;
  end;
end;

procedure tFFTstat.calc_thd;
var
 k:integer;
 v:double;
 base,step:integer;
 old_freq, old_energy:double;
 old_freq_pos:integer;
begin
 if self=nil then exit;
 fillchar(thd_freq_energy, sizeof(thd_freq_energy), 0);
 fillchar(thd_freq, sizeof(thd_freq), 0);
// thd:=0;

 if length(fft_dout)=0 then exit;
 if (max_freq_pos<10) then find_max_freq(1,length(fft_dout)-1);
 if (max_freq_pos<10) or (max_freq_pos>length(fft_dout)) then exit;

 base:=max_freq_pos;
 step:=round(base*0.05);

 thd_run:=true;
 old_freq:=max_freq;
 old_energy:=max_freq_energy;
 old_freq_pos:=max_freq_pos;

 for k:=0 to length(thd_freq_energy)-1 do
  begin
   if (base*(k+2)+step) >= length(fft_dout) then break;
   find_max_freq(base*(k+2)-step, base*(k+2)+step);
   calc_max_freq;
   thd_freq[k]:=max_freq;
   thd_freq_energy[k]:=fft_dout[max_freq_pos];
//   thd_freq_energy[k]:=max_freq_energy; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  end;

 max_freq:=old_freq;
 max_freq_energy:=old_energy;
 max_freq_pos:=old_freq_pos;
 thd_run:=false;

 base:=max_freq_pos;
 step:=round(base*0.5);
 if step<2 then exit;
 base:=step+base;

 old_energy:=noise*2;
 v:=0;
 for k:=base to length(fft_dout)-1 do
  if fft_dout[k]>old_energy then
   v:=v+fft_dout[k];

{ if v>10E-30 then
  thd:=(v*100)/max_freq_energy;}

 v:=0;
 for k:=0 to length(thd_freq_energy)-1 do
  v:=v+sqr(thd_freq_energy[k]);

 if v>10E-30 then
  v:=(sqrt(v)*100)/fft_dout[max_freq_pos];
 thd:=thd*0.9+0.1*v;
end;

procedure tFFTstat.calc_all_stat;
begin
 if self=nil then exit;

 find_max_freq(f2pos(10),length(fft_dout)-1);
 calc_max_freq;
 if calc_stat_div and 3=0 then calc_noise;
 if calc_stat_div and 1=0 then calc_thd;
 inc(calc_stat_div);
end;

procedure tFFTstat.run;
begin
 inherited run;
 calc_all_stat;
end;

procedure tFFTstat.calc_amplitude;
begin
 if self=nil then exit;
 if length(samples)=0 then exit;

 amplitude:=total_sum/(length(samples)*$7FFF);
end;

////////////////////////////////////////////////////////////////////////////////////////////////

constructor tfft.create;
begin
 samples_count:=1 shl power;
 init_power:=power;
// sample_freq:=s_freq;

 SetLength(fft_data, samples_count*3);
 SetLength(fft_dout, (samples_count div 2));
 SetLength(Samples, samples_count);

 temp_tag:=tag;
 if temp_tag=0 then
  begin
//   assignfile(temp_logfile2, 'temp_logfile_fifo.dat');
//   Rewrite(temp_logfile2, 1);
  end;
end;

destructor tfft.destroy;
begin
 if self=nil then exit;

 SetLength(fft_data, 0);
 SetLength(fft_dout, 0);
 SetLength(Samples, 0);

 if temp_tag=0 then
//  closefile(temp_logfile2)
  ;
end;

function tfft.get_power:integer;
begin
 result:=13;
 if self=nil then exit;
 result:=init_power;
end;

procedure tfft.reset_data;
begin
 if self=nil then exit;
 ZeroMemory(@samples[0], length(samples)*sizeof(samples[0]));
end;

procedure tfft.add_data;
begin
 if self=nil then exit;

 if length(fft_data)<cnt then exit;
 if sizeof(samples[0])<>sizeof(v^) then exit;
 if length(samples)<=cnt then
  begin
   inc(v, cnt-length(samples));
   cnt:=length(samples);
  end;

// if temp_tag=0 then
//  BlockWrite(temp_logfile2, v^, cnt*sizeof(v^))
//  ;

 if cnt<length(samples) then
  move(samples[cnt], samples[0], length(samples)*sizeof(samples[0])-cnt*sizeof(samples[0]));
 move(v^, samples[length(samples)-cnt], cnt*sizeof(v^));
end;

procedure tfft.run;
var
 i, j, n, m, mmax, istep, isign:integer;
 tempr, tempi, wtemp, theta, wpr, wpi, wr, wi,v:double;
 dIn:pFFTType; nn:integer;
 adder : double;
begin
 if self=nil then exit;
 if length(fft_data)=0 then exit;
 if length(fft_dout)=0 then exit;
 if length(samples)=0 then exit;

 fillchar(fft_data[0], sizeof(fft_data[0])*length(fft_data), 0);
 fillchar(fft_dout[0], sizeof(fft_dout[0])*length(fft_dout), 0);
 total_sum:=0;

 dIn:=@samples[0];
 nn:=length(samples);

 isign := -1;
// istep:=1 shl (sizeof(samples[0])*8);
 istep := 1;

 for  i := 0 to nn-1 do
  begin
     fft_data[i * 2] := 0;
     v:=dIn^/istep*(0.5-0.5*cos(2*pi*i/(nn-1)));
     fft_data[i * 2 + 1] := v;
     total_sum:=total_sum+abs(v);
     inc(dIn);
  end;

 n := nn shl 1;
 j := 1;
 i := 1;
 while i < n do
  begin
     if j > i then
      begin
         tempr := fft_data[i];
         fft_data[i] := fft_data[j];
         fft_data[j] := tempr;

         tempr := fft_data[i+1];
         fft_data[i+1] := fft_data[j+1];
         fft_data[j+1] := tempr;
      end;

     m := n shr 1;
     while  (m >= 2) and (j > m) do
      begin
         j := j - m;
         m := m shr 1;
      end;
     j := j + m;
     i := i + 2;
  end;

 mmax := 2;
 while n>mmax do
  begin
     istep := 2 * mmax;
     theta := 2.0 * PI / (isign * mmax);
     wtemp := sin( 0.5 * theta );
     wpr := -2.0 * wtemp * wtemp;
     wpi := sin( theta );
     wr := 1.0;
     wi := 0.0;
     m := 1;
     while m<mmax do
      begin
         i := m;
         while i<n do
          begin
             j := i + mmax;
             tempr := wr * fft_data[j] - wi * fft_data[j + 1];
             tempi := wr * fft_data[j + 1] + wi * fft_data[j];
             fft_data[j] := fft_data[i] - tempr;
             fft_data[j + 1] := fft_data[i + 1] - tempi;
             fft_data[i] := fft_data[i] + tempr;
             fft_data[i + 1] := fft_data[i + 1] + tempi;
             i := i + istep;
          end;
         wtemp := wr;
         wr := wtemp * wpr - wi * wpi + wr;
         wi := wi * wpr + wtemp * wpi + wi;
         m := m + 2;
      end;
     mmax := istep;
  end;

 if normalize then
  begin
   if total_sum>10E-30 then
    for i := 0 to length(fft_dOut)-1 do
     fft_dOut[ i ] := sqrt( sqr(fft_data[ i * 2 ]) + sqr(fft_data[ i * 2 + 1 ]) )/total_sum;
  end
 else
  begin
   for i := 0 to length(fft_dOut)-1 do
    fft_dOut[ i ] := sqrt( sqr(fft_data[ i * 2 ]) + sqr(fft_data[ i * 2 + 1 ]) ) / (32767*length(fft_dOut));
  end;

 if impulse_mode then
  begin
   adder := (1 shl init_power);
   for i := 0 to length(fft_dOut)-1 do
    fft_dOut[i] := fft_dOut[i] * adder;
  end;
end;

end.
