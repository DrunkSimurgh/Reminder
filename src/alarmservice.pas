unit AlarmService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TAlarmService = class
  private
    FActive: Boolean;
    FDueAt: TDateTime;
    FName: string;
  public
    constructor Create;
    procedure StartAfterMinutes(const AMinutes: Integer; const AName: string);
    procedure StartAt(const ADueAt: TDateTime; const AName: string);
    procedure Stop;
    function IsDue: Boolean;
    function SecondsRemaining: Int64;

    property Active: Boolean read FActive write FActive;
    property DueAt: TDateTime read FDueAt write FDueAt;
    property Name: string read FName write FName;
  end;

implementation

constructor TAlarmService.Create;
begin
  inherited Create;
  FActive := False;
  FDueAt := 0;
  FName := 'Look Away!';
end;

procedure TAlarmService.StartAfterMinutes(const AMinutes: Integer; const AName: string);
begin
  if AMinutes <= 0 then
    raise Exception.Create('Minutes must be greater than zero.');

  StartAt(Now + (AMinutes / (24 * 60)), AName);
end;

procedure TAlarmService.StartAt(const ADueAt: TDateTime; const AName: string);
begin
  if ADueAt <= Now then
    raise Exception.Create('The reminder time must be in the future.');

  FDueAt := ADueAt;
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

  Delta := (FDueAt - Now) * 24 * 60 * 60;
  if Delta < 0 then
    Result := 0
  else
    Result := Trunc(Delta);
end;

end.
