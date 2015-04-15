// --------------------------------------------------------------------------
// UniversalDataUnit
// Version 0.1DPP (DelphiPraxis Preview)
// --------------------------------------------------------------------------
// There is no limitation with this code.
// If you want to use, change and/or upload the code, just do it =)
// --------------------------------------------------------------------------
// Features:
// - INI Files
//  - Create INI Object
//  - Load File to Object
//  - Parse String/TStringList to Object
//  - Save Object to File
// --------------------------------------------------------------------------
// Authors:
// Stanojevic Milos
// Email: contact@svr2k.de
//
// (add yourself here)
// --------------------------------------------------------------------------

unit UniversalDataUnit;

interface

uses
  Generics.Collections,
  Classes,
  SysUtils,
  System.RegularExpressions;

type
  { INI CLASSES START }
  TIniSection = class
  private
    FValues : TDictionary<string, string>;
    function FGetValue(AKey: string) : string;
    procedure FSetValue(AKey : string; AProperty : string);
  public
    Title : string;
    constructor Create(ATitle : string);
    function ContainsKey(AKey : string): Boolean;
    property Value[AKey : string] : string read FGetValue write FSetValue; default;
  end;

  TIniObject = class
  private
    FSections : TList<TIniSection>;
    function FGetSection(AIndex : string) : TIniSection;
    function FGetTitle(AIndex : integer) : string;
  public
    constructor Create();
    procedure Parse(AStringList : TStrings);
    procedure LoadFromFile(AFileName : string);
    procedure SaveToFile(AFileName : string);
    function ContainsSection(ASection : string) : Boolean;
    procedure AddSection(AIniSection : TIniSection);
    procedure AddValue(ASection, AKey, AProperty : string); overload;
    procedure AddValue(ASection, AKey, AProperty : string; AAutoCreate : boolean); overload;
    property Section[Index : string] : TIniSection read FGetSection; default;
    property Title[index : integer] : string read FGetTitle;
  end;
  { INI CLASSES END }


  { JSON CLASSES START }


  TJSONObject = class
  private
  public
    test : string;

  end;

  TJSONParser = class
  private
    FCurrentCharIndex : integer;
  public
    procedure Parse(AString : string; var AJSONObject : TJSONObject); overload;
    procedure Parse(AStrings : TStrings; var AJSONObject : TJSONObject); overload;
  end;


  { INI CLASSES END }

implementation

{ TIniConfig }

procedure TIniObject.AddSection(AIniSection: TIniSection);
var
  LIndex : integer;
begin
  LIndex := FSections.Add(AIniSection);
end;

procedure TIniObject.AddValue(ASection, AKey, AProperty: string);
begin
  Section[ASection].FValues.Add(AKey, AProperty);
end;

procedure TIniObject.AddValue(ASection, AKey, AProperty: string; AAutoCreate : boolean);
begin
  if AAutoCreate then
  begin
    if ContainsSection(ASection) then
      AddValue(ASection, AKey, AProperty);
  end
  else
  begin
    AddSection(TIniSection.Create(ASection));
    AddValue(ASection, AKey, AProperty);
  end;
end;

function TIniObject.ContainsSection(ASection: string): Boolean;
var
  c: Integer;
begin
  for c := 0 to FSections.Count-1 do
    if FSections[c].Title = ASection then
      Result := true;
end;

constructor TIniObject.Create;
begin
  FSections := TList<TIniSection>.Create();
end;

function TIniObject.FGetSection(AIndex : string): TIniSection;
var
  c: Integer;
begin
  for c := 0 to FSections.Count-1 do
    if FSections[c].Title = AIndex then
      Result := FSections[c];


  if Result = nil then
    raise Exception.Create(AIndex + ' konnte nicht gefunden werden');
end;

function TIniObject.FGetTitle(AIndex: integer): string;
begin
  Result := FSections[AIndex].Title;
end;

procedure TIniObject.LoadFromFile(AFileName: string);
var
  LStringList : TStringList;
begin
  if FileExists(AFileName) then
  begin
    LStringList := TStringList.Create;
    LStringList.LoadFromFile(AFileName);
    Parse(LStringList);
  end
  else
    raise Exception.Create(AFileName + ' wurde nicht gefunden');

  LStringList.Free;
end;

procedure TIniObject.Parse(AStringList: TStrings);
var
  LLine : string;
  LParts : TStringList;
  c: Integer;
begin
  LParts := TStringList.Create;
  for c := 0 to AStringList.Count - 1 do
  begin
    LLine := AStringList[c];

    if Length(LLine) < 1 then
    Continue;

    if LLine[1] = ';' then
      Continue
    else if (LLine[1] = '[') and (LLine[Length(LLine)] = ']') then
    begin
      AddSection(TIniSection.Create(Copy(LLine,2,Length(LLine)-2)));
      Continue;
    end
    else if (TRegEx.IsMatch(LLine, '^[a-zA-Z0-9]*=[a-zA-Z0-9(./)]*$')) then
    begin
      LParts.Clear;
      LParts.StrictDelimiter := true;
      LParts.Delimiter := '=';
      LParts.DelimitedText := LLine;

      FSections[FSections.Count-1].FValues.Add(LParts[0],LParts[1]);
    end
    else
      raise Exception.Create('Fehler beim laden der INI-Datei.' + #10 +
                             'Zeile: ' + IntToStr(c + 1) + #10 +
                             '"' + LLine + '" ist keine gültige INI Anweisung.');


  end;

  LParts.Free;
end;

procedure TIniObject.SaveToFile(AFileName: string);
var
  LStringList : TStringList;
  LPair : TPair<string, string>;
  c: Integer;
begin
  LStringList := TStringList.Create;

  for c := 0 to FSections.Count-1 do
  begin
    LStringList.Add('[' + FSections[c].Title + ']');
    for LPair in FSections[c].FValues do
      LStringList.Add(LPair.Key + '=' + LPair.Value);


    LStringList.Add('');
  end;

  LStringList.SaveToFile(AFileName);
  LStringList.Free;
end;

{ TIniSection }

function TIniSection.ContainsKey(AKey : string): Boolean;
var
  c: Integer;
begin
  Result := FValues.ContainsKey(AKey);
end;

constructor TIniSection.Create(ATitle : string);
begin
  Title := ATitle;
  FValues := TDictionary<string, string>.Create;
end;


function TIniSection.FGetValue(AKey: string): string;
begin
  Result := FValues[AKey];
end;

procedure TIniSection.FSetValue(AKey, AProperty: string);
begin
  if ContainsKey(AKey) then
    FValues[AKey] := AProperty;
end;


{ TJSONParser }

procedure TJSONParser.Parse(AString: string; var AJSONObject: TJSONObject);
var
  LCharacterIndex: Integer;
begin
  for LCharacterIndex := 1 to Length(AString) do
  begin

  end;
end;

procedure TJSONParser.Parse(AStrings: TStrings; var AJSONObject: TJSONObject);
begin
  Parse(AStrings.Text, AJSONObject)
end;

end.

