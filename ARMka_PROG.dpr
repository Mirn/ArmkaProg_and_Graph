program ARMka_PROG;

uses
  Forms,
  uARMka_prog_form in 'uARMka_prog_form.pas' {ARMka_prog_form},
  uARMka_log_form in 'uARMka_log_form.pas' {ARMka_log_form},
  uARMka_Terminal in 'uARMka_Terminal.pas' {ARMka_Terminal};

{$R *.res}
{$R WindowsXP.res}

//procedure idle_event

begin
  Application.Initialize;
  Application.CreateForm(TARMka_prog_form, ARMka_prog_form);
  Application.CreateForm(TARMka_log_form, ARMka_log_form);
  Application.CreateForm(TARMka_Terminal, ARMka_Terminal);
  Application.ShowMainform:=false;
  Application.Run;
//  Application.OnIdle := idle_event;
end.
