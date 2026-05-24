unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Dialogs, Spin,
  DateUtils, DateTimeCtrls, AlarmService, SettingsStore, StatusForm
  {$IFDEF MSWINDOWS}, Windows{$ENDIF};

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
    FDatePicker: TDateTimePicker;
    FTimePicker: TDateTimePicker;
    FKeepOnTopTimer: TTimer;
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
    procedure KeepOnTopTimerTick(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure FormClickHandler(Sender: TObject);
    procedure NumericKeyPress(Sender: TObject; var Key: char);
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
    procedure ForceStayOnTop(AForm: TCustomForm);
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

  FKeepOnTopTimer := TTimer.Create(Self);
  FKeepOnTopTimer.Interval := 500;
  FKeepOnTopTimer.OnTimer := @KeepOnTopTimerTick;
  FKeepOnTopTimer.Enabled := True;

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
  Width := 500;
  Height := 350;
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  FormStyle := fsStayOnTop;
  OnClick := @FormClickHandler;

  NameLabel := TLabel.Create(Self);
  NameLabel.Parent := Self;
  NameLabel.Caption := 'Alarm Name:';
  NameLabel.Left := 62;
  NameLabel.Top := 16;

  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := Self;
  FNameEdit.Left := 135;
  FNameEdit.Top := 12;
  FNameEdit.Width := 220;
  FNameEdit.MaxLength := 30;
  FNameEdit.Text := FAlarm.Name;
  FNameEdit.OnChange := @NameEditChange;

  PresetGroup := TGroupBox.Create(Self);
  PresetGroup.Parent := Self;
  PresetGroup.Left := 48;
  PresetGroup.Top := 42;
  PresetGroup.Width := 400;
  PresetGroup.Height := 96;
  PresetGroup.Caption := 'Predefined postpone methods';

  AddPresetButton('5 minutes', 5 * SecsPerMin, 15, 24).Parent := PresetGroup;
  AddPresetButton('10 minutes', 10 * SecsPerMin, 110, 24).Parent := PresetGroup;
  AddPresetButton('15 minutes', 15 * SecsPerMin, 205, 24).Parent := PresetGroup;
  AddPresetButton('20 minutes', 20 * SecsPerMin, 300, 24).Parent := PresetGroup;
  AddPresetButton('30 minutes', 30 * SecsPerMin, 15, 60).Parent := PresetGroup;
  AddPresetButton('40 minutes', 40 * SecsPerMin, 110, 60).Parent := PresetGroup;
  AddPresetButton('1 hour', 60 * SecsPerMin, 205, 60).Parent := PresetGroup;
  AddPresetButton('2 hours', 120 * SecsPerMin, 300, 60).Parent := PresetGroup;

  ManualGroup := TGroupBox.Create(Self);
  ManualGroup.Parent := Self;
  ManualGroup.Left := 48;
  ManualGroup.Top := 145;
  ManualGroup.Width := 400;
  ManualGroup.Height := 112;
  ManualGroup.Caption := 'Manual postpone';

  Panel1 := TPanel.Create(Self);
  Panel1.Parent := ManualGroup;
  Panel1.Left := 25;
  Panel1.Top := 17;
  Panel1.Width := 350;
  Panel1.Height := 34;
  Panel1.BevelOuter := bvLowered;

  FManualSpin := TSpinEdit.Create(Self);
  FManualSpin.Parent := ManualGroup;
  FManualSpin.Left := 70;
  FManualSpin.Top := 22;
  FManualSpin.Width := 55;
  FManualSpin.MinValue := 1;
  FManualSpin.MaxValue := 1000;
  FManualSpin.Value := 1;
  FManualSpin.OnKeyPress := @NumericKeyPress;

  MinButton := TButton.Create(Self);
  MinButton.Parent := ManualGroup;
  MinButton.Left := 135;
  MinButton.Top := 21;
  MinButton.Width := 125;
  MinButton.Height := 26;
  MinButton.Caption := 'minute(s) (enter)';
  MinButton.OnClick := @ManualMinutesClick;

  HourButton := TButton.Create(Self);
  HourButton.Parent := ManualGroup;
  HourButton.Left := 270;
  HourButton.Top := 21;
  HourButton.Width := 85;
  HourButton.Height := 26;
  HourButton.Caption := 'hour(s)';
  HourButton.OnClick := @ManualHoursClick;

  OrLabel := TLabel.Create(Self);
  OrLabel.Parent := ManualGroup;
  OrLabel.Left := 12;
  OrLabel.Top := 63;
  OrLabel.Caption := 'or:';

  Panel2 := TPanel.Create(Self);
  Panel2.Parent := ManualGroup;
  Panel2.Left := 25;
  Panel2.Top := 53;
  Panel2.Width := 350;
  Panel2.Height := 52;
  Panel2.BevelOuter := bvLowered;

  DateInputLabel := TLabel.Create(Self);
  DateInputLabel.Parent := ManualGroup;
  DateInputLabel.Left := 34;
  DateInputLabel.Top := 65;
  DateInputLabel.Caption := 'Date:';

  FDatePicker := TDateTimePicker.Create(Self);
  FDatePicker.Parent := ManualGroup;
  FDatePicker.Left := 72;
  FDatePicker.Top := 61;
  FDatePicker.Width := 125;
  FDatePicker.Height := 24;
  FDatePicker.Kind := dtkDate;

  TimeInputLabel := TLabel.Create(Self);
  TimeInputLabel.Parent := ManualGroup;
  TimeInputLabel.Left := 206;
  TimeInputLabel.Top := 65;
  TimeInputLabel.Caption := 'Time:';

  FTimePicker := TDateTimePicker.Create(Self);
  FTimePicker.Parent := ManualGroup;
  FTimePicker.Left := 246;
  FTimePicker.Top := 61;
  FTimePicker.Width := 92;
  FTimePicker.Height := 24;
  FTimePicker.Kind := dtkTime;

  OkButton := TButton.Create(Self);
  OkButton.Parent := ManualGroup;
  OkButton.Left := 342;
  OkButton.Top := 60;
  OkButton.Width := 30;
  OkButton.Height := 26;
  OkButton.Caption := 'OK';
  OkButton.OnClick := @ExactOkClick;

  TestButton := TButton.Create(Self);
  TestButton.Parent := Self;
  TestButton.Left := 175;
  TestButton.Top := 264;
  TestButton.Width := 120;
  TestButton.Height := 26;
  TestButton.Caption := '20 seconds beep';
  TestButton.OnClick := @BeepTestClick;

  ExitButton := TButton.Create(Self);
  ExitButton.Parent := Self;
  ExitButton.Left := 402;
  ExitButton.Top := 264;
  ExitButton.Width := 75;
  ExitButton.Height := 26;
  ExitButton.Caption := 'Exit';
  ExitButton.OnClick := @ExitClick;

  ScheduledTitle := TLabel.Create(Self);
  ScheduledTitle.Parent := Self;
  ScheduledTitle.Left := 12;
  ScheduledTitle.Top := 300;
  ScheduledTitle.Caption := 'Scheduled time:';

  FScheduledLabel := TLabel.Create(Self);
  FScheduledLabel.Parent := Self;
  FScheduledLabel.Left := 120;
  FScheduledLabel.Top := 300;
  FScheduledLabel.Width := 350;
  FScheduledLabel.Caption := '-';

  ActivatedTitle := TLabel.Create(Self);
  ActivatedTitle.Parent := Self;
  ActivatedTitle.Left := 12;
  ActivatedTitle.Top := 318;
  ActivatedTitle.Caption := 'Activated on:';

  FActivatedLabel := TLabel.Create(Self);
  FActivatedLabel.Parent := Self;
  FActivatedLabel.Left := 120;
  FActivatedLabel.Top := 318;
  FActivatedLabel.Width := 350;
  FActivatedLabel.Caption := '-';
end;

function TMainForm.AddPresetButton(const ACaption: string; const ASeconds: Integer; const ALeft, ATop: Integer): TButton;
begin
  Result := TButton.Create(Self);
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := 88;
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

procedure TMainForm.KeepOnTopTimerTick(Sender: TObject);
begin
  if Visible then
    ForceStayOnTop(Self);
  if FStatusForm.Visible then
    ForceStayOnTop(FStatusForm);
end;

procedure TMainForm.NumericKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in [#8, #9, #13, '0'..'9']) then
  begin
    Beep;
    Key := #0;
  end;
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
  ForceStayOnTop(Self);
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
begin
  Result := True;
  try
    ADueAt := DateOf(FDatePicker.DateTime) + TimeOf(FTimePicker.DateTime);
  except
    ADueAt := 0;
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
  ForceStayOnTop(Self);
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
  FDatePicker.DateTime := DateOf(NextValue);
  FTimePicker.DateTime := TimeOf(NextValue);
end;

procedure TMainForm.RefreshLabels;
var
  LateSeconds, Days, Hours, Minutes, Seconds: Int64;
  LateText: string;
begin
  if FAlarm.ActivatedAt > 0 then
    FActivatedLabel.Caption := TimeToStr(FAlarm.ActivatedAt) + ', ' + DateToStr(FAlarm.ActivatedAt)
  else
    FActivatedLabel.Caption := '-';

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
      FActivatedLabel.Caption := FActivatedLabel.Caption + ' (' + LateText + ')';
    end;
  end;

  if FAlarm.Active then
    FStatusForm.UpdateTrayHint(FAlarm.Name + '; next alarm time: ' + TimeToStr(FAlarm.DueAt));
end;

procedure TMainForm.ForceStayOnTop(AForm: TCustomForm);
begin
  if not Assigned(AForm) then
    Exit;

  AForm.FormStyle := fsStayOnTop;
  {$IFDEF MSWINDOWS}
  if AForm.HandleAllocated then
    SetWindowPos(AForm.Handle, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
  {$ELSE}
  AForm.BringToFront;
  {$ENDIF}
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
