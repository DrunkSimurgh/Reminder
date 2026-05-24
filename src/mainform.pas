unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs, Spin,
  DateUtils, AlarmService, SettingsStore, StatusForm;

type
  TMainForm = class(TForm)
  private
    FAlarm: TAlarmService;
    FStatusForm: TStatusForm;
    FCheckTimer: TTimer;
    FBeepTestTimer: TTimer;
    FAllowClose: Boolean;

    FNameEdit: TEdit;
    FManualSpin: TSpinEdit;
    FDateEdit: TEdit;
    FTimeEdit: TEdit;
    FActivatedLabel: TLabel;
    FScheduledLabel: TLabel;

    procedure BuildUi;
    function AddPresetButton(const ACaption: string; const ASeconds: Integer; const ALeft, ATop: Integer): TButton;
    procedure PresetButtonClick(Sender: TObject);
    procedure ManualMinutesClick(Sender: TObject);
    procedure ManualHoursClick(Sender: TObject);
    procedure ExactOkClick(Sender: TObject);
    procedure BeepTestClick(Sender: TObject);
    procedure BeepTestTimerTick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure CheckTimerTick(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure FormClickHandler(Sender: TObject);
    procedure StatusShowSettings(Sender: TObject);
    procedure StatusStopReminder(Sender: TObject);
    procedure StatusExitApp(Sender: TObject);
    procedure StartAfterSeconds(const ASeconds: Integer);
    procedure StartAtExactPickerTime;
    function TryInputDateTime(out ADueAt: TDateTime): Boolean;
    procedure ShowRunningReminder;
    procedure TriggerReminder;
    procedure StopReminder(const AShowMain: Boolean);
    procedure ResetPickers;
    procedure RefreshLabels;
    function CleanReminderName: string;
  protected
    procedure DoClose(var CloseAction: TCloseAction); override;
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

  FAllowClose := False;

  FAlarm := TAlarmService.Create;
  TSettingsStore.LoadInto(FAlarm);

  FStatusForm := TStatusForm.Create(Self);
  FStatusForm.OnShowSettings := @StatusShowSettings;
  FStatusForm.OnStopReminder := @StatusStopReminder;
  FStatusForm.OnExitApp := @StatusExitApp;

  BuildUi;

  FCheckTimer := TTimer.Create(Self);
  FCheckTimer.Interval := 1000;
  FCheckTimer.OnTimer := @CheckTimerTick;
  FCheckTimer.Enabled := True;

  FBeepTestTimer := TTimer.Create(Self);
  FBeepTestTimer.Interval := 20000;
  FBeepTestTimer.OnTimer := @BeepTestTimerTick;
  FBeepTestTimer.Enabled := False;

  ResetPickers;
  RefreshLabels;

  if FAlarm.Active and (FAlarm.DueAt > Now) then
    ShowRunningReminder;
end;

destructor TMainForm.Destroy;
begin
  FStatusForm.HideTrayIcon;
  TSettingsStore.SaveFrom(FAlarm);
  FAlarm.Free;
  inherited Destroy;
end;

procedure TMainForm.BuildUi;
var
  NameLabel, OrLabel, DateInputLabel, TimeInputLabel, ActivatedTitle, ScheduledTitle: TLabel;
  PresetGroup, ManualGroup: TGroupBox;
  TestButton, ExitButton, MinButton, HourButton, OkButton: TButton;
  Panel1, Panel2: TPanel;
begin
  Caption := 'Look Away!';
  Width := 464;
  Height := 330;
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  FormStyle := fsStayOnTop;
  OnClick := @FormClickHandler;

  NameLabel := TLabel.Create(Self);
  NameLabel.Parent := Self;
  NameLabel.Caption := 'Alarm Name:';
  NameLabel.Left := 61;
  NameLabel.Top := 15;

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.Left := 130;
  FNameEdit.Top := 12;
  FNameEdit.Width := 187;
  FNameEdit.MaxLength := 30;
  FNameEdit.Text := FAlarm.Name;
  FNameEdit.OnChange := @NameEditChange;

  PresetGroup := TGroupBox.Create(Self);
  PresetGroup.Parent := Self;
  PresetGroup.Left := 61;
  PresetGroup.Top := 40;
  PresetGroup.Width := 346;
  PresetGroup.Height := 80;
  PresetGroup.Caption := 'Predefined postpone methods';

  AddPresetButton('5 minutes', 5 * SecsPerMin, 15, 20).Parent := PresetGroup;
  AddPresetButton('10 minutes', 10 * SecsPerMin, 95, 20).Parent := PresetGroup;
  AddPresetButton('15 minutes', 15 * SecsPerMin, 175, 20).Parent := PresetGroup;
  AddPresetButton('20 minutes', 20 * SecsPerMin, 255, 20).Parent := PresetGroup;
  AddPresetButton('30 minutes', 30 * SecsPerMin, 15, 50).Parent := PresetGroup;
  AddPresetButton('40 minutes', 40 * SecsPerMin, 95, 50).Parent := PresetGroup;
  AddPresetButton('1 hour', 60 * SecsPerMin, 175, 50).Parent := PresetGroup;
  AddPresetButton('2 hours', 120 * SecsPerMin, 255, 50).Parent := PresetGroup;

  ManualGroup := TGroupBox.Create(Self);
  ManualGroup.Parent := Self;
  ManualGroup.Left := 48;
  ManualGroup.Top := 120;
  ManualGroup.Width := 369;
  ManualGroup.Height := 105;
  ManualGroup.Caption := 'Manual postpone';

  Panel1 := TPanel.Create(Self);
  Panel1.Parent := ManualGroup;
  Panel1.Left := 25;
  Panel1.Top := 15;
  Panel1.Width := 325;
  Panel1.Height := 33;
  Panel1.BevelOuter := bvLowered;

  FManualSpin := TSpinEdit.Create(Self);
  FManualSpin.Parent := ManualGroup;
  FManualSpin.Left := 70;
  FManualSpin.Top := 20;
  FManualSpin.Width := 47;
  FManualSpin.MinValue := 1;
  FManualSpin.MaxValue := 1000;
  FManualSpin.Value := 1;

  MinButton := TButton.Create(Self);
  MinButton.Parent := ManualGroup;
  MinButton.Left := 130;
  MinButton.Top := 20;
  MinButton.Width := 100;
  MinButton.Height := 25;
  MinButton.Caption := 'minute(s) (enter)';
  MinButton.OnClick := @ManualMinutesClick;

  HourButton := TButton.Create(Self);
  HourButton.Parent := ManualGroup;
  HourButton.Left := 240;
  HourButton.Top := 20;
  HourButton.Width := 75;
  HourButton.Height := 25;
  HourButton.Caption := 'hour(s)';
  HourButton.OnClick := @ManualHoursClick;

  OrLabel := TLabel.Create(Self);
  OrLabel.Parent := ManualGroup;
  OrLabel.Left := 12;
  OrLabel.Top := 55;
  OrLabel.Caption := 'or:';

  Panel2 := TPanel.Create(Self);
  Panel2.Parent := ManualGroup;
  Panel2.Left := 25;
  Panel2.Top := 45;
  Panel2.Width := 325;
  Panel2.Height := 57;
  Panel2.BevelOuter := bvLowered;

  DateInputLabel := TLabel.Create(Self);
  DateInputLabel.Parent := ManualGroup;
  DateInputLabel.Left := 32;
  DateInputLabel.Top := 53;
  DateInputLabel.Caption := 'Date:';

  FDateEdit := TEdit.Create(Self);
  FDateEdit.Parent := ManualGroup;
  FDateEdit.Left := 70;
  FDateEdit.Top := 50;
  FDateEdit.Width := 116;
  FDateEdit.Height := 21;

  TimeInputLabel := TLabel.Create(Self);
  TimeInputLabel.Parent := ManualGroup;
  TimeInputLabel.Left := 194;
  TimeInputLabel.Top := 53;
  TimeInputLabel.Caption := 'Time:';

  FTimeEdit := TEdit.Create(Self);
  FTimeEdit.Parent := ManualGroup;
  FTimeEdit.Left := 232;
  FTimeEdit.Top := 50;
  FTimeEdit.Width := 110;
  FTimeEdit.Height := 21;

  OkButton := TButton.Create(Self);
  OkButton.Parent := ManualGroup;
  OkButton.Left := 268;
  OkButton.Top := 75;
  OkButton.Width := 75;
  OkButton.Height := 25;
  OkButton.Caption := 'OK';
  OkButton.OnClick := @ExactOkClick;

  TestButton := TButton.Create(Self);
  TestButton.Parent := Self;
  TestButton.Left := 173;
  TestButton.Top := 230;
  TestButton.Width := 106;
  TestButton.Height := 25;
  TestButton.Caption := '20 seconds beep';
  TestButton.OnClick := @BeepTestClick;

  ExitButton := TButton.Create(Self);
  ExitButton.Parent := Self;
  ExitButton.Left := 381;
  ExitButton.Top := 231;
  ExitButton.Width := 75;
  ExitButton.Height := 25;
  ExitButton.Caption := 'Exit';
  ExitButton.OnClick := @ExitClick;

  ScheduledTitle := TLabel.Create(Self);
  ScheduledTitle.Parent := Self;
  ScheduledTitle.Left := 5;
  ScheduledTitle.Top := 260;
  ScheduledTitle.Caption := 'Scheduled time:';

  FScheduledLabel := TLabel.Create(Self);
  FScheduledLabel.Parent := Self;
  FScheduledLabel.Left := 85;
  FScheduledLabel.Top := 260;
  FScheduledLabel.Caption := '-';

  ActivatedTitle := TLabel.Create(Self);
  ActivatedTitle.Parent := Self;
  ActivatedTitle.Left := 5;
  ActivatedTitle.Top := 275;
  ActivatedTitle.Caption := 'Activated on:';

  FActivatedLabel := TLabel.Create(Self);
  FActivatedLabel.Parent := Self;
  FActivatedLabel.Left := 70;
  FActivatedLabel.Top := 275;
  FActivatedLabel.Caption := '-';
end;

function TMainForm.AddPresetButton(const ACaption: string; const ASeconds: Integer; const ALeft, ATop: Integer): TButton;
begin
  Result := TButton.Create(Self);
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := 75;
  Result.Height := 25;
  Result.Tag := ASeconds;
  Result.OnClick := @PresetButtonClick;
end;

procedure TMainForm.PresetButtonClick(Sender: TObject);
begin
  StartAfterSeconds((Sender as TButton).Tag);
end;

procedure TMainForm.ManualMinutesClick(Sender: TObject);
begin
  StartAfterSeconds(FManualSpin.Value * SecsPerMin);
end;

procedure TMainForm.ManualHoursClick(Sender: TObject);
begin
  StartAfterSeconds(FManualSpin.Value * SecsPerHour);
end;

procedure TMainForm.ExactOkClick(Sender: TObject);
begin
  StartAtExactPickerTime;
end;

procedure TMainForm.BeepTestClick(Sender: TObject);
begin
  FBeepTestTimer.Enabled := False;
  FManualSpin.SetFocus;
  FBeepTestTimer.Enabled := True;
end;

procedure TMainForm.BeepTestTimerTick(Sender: TObject);
begin
  Beep;
  FBeepTestTimer.Enabled := False;
end;

procedure TMainForm.ExitClick(Sender: TObject);
begin
  FAllowClose := True;
  FStatusForm.HideTrayIcon;
  Close;
end;

procedure TMainForm.CheckTimerTick(Sender: TObject);
begin
  if FAlarm.IsDue then
    TriggerReminder;

  RefreshLabels;
end;

procedure TMainForm.NameEditChange(Sender: TObject);
begin
  Caption := CleanReminderName;
  FStatusForm.Caption := CleanReminderName;
end;

procedure TMainForm.FormClickHandler(Sender: TObject);
begin
  FManualSpin.SetFocus;
end;

procedure TMainForm.StatusShowSettings(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  FormStyle := fsStayOnTop;
  BringToFront;
  FManualSpin.SetFocus;
end;

procedure TMainForm.StatusStopReminder(Sender: TObject);
begin
  StopReminder(True);
end;

procedure TMainForm.StatusExitApp(Sender: TObject);
begin
  FAllowClose := True;
  FStatusForm.HideTrayIcon;
  Close;
end;

function TMainForm.CleanReminderName: string;
begin
  Result := Trim(FNameEdit.Text);
  if Result = '' then
    Result := 'Look Away!';
end;

procedure TMainForm.StartAfterSeconds(const ASeconds: Integer);
begin
  try
    FAlarm.StartAfterSeconds(ASeconds, CleanReminderName);
    TSettingsStore.SaveFrom(FAlarm);
    ShowRunningReminder;
  except
    on E: Exception do
    begin
      Beep;
      ShowMessage(E.Message);
    end;
  end;
end;

procedure TMainForm.StartAtExactPickerTime;
var
  DueAt: TDateTime;
begin
  try
    if not TryInputDateTime(DueAt) then
      raise Exception.Create('Please enter the date as YYYY-MM-DD and the time as HH:MM or HH:MM:SS.');

    FAlarm.StartAt(DueAt, CleanReminderName);
    TSettingsStore.SaveFrom(FAlarm);
    ShowRunningReminder;
  except
    on E: Exception do
    begin
      Beep;
      ShowMessage(E.Message);
      ResetPickers;
    end;
  end;
end;

function TMainForm.TryInputDateTime(out ADueAt: TDateTime): Boolean;
var
  DateText, TimeText: string;
  Y, M, D, H, N, Sec: Word;
begin
  Result := False;
  ADueAt := 0;
  DateText := Trim(FDateEdit.Text);
  TimeText := Trim(FTimeEdit.Text);
  Sec := 0;

  try
    if (Length(DateText) <> 10) or (DateText[5] <> '-') or (DateText[8] <> '-') then
      Exit;

    if not (Length(TimeText) in [5, 8]) then
      Exit;

    if (TimeText[3] <> ':') then
      Exit;

    if (Length(TimeText) = 8) and (TimeText[6] <> ':') then
      Exit;

    Y := StrToInt(Copy(DateText, 1, 4));
    M := StrToInt(Copy(DateText, 6, 2));
    D := StrToInt(Copy(DateText, 9, 2));
    H := StrToInt(Copy(TimeText, 1, 2));
    N := StrToInt(Copy(TimeText, 4, 2));
    if Length(TimeText) = 8 then
      Sec := StrToInt(Copy(TimeText, 7, 2));

    if (H > 23) or (N > 59) or (Sec > 59) then
      Exit;

    ADueAt := EncodeDate(Y, M, D) + EncodeTime(H, N, Sec, 0);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TMainForm.ShowRunningReminder;
begin
  RefreshLabels;
  Hide;
  FStatusForm.ShowNextAlarm(FAlarm.Name, FAlarm.DueAt, FAlarm.SecondsRemaining);
end;

procedure TMainForm.TriggerReminder;
begin
  FAlarm.Stop;
  TSettingsStore.SaveFrom(FAlarm);

  FStatusForm.Hide;
  FStatusForm.HideTrayIcon;
  RefreshLabels;
  ResetPickers;

  Beep;
  Show;
  WindowState := wsNormal;
  FormStyle := fsStayOnTop;
  BringToFront;
  FManualSpin.Value := 1;
  FManualSpin.SetFocus;
end;

procedure TMainForm.StopReminder(const AShowMain: Boolean);
begin
  FAlarm.Stop;
  TSettingsStore.SaveFrom(FAlarm);
  FStatusForm.Hide;
  FStatusForm.HideTrayIcon;
  RefreshLabels;
  ResetPickers;

  if AShowMain then
  begin
    Show;
    WindowState := wsNormal;
    FormStyle := fsStayOnTop;
    BringToFront;
  end;
end;

procedure TMainForm.ResetPickers;
var
  NextValue: TDateTime;
begin
  NextValue := IncMinute(Now, 1);
  FDateEdit.Text := FormatDateTime('yyyy"-"mm"-"dd', DateOf(NextValue));
  FTimeEdit.Text := FormatDateTime('hh":"nn":"ss', TimeOf(NextValue));
end;

procedure TMainForm.RefreshLabels;
var
  LateSeconds, Days, Hours, Minutes, Seconds: Int64;
  LateText: string;
begin
  if FAlarm.ActivatedAt > 0 then
    FActivatedLabel.Caption := TimeToStr(FAlarm.ActivatedAt) + ', ' + DateToStr(FAlarm.ActivatedAt)
  else
    FActivatedLabel.Caption := TimeToStr(Now) + ', ' + DateToStr(Now);

  if FAlarm.DueAt > 0 then
    FScheduledLabel.Caption := TimeToStr(FAlarm.DueAt) + ', ' + DateToStr(FAlarm.DueAt)
  else
    FScheduledLabel.Caption := '-';

  FActivatedLabel.Font.Color := clBlack;
  LateSeconds := FAlarm.SecondsLate;
  if (not FAlarm.Active) and (FAlarm.DueAt > 0) and (LateSeconds > 2) then
  begin
    Days := LateSeconds div SecsPerDay;
    LateSeconds := LateSeconds mod SecsPerDay;
    Hours := LateSeconds div SecsPerHour;
    LateSeconds := LateSeconds mod SecsPerHour;
    Minutes := LateSeconds div SecsPerMin;
    Seconds := LateSeconds mod SecsPerMin;

    LateText := '';
    if Days > 0 then LateText := LateText + Format('%d day(s), ', [Days]);
    if Hours > 0 then LateText := LateText + Format('%d hour(s), ', [Hours]);
    if Minutes > 0 then LateText := LateText + Format('%d minute(s), ', [Minutes]);
    if Seconds > 0 then LateText := LateText + Format('%d second(s) late', [Seconds]);

    if LateText <> '' then
    begin
      FActivatedLabel.Font.Color := clRed;
      FActivatedLabel.Caption := TimeToStr(Now) + ', ' + DateToStr(Now) + ' (' + LateText + ')';
    end;
  end;

  if FAlarm.Active then
    FStatusForm.UpdateTrayHint(FAlarm.Name + '; next alarm time: ' + TimeToStr(FAlarm.DueAt));
end;

procedure TMainForm.DoClose(var CloseAction: TCloseAction);
begin
  if (not FAllowClose) and Visible and FAlarm.Active then
  begin
    CloseAction := caNone;
    Hide;
    FStatusForm.HideToTray;
  end
  else
    inherited DoClose(CloseAction);
end;

end.
