unit uArmkaFFT_Form;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,
  fft_math,
  XScallerViewer,
  uSimpleLog,
  StdCtrls;

type
  TArmkaFFT_Form = class(TForm)
    PaintBox: TPaintBox;
    WinSizeRadioGroup: TRadioGroup;
    SampleFreqRadioGroup: TRadioGroup;
    ScreenShotButton: TButton;
    ImpulseCheckBox: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure WinSizeRadioGroupClick(Sender: TObject);
    procedure SampleFreqRadioGroupClick(Sender: TObject);
    procedure ScreenShotButtonClick(Sender: TObject);
    procedure ImpulseCheckBoxClick(Sender: TObject);
  private
  public
   fft : tFFTdraw;
   window_scaler : tXScallerViewer;
   procedure reinit;
   procedure redraw;
   procedure calc_data(data:pFFTType; cnt:integer);
  end;

var
  ArmkaFFT_Form: TArmkaFFT_Form;

implementation

uses GraphLinesForm;
{$R *.dfm}

procedure TArmkaFFT_Form.reinit;
var
 power : integer;
 sample_freq : integer;
begin
 FreeAndNil(fft);
 FreeAndNil(window_scaler);

 power := 7 + WinSizeRadioGroup.ItemIndex;
 sample_freq := strtoint(SampleFreqRadioGroup.Items[SampleFreqRadioGroup.Itemindex]);
 fft := tFFTdraw.create(power, sample_freq, PaintBox, 0);
 fft.impulse_mode := ImpulseCheckBox.Checked;

 window_scaler := tXScallerViewer.create(fft.sample_freq_half);
 window_scaler.connect_to_paintbox(PaintBox);
end;

procedure tArmkaFFT_Form.redraw;
begin
 fft.update(window_scaler.view_min, window_scaler.view_max, 130, 30);
 fft.draw_all(window_scaler.cursor_old, window_scaler.cursor_current, rgb(255,255,255), rgb(128,128,128))
end;

procedure TArmkaFFT_Form.FormShow(Sender: TObject);
begin
 reinit;
end;

procedure TArmkaFFT_Form.calc_data(data:pFFTType; cnt:integer);
begin
 fft.reset_data;
 if cnt > 0 then
  fft.add_data(data, cnt);
 fft.run;
end;

procedure TArmkaFFT_Form.PaintBoxPaint(Sender: TObject);
begin
 redraw;
end;

procedure TArmkaFFT_Form.FormHide(Sender: TObject);
begin
 LinesForm.FFTCheckBox.checked := false;
end;

procedure TArmkaFFT_Form.WinSizeRadioGroupClick(Sender: TObject);
begin
 reinit;
 LinesForm.update_fft;
end;

procedure TArmkaFFT_Form.SampleFreqRadioGroupClick(Sender: TObject);
begin
 reinit;
 LinesForm.update_fft;
end;

procedure TArmkaFFT_Form.ImpulseCheckBoxClick(Sender: TObject);
begin
 reinit;
 LinesForm.update_fft;
end;

procedure TArmkaFFT_Form.ScreenShotButtonClick(Sender: TObject);
var
 dir : string;
 fn : string;
begin
 dir := ExtractFilePath(paramstr(0)) + 'screenshots';
 fn := dir + '\' + date_time_filename + '.bmp';
 MkDir(dir);

 fft.bmp.SaveToFile(fn);
 ShowMessage('Screenshot saved to'#13 + fn);
end;

end.
