unit SettingsStore;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, IniFiles, AlarmService;

type
  TSettingsStore = class
  private
    class function SettingsFileName: string; static;
    class function DateTimeToStableString(const AValue: TDateTime): string; static;
    class function TryStableStringToDateTime(const AValue: string; out ADateTime: TDateTime): Boolean; static;
  public
    class procedure LoadInto(const Alarm: TAlarmService); static;
    class procedure SaveFrom(const Alarm: TAlarmService); static;
  end;

implementation

class function TSettingsStore.SettingsFileName: string;
begin
  Result := GetAppConfigFile(False);
end;

class function TSettingsStore.DateTimeToStableString(const AValue: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd hh":"nn":"ss', AValue);
end;

class function TSettingsStore.TryStableStringToDateTime(const AValue: string; out ADateTime: TDateTime): Boolean;
var
  Y, M, D, H, N, S: Word;
begin
  Result := False;
  ADateTime := 0;

  if Length(AValue) <> 19 then
    Exit;

  try
    Y := StrToInt(Copy(AValue, 1, 4));
    M := StrToInt(Copy(AValue, 6, 2));
    D := StrToInt(Copy(AValue, 9, 2));
    H := StrToInt(Copy(AValue, 12, 2));
    N := StrToInt(Copy(AValue, 15, 2));
    S := StrToInt(Copy(AValue, 18, 2));
    Result := TryEncodeDateTime(Y, M, D, H, N, S, 0, ADateTime);
  except
    Result := False;
  end;
end;

class procedure TSettingsStore.LoadInto(const Alarm: TAlarmService);
var
  Ini: TIniFile;
  DueText: string;
  DueAt: TDateTime;
begin
  Ini := TIniFile.Create(SettingsFileName);
  try
    Alarm.Name := Ini.ReadString('Reminder', 'Name', 'Look Away!');
    Alarm.Active := Ini.ReadBool('Reminder', 'Active', False);
    DueText := Ini.ReadString('Reminder', 'DueAt', '');

    if TryStableStringToDateTime(DueText, DueAt) then
      Alarm.DueAt := DueAt
    else
      Alarm.Active := False;

    if Alarm.Active and (Alarm.DueAt <= Now) then
      Alarm.Active := False;
  finally
    Ini.Free;
  end;
end;

class procedure TSettingsStore.SaveFrom(const Alarm: TAlarmService);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(SettingsFileName);
  try
    Ini.WriteString('Reminder', 'Name', Alarm.Name);
    Ini.WriteBool('Reminder', 'Active', Alarm.Active);
    Ini.WriteString('Reminder', 'DueAt', DateTimeToStableString(Alarm.DueAt));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
