unit CsvObject;

interface

uses
  Types,
  Classes,
  SysUtils,
  Generics.Collections;

type

  TCsvItem = class
  private
    FValues : TList<string>;
    function FGetValue(index : integer) : string;
    function FGetCount : integer;
  public
    constructor Create;
    procedure Add(AString : string);
    procedure Assign(AList : TList<string>);
    property Value[index : integer] : string read FGetValue; default;
    property Count : integer read FGetCount;
    property Values : TList<string> read FValues;
  end;


  TCsvObject = class
  private
    FItems : TList<TCsvItem>;
    function FGetItem(index : integer) : TCsvItem;
    function FGetCount : integer;
  public
    constructor Create;

    procedure Add(ACsvItem : TCsvItem);
    procedure LoadFromFile(AFileName : string);
    procedure SaveToFile(AFileName : string);
    property Item[index : integer] : TCsvItem read FGetItem; default;
    property Count : integer read FGetCount;
  end;


const
  CsvDelimiter = ';';
  CsvSteps = 1;

implementation

procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings) ;
begin
   ListOfStrings.Clear;
   ListOfStrings.Delimiter       := Delimiter;
   ListOfStrings.StrictDelimiter := True;
   ListOfStrings.DelimitedText   := Str;
end;

{ TCSVValue }

procedure TCsvItem.Add(AString: string);
begin
  FValues.Add(AString);
end;

procedure TCsvItem.Assign(AList: TList<string>);
begin
  FValues := AList;
end;

constructor TCsvItem.Create;
begin
  FValues := TList<string>.Create;
end;

function TCsvItem.FGetCount: integer;
begin
  Result := FValues.Count;
end;

function TCsvItem.FGetValue(index: integer): string;
begin
  Result := FValues[index];
end;

{ TCsvObject }

procedure TCsvObject.Add(ACsvItem: TCsvItem);
begin
  FItems.Add(ACsvItem)
end;

constructor TCsvObject.Create;
begin
  FItems := TList<TCsvItem>.Create;
end;


function TCsvObject.FGetCount: integer;
begin
  Result := FItems.Count;
end;

function TCsvObject.FGetItem(index: integer): TCsvItem;
begin
  Result := FItems[index];

end;

procedure TCsvObject.LoadFromFile(AFileName : string);
var
  LStringList : TStringList;
  CurrentLine: Integer;
  CurrentString : string;
  LSplits : TStringList;
  c: Integer;

  LCsvItem : TCsvItem;
begin
  LStringList := TStringList.Create;

  LStringList.LoadFromFile(AFileName);

  for CurrentLine := 0 to LStringList.Count-1 do
  begin
    CurrentString := LStringList[CurrentLine];

    LSplits := TStringList.Create;
    Split(CsvDelimiter, CurrentString, LSplits);

    LCsvItem := TCsvItem.Create;

    for c := 0 to LSplits.Count-1 do
    begin
      LCsvItem.Add(LSplits[c]);
    end;

    FItems.Add(LCsvItem);
    if (CurrentLine mod 8) = 0 then
      Sleep(CsvSteps);
  end;

end;

procedure TCsvObject.SaveToFile(AFileName : string);
var
  c: Integer;
  LineBuffer : string;
  cc: Integer;
  LFile : TStringList;
begin
  LFile := TStringList.Create;
      LineBuffer := '';

  for c := 0 to FItems.Count -1 do
  begin
    for cc := 0 to FItems[c].Count-1 do
    begin
      if cc <> 0 then
        LineBuffer := LineBuffer + CsvDelimiter;
      LineBuffer := LineBuffer + FItems[c][cc];
    end;
      LFile.Add(LineBuffer);
      LineBuffer := '';
      if (c mod 7) = 0 then
        Sleep(CsvSteps);
  end;

  LFile.SaveToFile(AFileName);
end;

end.
