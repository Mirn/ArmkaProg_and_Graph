unit uARMka_log_form;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ClipBrd, StdCtrls,
  CP210xManufacturingDLL,
  CP2102_classes,
  uLog_Viewer,
  ExtCtrls, AppEvnts;

type
  TARMka_log_form = class(TForm)
    Button: TButton;
    PaintBox1: TPaintBox;
    ApplicationEvents1: TApplicationEvents;
    Timer1: TTimer;
    SmoothCheckBox: TCheckBox;
    procedure ButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SmoothCheckBoxClick(Sender: TObject);

  private

  public
   log : tstringlist;
   viewer : tLog_Viewer;
   update_block : boolean;
   procedure add_log(msg:string);
   procedure viewer_update;
  end;

 tlog_prog=tCP210x_log_event;

var
  ARMka_log_form: TARMka_log_form;

implementation

{$R *.dfm}

procedure TARMka_log_form.viewer_update;
var
 txt : string;
begin
 if viewer = nil then exit;
 if log = nil then exit;
 
 txt := log.Text;
 if length(txt) = 0 then
  viewer.text_update(nil, 0)
 else
  viewer.text_update(@txt[1], length(txt));
end;

procedure TARMka_log_form.add_log(msg:string);
begin
 log.Add(msg);

 if not update_block then
  viewer_update;
end;

procedure TARMka_log_form.ButtonClick(Sender: TObject);
begin
 Clipboard.AsText := log.Text;
end;

procedure TARMka_log_form.FormCreate(Sender: TObject);
begin
 log := tstringlist.create;

 viewer := tLog_Viewer.create(PaintBox1, ApplicationEvents1);
 viewer.auto_scroll_smooth := SmoothCheckBox.Checked;
end;

procedure TARMka_log_form.Timer1Timer(Sender: TObject);
begin
 if viewer = nil then exit;
 viewer.onTimer(sender);
end;

procedure TARMka_log_form.FormResize(Sender: TObject);
begin
 if viewer = nil then exit;
 viewer.onResize(self);
end;

procedure TARMka_log_form.SmoothCheckBoxClick(Sender: TObject);
begin
 if viewer = nil then exit;
 viewer.auto_update_scroll := not SmoothCheckBox.Checked;
 viewer.auto_scroll_smooth := SmoothCheckBox.Checked;
end;

end.



