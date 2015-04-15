unit JsonUnit;

interface

uses
  SysUtils;

type
  TJsonType = ( jntArray,
                jntBoolean,
                jntInteger,
                jntFloat,
                jntNull,
                jntObject,
                jntString,
                jntUnknown );


  TStringArray = class
  private
  public
    Strings : array of string;
    procedure Add(AString : string);
    procedure Clear;
    function Count : integer;
  end;

  TJsonObject = class;

  TJsonArray = class;

  TJsonValue = class
  private
    FValue : string;
    function FGetType : TJsonType;
  public
    Key : string;

    procedure GetValue(var AOutput : TJsonArray); overload;
    procedure GetValue(var AOutput : boolean); overload;
    procedure GetValue(var AOutput : double); overload;
    procedure GetValue(var AOutput : integer); overload;
    procedure GetValue(var AOutput : string); overload;
    procedure GetValue(var AOutput : TJsonObject); overload;

    function FormatSyntax(ASpaces : integer) : string;

    procedure Assign(AJsonText : string);
    property NativeValue : string read FValue;

    property ValueType : TJsonType read FGetType;
  end;

  TJsonArray = class
  protected
    FValues : array of TJsonValue;
    function FGetValue(Key : Integer) : TJsonValue;
  public
    procedure Add(AJsonValue : TJsonValue);
    function Count : integer;
    procedure Clear;
    property Value[Key : integer] : TJsonValue read FGetValue; default;
  public

  end;

  TJsonValues = class(TJsonArray)
  protected
    function FGetValue(Key : string) : TJsonValue;
  public
    procedure Add(AString : string; AJsonValue : TJsonValue);
    property Value[Key : string] : TJsonValue read FGetValue; default;
  end;


  TJsonObject = class
  protected
    FValues : TJsonValues;
    FKeys : TStringArray;

    function FGetValue(Key : string) : TJsonValue;
    function FGetCount : Integer;
  public
    constructor Create;

    procedure AddValue(AKey : string; AJsonValue : TJsonValue);

    function FormatSyntax : string;

    procedure Clear();
    procedure Parse(AJsonText : string);

    property Count : integer read FGetCount;
    property Value[Key : string] : TJsonValue read FGetValue; default;
    property Keys : TStringArray read FKeys;
    destructor Destroy(); override;
  end;

    procedure Format(AJsonText : string; var AOutPut: string);

var
  JsonSpaces : integer = 2;

implementation


procedure Format(AJsonText : string; var AOutPut: string);
var
  CurrentCharIndex: Integer;
  CurrentChar : char;
  OutputString : string;
  InString : boolean;
begin
  InString := False;

  for CurrentCharIndex := 1 to Length(AJsonText) do
  begin
    CurrentChar := AJsonText[CurrentCharIndex];

    if (CurrentChar = '"') then
      InString := not InString;

    if ((CurrentChar = ' ') and (InString = false)) or
       ((CurrentChar = #10) or (CurrentChar = #13)) then
      Continue;

    OutputString := OutputString + CurrentChar;
  end;
  AOutPut := OutputString;
end;

{ TJsonObject }

procedure TJsonObject.AddValue(AKey: string; AJsonValue: TJsonValue);
begin
  FValues.Add(AKey, AJsonValue);
end;

procedure TJsonObject.Clear;
begin
  FValues.Clear;
end;

constructor TJsonObject.Create;
begin
  FKeys := TStringArray.Create;
  FValues := TJsonValues.Create;
end;

destructor TJsonObject.Destroy;
begin
  FValues.Free;
  FKeys.Free;
end;

function TJsonObject.FGetCount: Integer;
begin
  Result := FKeys.Count;
end;

function TJsonObject.FGetValue(Key: string): TJsonValue;
begin
  Result := FValues[Key];
end;


function TJsonObject.FormatSyntax: string;
var
  c: Integer;
  LKey : string;
begin
  for c := 0 to Count-1 do
  begin
    LKey := Keys.Strings[c];

    Result := Result + FValues[LKey].FormatSyntax(2);
    if c <> Count-1 then
      Result := Result + ',';

    Result := Result + #13 + #10;
  end;
end;

procedure TJsonObject.Parse(AJsonText: string);
var
  FormatedJsonText : string;

  CurrentCharIndex : integer;
  CurrentChar : Char;
  LastChar : Char;

  CurrentKey : string;

  StringBuffer : string;

  LineStarted : Boolean;

  InKey : Boolean;
  InValue : Boolean;

  KeyDone : Boolean;
  ValueDone : Boolean;

  ObjectStarted : Boolean;

  ObjCount : integer;

  InArray : Boolean;
  ArrCount : integer;
begin
  Format(AJsonText, FormatedJsonText);

  CurrentKey := '';
  StringBuffer := '';
  LineSTarted := false;
  InKey := false;
  InValue := false;
  KeyDone := false;
  ValueDone := false;
  ObjectStarted := false;
  ObjCount := 0;
  ArrCount := 0;

  for CurrentCharIndex := 1 to Length(FormatedJsonText) do
  begin
    CurrentChar := FormatedJsonText[CurrentCharIndex];
    LastChar := FormatedJsonText[CurrentCharIndex-1];

    if (CurrentCharIndex = 1) and
       (CurrentChar = '{') then
    begin
      ObjectStarted := true;
      Continue;
    end;

    if ObjectStarted then
    begin
      if not(InKey) and not(InValue) then
      begin
        if not(KeyDone) then
        begin
          if CurrentChar = '"' then
          begin
            InKey := True;
            Continue;
          end
          else
          begin
            raise Exception.Create('Key muss gestartet werden');
            Break;
          end;
        end
        else if KeyDone and not InKey then
        begin
          if CurrentChar = ':' then
          begin
            InValue := true;
            Continue;
          end
          else
          begin 
            raise Exception.Create('String muss gestartet werden. ' + CurrentKey + ' ' + IntToStr(CurrentCharIndex));
            Break;
          end;
        end;
      end;

      if InKey then
      begin
        if CurrentChar = '"' then
        begin
          CurrentKey := StringBuffer;
          StringBuffer := '';
          AddValue(CurrentKey, TJsonValue.Create);
          Keys.Add(CurrentKey);
          InKey := false;
          KeyDone := true;
          Continue;
        end
        else
        begin
          StringBuffer := StringBuffer + CurrentChar;
        end;
      end;

      if InValue then
      begin
        if CurrentChar = '{' then
        begin
          ObjCount := ObjCount + 1;
        end
        else if CurrentChar = '[' then
        begin
          ArrCount := ArrCount + 1;
        end
        else if (CurrentChar = '}') and
                (not(ObjCount = 0)) then
        begin
          ObjCount := ObjCount - 1;
        end
        else if (CurrentChar = ']') and
                (not(ArrCount = 0)) then
        begin
          ArrCount := ArrCount - 1;
        end
        else if ((CurrentChar = ',') and (ObjCount + ArrCount = 0)) or
                ((CurrentChar = ']') and (ObjCount + ArrCount = 0)) or
                ((CurrentChar = '}') and (ObjCount + ArrCount = 0)) then
        begin
          FValues[CurrentKey].FValue := StringBuffer;
          StringBuffer := '';
          ValueDone := false;
          InValue := false;
          KeyDone := false;
          Continue;
        end;

        StringBuffer := StringBuffer + CurrentChar;
      end;
    end
    else
    begin
      raise Exception.Create('Objekt muss gestartet werden');
      Break;
    end;
  end;
end;

{ TJsonValue }

procedure TJsonValue.Assign(AJsonText: string);
begin
  FValue := AJsonText;
end;

function TJsonValue.FGetType: TJsonType;
var
  LJsonObject : TJsonObject;
  iCode : integer;
  LInteger : integer;
  LFLoat : Double;
begin
  if FValue = '' then
  begin
    Result := jntNull;
    Exit;
  end;

  if (LowerCase(FValue) = 'true') or
     (LowerCase(FValue) = 'false') then
     Result := jntBoolean
  else if (FValue[1] = '"') and
          (FValue[Length(FValue)] = '"') then
    Result := jntString
  else if (FValue[1] = '[') and
          (FValue[Length(FValue)] = ']') then
    Result := jntArray
  else if (FValue[1] = '{') and
          (FValue[Length(FValue)] = '}') then
    Result := jntObject
  else if LowerCase(FValue) = 'null' then
    Result := jntNull
  else
  begin
    Val(FValue,LInteger,iCode);
    if iCode = 0 then
      Result := jntInteger
    else if TryStrToFloat(FValue,LFloat) then
      Result := jntFloat;
  end;
end;


function TJsonValue.FormatSyntax(ASpaces : integer): string;
var
  LSpaces : string;
  c: Integer;
  cc: Integer;

  LArray : TJsonArray;
  LObject : TJsonObject;
  arrayC: Integer;
begin
  Result := '';
  for c := 0 to (ASpaces-1) do
  begin
    for cc := 0 to JsonSpaces-1 do
    begin
      LSpaces := LSpaces + ' ';
    end;
  end;

  case valueType of

    jntArray: begin
      LArray := TJsonArray.Create;
      GetValue(LArray);
      Result := '"' + Key + '": [' + #13#10;
      for arrayC := 0 to LArray.Count-1 do
      begin
        Result := LSpaces + Result + Larray[arrayC].FValue;

        if arrayC <> LArray.Count-1 then
          Result := Result + ',';

        Result := Result + #13#10;
      end;
      Result := Result + LSpaces + ']';

    end;
    jntBoolean: Result := LSpaces + '"' + Key + '": ' + FValue;
    jntInteger: Result := LSpaces + '"' + Key + '": ' + FValue;
    jntFloat: Result := LSpaces + '"' + Key + '": ' + FValue;
    jntNull: Result := LSpaces + '"' + Key + '": null';
    jntObject: begin
      GetValue(LObject);
      Result := Result + LObject.FormatSyntax;
    end;
    jntString: Result := LSpaces + '"' + Key + '": ' + FValue;
    jntUnknown: ;

  end;
end;

procedure TJsonValue.GetValue(var AOutput: TJsonArray);
var
  InKey : Boolean;
  InValue : Boolean;

  LJsonArray : TJsonArray;

  CurrentCharIndex: Integer;
  CurrentChar : Char;

  StringBuffer : string;

  ArrCount : integer;
  ObjCount : integer;
begin
  ObjCount := 0;
  ArrCount := 0;

  InKey := False;
  InValue := false;

  StringBuffer := '';

  LJsonArray := TJsonArray.Create;

  for CurrentCharIndex := 2 to Length(FValue)-1 do
  begin
    CurrentChar := FValue[CurrentCharIndex];

    if CurrentChar = '{' then
      ObjCount := ObjCount + 1
    else if CurrentChar = '}' then
      ObjCount := ObjCount - 1
    else if CurrentChar = '[' then
      ArrCount := ArrCount + 1
    else if CurrentChar = ']' then
      ArrCount := ArrCount - 1;

    if (not(CurrentChar = ',')) or (ArrCount + ObjCount >= 1) then
    begin
      StringBuffer := StringBuffer + CurrentChar;
    end;

    if ((CurrentChar = ',') and
       (ArrCount + ObjCount = 0)) or
       (CurrentCharIndex = Length(FValue)-1) then
    begin
      if StringBuffer = '' then
      begin
        raise Exception.Create('No Input to array field');
        Exit;
      end;
      LJsonArray.Add(TJsonValue.Create);
      LJsonArray[LJsonArray.Count-1].Assign(StringBuffer);
      StringBuffer := '';
    end;
  end;

  AOutput := LJsonArray;
end;

procedure TJsonValue.GetValue(var AOutput: integer);
begin
  try
    AOutput := StrToInt(FValue);
  except
    raise Exception.Create('Inhalt ist kein Integer. "' + FValue + '"');
  end;
end;

procedure TJsonValue.GetValue(var AOutput: boolean);
begin
  if LowerCase(FValue) = 'true' then
    AOutput := true
  else if LowerCase(FValue) = 'false' then
    AOutput := False
  else
    raise Exception.Create('Inhalt ist kein Boolean. "' + FValue + '"');
end;

procedure TJsonValue.GetValue(var AOutput: TJsonObject);
begin
  AOutput.Parse(FValue);
end;

procedure TJsonValue.GetValue(var AOutput: double);
begin
  try
    AOutput := StrToFloat(FValue);
  except
    raise Exception.Create('Inhalt ist kein Float. "' + FValue + '"');
  end;
end;

procedure TJsonValue.GetValue(var AOutput: string);
begin
  if (FValue[1] = '"') and
     (FValue[Length(FValue)] = '"') then
    AOutput := Copy(FValue, 2, Length(FValue)-2)
  else
    raise Exception.Create('Inhalt ist kein String. "' + FValue + '"');
end;

{ TStringArray }

procedure TStringArray.Add(AString: string);
begin
  SetLength(Strings, Length(Strings)+1);
  Strings[Length(Strings)-1] := AString;
end;

procedure TStringArray.Clear;
begin

end;

function TStringArray.Count: integer;
begin
  Result := Length(Strings);
end;

{ TJsonArray }

procedure TJsonArray.Add(AJsonValue: TJsonValue);
begin
  SetLength(FValues, Count+1);
  FValues[Count-1] := AJsonValue;
end;

procedure TJsonArray.Clear;
begin

end;

function TJsonArray.Count: integer;
begin
  Result := Length(FValues);
end;

function TJsonArray.FGetValue(Key: Integer): TJsonValue;
begin
  Result := FValues[Key];
end;

{ TJsonValues }

procedure TJsonValues.Add(AString: string; AJsonValue: TJsonValue);
begin
  inherited Add(AJsonValue);
  FValues[Count-1].Key := AString;
end;

function TJsonValues.FGetValue(Key: string): TJsonValue;
var
  c: Integer;
begin
  for c := 0 to Count-1 do
  begin
    if FValues[c].Key = Key then
      Result := FValues[c];
  end;
end;

end.
