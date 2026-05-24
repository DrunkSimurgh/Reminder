unit StatusForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Menus, DateUtils;

type
  TReminderActionEvent = procedure(Sender: TObject) of object;

  TStatusForm = class(TForm)
  private
    FGroupBox: TGroupBox;
    FTimeLabel: TLabel;
    FDateLabel: TLabel;
    FNameLabel: TLabel;
    FSecondsLabel: TLabel;
    FStopButton: TButton;
    FHideButton: TButton;
    FFadeTimer: TTimer;
    FMouseDelayTimer: TTimer;
    FTrayIcon: TTrayIcon;
    FTrayMenu: TPopupMenu;
    FShowItem: TMenuItem;
    FStopItem: TMenuItem;
    FExitItem: TMenuItem;
    FOnShowSettings: TReminderActionEvent;
    FOnStopReminder: TReminderActionEvent;
    FOnExitApp: TReminderActionEvent;

    procedure BuildUi;
    procedure BuildTray;
    procedure StopButtonClick(Sender: TObject);
    procedure HideButtonClick(Sender: TObject);
    procedure FadeTimerTick(Sender: TObject);
    procedure MouseDelayTimerTick(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure ShowItemClick(Sender: TObject);
    procedure StopItemClick(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure FormMouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PositionAtBottomRight;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowNextAlarm(const AName: string; const ADueAt: TDateTime; const ASeconds: Int64);
    procedure ShowStatusWindow;
    procedure HideToTray;
    procedure HideTrayIcon;
    procedure UpdateTrayHint(const AHint: string);

    property OnShowSettings: TReminderActionEvent read FOnShowSettings write FOnShowSettings;
    property OnStopReminder: TReminderActionEvent read FOnStopReminder write FOnStopReminder;
    property OnExitApp: TReminderActionEvent read FOnExitApp write FOnExitApp;
  end;

implementation

constructor TStatusForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 1);
  BuildUi;
  BuildTray;
end;

procedure TStatusForm.BuildUi;
begin
  Caption := 'Look Away!';
  Width := 330;
  Height := 155;
  BorderStyle := bsNone;
  Color := clWhite;
  Position := poDesigned;
  FormStyle := fsStayOnTop;
  AlphaBlend := True;
  AlphaBlendValue := 255;
  OnMouseMove := @FormMouseMoveHandler;

  FSecondsLabel := TLabel.Create(Self);
  FSecondsLabel.Parent := Self;
  FSecondsLabel.Left := 75;
  FSecondsLabel.Top := 135;
  FSecondsLabel.Caption := '0';
  FSecondsLabel.Visible := False;

  FGroupBox := TGroupBox.Create(Self);
  FGroupBox.Parent := Self;
  FGroupBox.Caption := 'next alarm time';
  FGroupBox.Left := 15;
  FGroupBox.Top := 15;
  FGroupBox.Width := 300;
  FGroupBox.Height := 121;
  FGroupBox.Color := clCream;
  FGroupBox.ParentColor := False;
  FGroupBox.OnMouseMove := @FormMouseMoveHandler;

  FNameLabel := TLabel.Create(Self);
  FNameLabel.Parent := FGroupBox;
  FNameLabel.Left := 18;
  FNameLabel.Top := 22;
  FNameLabel.Width := 250;
  FNameLabel.Caption := 'Look Away!';

  FTimeLabel := TLabel.Create(Self);
  FTimeLabel.Parent := FGroupBox;
  FTimeLabel.Left := 18;
  FTimeLabel.Top := 44;
  FTimeLabel.Caption := '0:00:00';
  FTimeLabel.Font.Height := -24;
  FTimeLabel.Font.Style := [fsBold];

  FDateLabel := TLabel.Create(Self);
  FDateLabel.Parent := FGroupBox;
  FDateLabel.Left := 175;
  FDateLabel.Top := 54;
  FDateLabel.Caption := DateToStr(Date);

  FStopButton := TButton.Create(Self);
  FStopButton.Parent := FGroupBox;
  FStopButton.Left := 18;
  FStopButton.Top := 86;
  FStopButton.Width := 100;
  FStopButton.Height := 25;
  FStopButton.Caption := 'Stop alarm';
  FStopButton.OnClick := @StopButtonClick;

  FHideButton := TButton.Create(Self);
  FHideButton.Parent := FGroupBox;
  FHideButton.Left := 194;
  FHideButton.Top := 86;
  FHideButton.Width := 88;
  FHideButton.Height := 25;
  FHideButton.Caption := 'Hide';
  FHideButton.OnClick := @HideButtonClick;

  FFadeTimer := TTimer.Create(Self);
  FFadeTimer.Interval := 100;
  FFadeTimer.Enabled := False;
  FFadeTimer.OnTimer := @FadeTimerTick;

  FMouseDelayTimer := TTimer.Create(Self);
  FMouseDelayTimer.Interval := 5000;
  FMouseDelayTimer.Enabled := False;
  FMouseDelayTimer.OnTimer := @MouseDelayTimerTick;
end;

procedure TStatusForm.BuildTray;
begin
  FTrayMenu := TPopupMenu.Create(Self);

  FShowItem := TMenuItem.Create(FTrayMenu);
  FShowItem.Caption := 'Show next alarm time';
  FShowItem.OnClick := @ShowItemClick;
  FTrayMenu.Items.Add(FShowItem);

  FStopItem := TMenuItem.Create(FTrayMenu);
  FStopItem.Caption := 'Stop alarm';
  FStopItem.OnClick := @StopItemClick;
  FTrayMenu.Items.Add(FStopItem);

  FTrayMenu.Items.AddSeparator;

  FExitItem := TMenuItem.Create(FTrayMenu);
  FExitItem.Caption := 'Exit';
  FExitItem.OnClick := @ExitItemClick;
  FTrayMenu.Items.Add(FExitItem);

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := 'Look Away!';
  FTrayIcon.PopupMenu := FTrayMenu;
  FTrayIcon.OnClick := @TrayIconClick;
  FTrayIcon.Visible := False;
end;

procedure TStatusForm.PositionAtBottomRight;
begin
  Left := Screen.DesktopWidth - Width - 10;
  Top := Screen.DesktopHeight - Height - 40;
end;

procedure TStatusForm.ShowNextAlarm(const AName: string; const ADueAt: TDateTime; const ASeconds: Int64);
begin
  FNameLabel.Caption := AName;
  Caption := AName;
  FTimeLabel.Caption := TimeToStr(ADueAt);
  FDateLabel.Caption := DateToStr(ADueAt);
  FSecondsLabel.Caption := IntToStr(ASeconds);
  FTrayIcon.Hint := AName + '; next alarm time: ' + TimeToStr(ADueAt);
  FTrayIcon.Visible := True;
  ShowStatusWindow;
end;

procedure TStatusForm.ShowStatusWindow;
begin
  PositionAtBottomRight;
  AlphaBlendValue := 255;
  FormStyle := fsStayOnTop;
  Show;
  BringToFront;
  FFadeTimer.Enabled := True;
  FMouseDelayTimer.Enabled := False;
  FShowItem.Caption := 'Show next alarm time';
end;

procedure TStatusForm.HideToTray;
begin
  FTrayIcon.Visible := True;
  Hide;
  FShowItem.Caption := 'Show next alarm time';
end;

procedure TStatusForm.HideTrayIcon;
begin
  FTrayIcon.Visible := False;
end;

procedure TStatusForm.UpdateTrayHint(const AHint: string);
begin
  FTrayIcon.Hint := AHint;
end;

procedure TStatusForm.StopButtonClick(Sender: TObject);
begin
  if Assigned(FOnStopReminder) then
    FOnStopReminder(Self);
end;

procedure TStatusForm.HideButtonClick(Sender: TObject);
begin
  HideToTray;
end;

procedure TStatusForm.FadeTimerTick(Sender: TObject);
begin
  // The original app deliberately stayed above other windows until the user acted.
  // Keep fsStayOnTop even after the fade starts.
  FormStyle := fsStayOnTop;

  if AlphaBlendValue >= 50 then
    AlphaBlendValue := AlphaBlendValue - 1
  else
    FFadeTimer.Enabled := False;
end;

procedure TStatusForm.MouseDelayTimerTick(Sender: TObject);
begin
  FFadeTimer.Enabled := True;
  FMouseDelayTimer.Enabled := False;
end;

procedure TStatusForm.TrayIconClick(Sender: TObject);
begin
  ShowStatusWindow;
end;

procedure TStatusForm.ShowItemClick(Sender: TObject);
begin
  ShowStatusWindow;
end;

procedure TStatusForm.StopItemClick(Sender: TObject);
begin
  StopButtonClick(Sender);
end;

procedure TStatusForm.ExitItemClick(Sender: TObject);
begin
  if Assigned(FOnExitApp) then
    FOnExitApp(Self);
end;

procedure TStatusForm.FormMouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  FFadeTimer.Enabled := False;
  AlphaBlendValue := 255;
  FormStyle := fsStayOnTop;
  FMouseDelayTimer.Enabled := True;
end;

end.
