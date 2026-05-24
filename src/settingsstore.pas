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
  if AValue <= 0 then
    Result := ''
  else
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
    if (M < 1) or (M > 12) or (D < 1) or (D > 31) or
       (H > 23) or (N > 59) or (S > 59) then
      Exit;

    ADateTime := EncodeDate(Y, M, D) + EncodeTime(H, N, S, 0);
    Result := True;
  except
    Result := False;
  end;
end;

class procedure TSettingsStore.LoadInto(const Alarm: TAlarmService);
var
  Ini: TIniFile;
  DueText, ActivatedText: string;
  ADateTime: TDateTime;
begin
  Ini := TIniFile.Create(SettingsFileName);
  try
    Alarm.Name := Ini.ReadString('Reminder', 'Name', 'Look Away!');
    Alarm.Active := Ini.ReadBool('Reminder', 'Active', False);

    DueText := Ini.ReadString('Reminder', 'DueAt', '');
    if TryStableStringToDateTime(DueText, ADateTime) then
      Alarm.DueAt := ADateTime
    else
      Alarm.DueAt := 0;

    ActivatedText := Ini.ReadString('Reminder', 'ActivatedAt', '');
    if TryStableStringToDateTime(ActivatedText, ADateTime) then
      Alarm.ActivatedAt := ADateTime
    else
      Alarm.ActivatedAt := 0;
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
    Ini.WriteString('Reminder', 'ActivatedAt', DateTimeToStableString(Alarm.ActivatedAt));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
