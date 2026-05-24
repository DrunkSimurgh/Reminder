unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Menus, Dialogs,
  AlarmService, SettingsStore;

type
  TMainForm = class(TForm)
  private
    FAlarm: TAlarmService;
    FCheckTimer: TTimer;
    FTrayIcon: TTrayIcon;
    FTrayMenu: TPopupMenu;

    FNameEdit: TEdit;
    FStatusLabel: TLabel;
    FExactTimeEdit: TEdit;
    FCustomMinutesEdit: TEdit;

    procedure BuildUi;
    procedure BuildTrayIcon;
    procedure AddPresetButton(const ACaption: string; const AMinutes: Integer; const ALeft, ATop: Integer);
    procedure PresetButtonClick(Sender: TObject);
    procedure CustomMinutesClick(Sender: TObject);
    procedure ExactTimeClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure CheckTimerTick(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure TrayShowClick(Sender: TObject);
    procedure TrayStopClick(Sender: TObject);
    procedure TrayExitClick(Sender: TObject);
    procedure StartAfterMinutes(const AMinutes: Integer);
    procedure StartAtExactTime(const AText: string);
    procedure TriggerReminder;
    procedure UpdateStatus;
    function CleanReminderName: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainFormInstance: TMainForm;

implementation

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 1);

  FAlarm := TAlarmService.Create;
  TSettingsStore.LoadInto(FAlarm);

  BuildUi;
  BuildTrayIcon;

  FCheckTimer := TTimer.Create(Self);
  FCheckTimer.Interval := 1000;
  FCheckTimer.OnTimer := @CheckTimerTick;
  FCheckTimer.Enabled := True;

  UpdateStatus;
end;

destructor TMainForm.Destroy;
begin
  TSettingsStore.SaveFrom(FAlarm);
  FAlarm.Free;
  inherited Destroy;
end;

procedure TMainForm.BuildUi;
var
  StopButton, CustomButton, ExactButton: TButton;
  InfoLabel, NameLabel, CustomLabel, ExactLabel: TLabel;
begin
  Caption := 'Look Away!';
  Width := 430;
  Height := 355;
  Position := poScreenCenter;
  BorderStyle := bsSingle;

  NameLabel := TLabel.Create(Self);
  NameLabel.Parent := Self;
  NameLabel.Caption := 'Reminder name:';
  NameLabel.Left := 18;
  NameLabel.Top := 18;

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.Left := 18;
  FNameEdit.Top := 40;
  FNameEdit.Width := 380;
  FNameEdit.Text := FAlarm.Name;

  InfoLabel := TLabel.Create(Self);
  InfoLabel.Parent := Self;
  InfoLabel.Caption := 'Quick reminders:';
  InfoLabel.Left := 18;
  InfoLabel.Top := 78;

  AddPresetButton('5 min', 5, 18, 100);
  AddPresetButton('10 min', 10, 112, 100);
  AddPresetButton('15 min', 15, 206, 100);
  AddPresetButton('30 min', 30, 300, 100);
  AddPresetButton('1 hour', 60, 18, 138);
  AddPresetButton('2 hours', 120, 112, 138);
  AddPresetButton('4 hours', 240, 206, 138);
  AddPresetButton('8 hours', 480, 300, 138);

  CustomLabel := TLabel.Create(Self);
  CustomLabel.Parent := Self;
  CustomLabel.Caption := 'Custom minutes:';
  CustomLabel.Left := 18;
  CustomLabel.Top := 185;

  FCustomMinutesEdit := TEdit.Create(Self);
  FCustomMinutesEdit.Parent := Self;
  FCustomMinutesEdit.Left := 118;
  FCustomMinutesEdit.Top := 180;
  FCustomMinutesEdit.Width := 80;
  FCustomMinutesEdit.Text := '20';

  CustomButton := TButton.Create(Self);
  CustomButton.Parent := Self;
  CustomButton.Caption := 'Start custom';
  CustomButton.Left := 214;
  CustomButton.Top := 178;
  CustomButton.Width := 110;
  CustomButton.OnClick := @CustomMinutesClick;

  ExactLabel := TLabel.Create(Self);
  ExactLabel.Parent := Self;
  ExactLabel.Caption := 'Exact time: yyyy-mm-dd hh:mm:ss';
  ExactLabel.Left := 18;
  ExactLabel.Top := 225;

  FExactTimeEdit := TEdit.Create(Self);
  FExactTimeEdit.Parent := Self;
  FExactTimeEdit.Left := 18;
  FExactTimeEdit.Top := 247;
  FExactTimeEdit.Width := 190;
  FExactTimeEdit.Text := FormatDateTime('yyyy"-"mm"-"dd hh":"nn":"ss', Now + (20 / (24 * 60)));

  ExactButton := TButton.Create(Self);
  ExactButton.Parent := Self;
  ExactButton.Caption := 'Start exact';
  ExactButton.Left := 224;
  ExactButton.Top := 245;
  ExactButton.Width := 100;
  ExactButton.OnClick := @ExactTimeClick;

  StopButton := TButton.Create(Self);
  StopButton.Parent := Self;
  StopButton.Caption := 'Stop reminder';
  StopButton.Left := 18;
  StopButton.Top := 285;
  StopButton.Width := 130;
  StopButton.OnClick := @StopClick;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Left := 165;
  FStatusLabel.Top := 289;
  FStatusLabel.Width := 240;
  FStatusLabel.Caption := 'No active reminder.';
end;

procedure TMainForm.BuildTrayIcon;
var
  Item: TMenuItem;
begin
  FTrayMenu := TPopupMenu.Create(Self);

  Item := TMenuItem.Create(FTrayMenu);
  Item.Caption := 'Show Reminder';
  Item.OnClick := @TrayShowClick;
  FTrayMenu.Items.Add(Item);

  Item := TMenuItem.Create(FTrayMenu);
  Item.Caption := 'Stop Reminder';
  Item.OnClick := @TrayStopClick;
  FTrayMenu.Items.Add(Item);

  FTrayMenu.Items.AddSeparator;

  Item := TMenuItem.Create(FTrayMenu);
  Item.Caption := 'Exit';
  Item.OnClick := @TrayExitClick;
  FTrayMenu.Items.Add(Item);

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := 'Reminder - Look Away!';
  FTrayIcon.PopupMenu := FTrayMenu;
  FTrayIcon.OnClick := @TrayIconClick;
  FTrayIcon.Visible := True;
end;

procedure TMainForm.AddPresetButton(const ACaption: string; const AMinutes: Integer; const ALeft, ATop: Integer);
var
  Button: TButton;
begin
  Button := TButton.Create(Self);
  Button.Parent := Self;
  Button.Caption := ACaption;
  Button.Left := ALeft;
  Button.Top := ATop;
  Button.Width := 80;
  Button.Tag := AMinutes;
  Button.OnClick := @PresetButtonClick;
end;

procedure TMainForm.PresetButtonClick(Sender: TObject);
begin
  StartAfterMinutes((Sender as TButton).Tag);
end;

procedure TMainForm.CustomMinutesClick(Sender: TObject);
var
  Minutes: Integer;
begin
  if not TryStrToInt(Trim(FCustomMinutesEdit.Text), Minutes) then
  begin
    ShowMessage('Please enter a whole number of minutes.');
    Exit;
  end;

  StartAfterMinutes(Minutes);
end;

procedure TMainForm.ExactTimeClick(Sender: TObject);
begin
  StartAtExactTime(FExactTimeEdit.Text);
end;

procedure TMainForm.StopClick(Sender: TObject);
begin
  FAlarm.Stop;
  TSettingsStore.SaveFrom(FAlarm);
  UpdateStatus;
end;

procedure TMainForm.CheckTimerTick(Sender: TObject);
begin
  if FAlarm.IsDue then
    TriggerReminder;

  UpdateStatus;
end;

procedure TMainForm.TrayIconClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TMainForm.TrayShowClick(Sender: TObject);
begin
  TrayIconClick(Sender);
end;

procedure TMainForm.TrayStopClick(Sender: TObject);
begin
  StopClick(Sender);
end;

procedure TMainForm.TrayExitClick(Sender: TObject);
begin
  Close;
end;

function TMainForm.CleanReminderName: string;
begin
  Result := Trim(FNameEdit.Text);
  if Result = '' then
    Result := 'Look Away!';
end;

procedure TMainForm.StartAfterMinutes(const AMinutes: Integer);
begin
  try
    FAlarm.StartAfterMinutes(AMinutes, CleanReminderName);
    TSettingsStore.SaveFrom(FAlarm);
    UpdateStatus;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.StartAtExactTime(const AText: string);
var
  DueAt: TDateTime;
  Y, M, D, H, N, S: Word;
  Text: string;
begin
  Text := Trim(AText);
  if Length(Text) <> 19 then
  begin
    ShowMessage('Please use this format: yyyy-mm-dd hh:mm:ss');
    Exit;
  end;

  try
    Y := StrToInt(Copy(Text, 1, 4));
    M := StrToInt(Copy(Text, 6, 2));
    D := StrToInt(Copy(Text, 9, 2));
    H := StrToInt(Copy(Text, 12, 2));
    N := StrToInt(Copy(Text, 15, 2));
    S := StrToInt(Copy(Text, 18, 2));

    if not TryEncodeDateTime(Y, M, D, H, N, S, 0, DueAt) then
    begin
      ShowMessage('That date/time is not valid.');
      Exit;
    end;

    FAlarm.StartAt(DueAt, CleanReminderName);
    TSettingsStore.SaveFrom(FAlarm);
    UpdateStatus;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.TriggerReminder;
begin
  FAlarm.Stop;
  TSettingsStore.SaveFrom(FAlarm);
  UpdateStatus;

  Beep;
  Show;
  WindowState := wsNormal;
  BringToFront;
  ShowMessage(FAlarm.Name);
end;

procedure TMainForm.UpdateStatus;
var
  Seconds, Minutes, Hours: Int64;
begin
  if not FAlarm.Active then
  begin
    FStatusLabel.Caption := 'No active reminder.';
    FTrayIcon.Hint := 'Reminder - no active reminder';
    Exit;
  end;

  Seconds := FAlarm.SecondsRemaining;
  Hours := Seconds div 3600;
  Seconds := Seconds mod 3600;
  Minutes := Seconds div 60;
  Seconds := Seconds mod 60;

  FStatusLabel.Caption := Format('Due %s  (%d:%2.2d:%2.2d left)', [
    FormatDateTime('yyyy-mm-dd hh:nn:ss', FAlarm.DueAt), Hours, Minutes, Seconds
  ]);
  FTrayIcon.Hint := 'Reminder due at ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FAlarm.DueAt);
end;

end.
