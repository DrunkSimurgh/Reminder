unit AlarmService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils;

type
  TAlarmService = class
  private
    FActive: Boolean;
    FDueAt: TDateTime;
    FName: string;
    FActivatedAt: TDateTime;
  public
    constructor Create;
    procedure StartAfterSeconds(const ASeconds: Integer; const AName: string);
    procedure StartAfterMinutes(const AMinutes: Integer; const AName: string);
    procedure StartAfterHours(const AHours: Integer; const AName: string);
    procedure StartAt(const ADueAt: TDateTime; const AName: string);
    procedure Stop;
    function IsDue: Boolean;
    function SecondsRemaining: Int64;
    function SecondsLate: Int64;

    property Active: Boolean read FActive write FActive;
    property DueAt: TDateTime read FDueAt write FDueAt;
    property ActivatedAt: TDateTime read FActivatedAt write FActivatedAt;
    property Name: string read FName write FName;
  end;

implementation

constructor TAlarmService.Create;
begin
  inherited Create;
  FActive := False;
  FDueAt := 0;
  FActivatedAt := 0;
  FName := 'Look Away!';
end;

procedure TAlarmService.StartAfterSeconds(const ASeconds: Integer; const AName: string);
begin
  if ASeconds <= 0 then
    raise Exception.Create('The delay must be greater than zero.');

  StartAt(Now + (ASeconds / SecsPerDay), AName);
end;

procedure TAlarmService.StartAfterMinutes(const AMinutes: Integer; const AName: string);
begin
  StartAfterSeconds(AMinutes * SecsPerMin, AName);
end;

procedure TAlarmService.StartAfterHours(const AHours: Integer; const AName: string);
begin
  StartAfterSeconds(AHours * SecsPerHour, AName);
end;

procedure TAlarmService.StartAt(const ADueAt: TDateTime; const AName: string);
begin
  if ADueAt <= Now then
    raise Exception.Create('Not a valid time!');

  FDueAt := ADueAt;
  FActivatedAt := Now;
  FActive := True;

  if Trim(AName) = '' then
    FName := 'Look Away!'
  else
    FName := Trim(AName);
end;

procedure TAlarmService.Stop;
begin
  FActive := False;
end;

function TAlarmService.IsDue: Boolean;
begin
  Result := FActive and (Now >= FDueAt);
end;

function TAlarmService.SecondsRemaining: Int64;
var
  Delta: Double;
begin
  if not FActive then
    Exit(0);

  Delta := (FDueAt - Now) * SecsPerDay;
  if Delta < 0 then
    Result := 0
  else
    Result := Trunc(Delta);
end;

function TAlarmService.SecondsLate: Int64;
var
  Delta: Double;
begin
  if FDueAt <= 0 then
    Exit(0);

  Delta := (Now - FDueAt) * SecsPerDay;
  if Delta < 0 then
    Result := 0
  else
    Result := Trunc(Delta);
end;

end.
