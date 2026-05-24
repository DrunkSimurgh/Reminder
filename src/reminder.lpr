program reminder;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Forms,
  MainForm,
  StatusForm;

begin
  RequireDerivedFormResource := False;
  Application.Title := 'Reminder';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainFormInstance);
  Application.Run;
end.
