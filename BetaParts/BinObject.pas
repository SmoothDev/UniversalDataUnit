unit BinObject;

interface

uses
  Classes,
  Generics.Collections,
  SysUtils;

type
  TBinItem = class
  private
    FSubItems : TList<TList<Byte>>;
    function FGetBytes(AIndex : integer) : TList<Byte>;
    function FGetCount : integer;
  public
    procedure Add(ABytes : TList<Byte>);
    constructor Create();
    property Count : Integer read FGetCount;
    property Item[AIndex : integer] : TList<Byte> read FGetBytes; default;
  end;

  TBinObject = class
  private
    FBinaryReader : TBinaryReader;
    FBinaryWriter : TBinaryWriter;
    FItems : TList<TBinItem>;
    function FGetCount : integer;
    function FGetItem(AIndex : integer) : TBinItem;
  public
    constructor Create();
    procedure SaveToFile(AFileName : string);
    procedure LoadFromFile(AFileName : string);
    procedure Add(ABinItem : TBinItem);
    property Count : Integer read FGetCount;
    property Item[AIndex : integer] : TBinItem read FGetItem; default;
  end;


  function StringToByteList(AString : string) : TList<Byte>;
  function ByteListToString(AByteList : TList<Byte>) : string;

var
  LastResult : string;
  LastRead : string;
implementation

const
  IndexPrefix = 310;

function ByteListToString(AByteList : TList<Byte>) : string;
var
  c: Integer;
begin
  Result := '';

  for c := 0 to AByteList.Count-1 do
  begin
    Result := Result + (Ansichar(AByteList[c] - IndexPrefix));
  end;
end;

function StringToByteList(AString : string) : TList<Byte>;
var
  c: Integer;
begin
  Result := TList<Byte>.Create;
  for c := 1 to Length(Astring) do
  begin
    Result.Add(Ord(AString[c]) + IndexPrefix);
  end;
end;


{ TBinData }

procedure TBinItem.Add(ABytes: TList<Byte>);
begin
  FSubItems.Add(ABytes);
end;

constructor TBinItem.Create;
begin
  FSubItems := TList<TList<Byte>>.Create;
end;


function TBinItem.FGetBytes(AIndex: integer): TList<Byte>;
begin
  Result := FSubItems[AIndex];
end;

function TBinItem.FGetCount: integer;
begin
  Result := FSubItems.Count;
end;

{ TBinObject }

procedure TBinObject.Add(ABinItem: TBinItem);
begin
  FItems.Add(ABinItem);
end;

constructor TBinObject.Create;
begin
  FItems := TList<TBinItem>.Create;
end;


function TBinObject.FGetCount: integer;
begin
  Result := FItems.Count;
end;

function TBinObject.FGetItem(AIndex: integer): TBinItem;
begin
  Result := FItems[AIndex];
end;

procedure TBinObject.LoadFromFile(AFileName: string);
var
  TransmissionStarted : boolean;
  InValue : Boolean;
  Finished : Boolean;

  LBinItem : TBinItem;
  LByteBuffer : TList<Byte>;
  LStringBuffer : string;
  TeBuffer : TList<Byte>;
  LByte : byte;
begin
  FItems := TList<TBinItem>.Create;
  TransmissionStarted := false;
  InValue := false;
  Finished := false;
  LByteBuffer := TList<Byte>.Create;
  LBinItem := TBinItem.Create;
  LStringBuffer := '';

  FBinaryReader := TBinaryReader.Create(AFileName);

  repeat
    try
      LByte := FBinaryReader.ReadByte;

      if not(TransmissionStarted) then
      begin
        if LByte = $02  then
        begin
          TransmissionStarted := true;
          InValue := true;
          Continue
        end
        else
          raise Exception.Create('Row started wrong.');

        Exit;
      end
      else
      begin
        if InValue then
        begin

          if LByte = $04 then
          begin
            TransmissionStarted := false;

            Add(LBinItem);
            LBinItem := TBinItem.Create;

            Continue;
          end;

          if LByte = $03 then
          begin
            LBinItem.Add(StringToByteList(LStringBuffer));
            LStringBuffer := '';
            Continue;
          end;

          LByteBuffer.Add(LByte);
          LStringBuffer := LStringBuffer + AnsiChar(LByte  - IndexPrefix);
        end
      end;

    except
      Finished := true;
    end;
  until (Finished);

  FBinaryReader.Close;
end;

procedure TBinObject.SaveToFile(AFileName: string);
var
  ItemIndex: Integer;
  LBinItem : TBinItem;
  SubItemIndex: Integer;
  LSubItem : TList<byte>;
  LByte : byte;
  ByteIndex: Integer;
begin
  FBinaryWriter := TBinaryWriter.Create(AFileName);

  LastResult := '';
  for ItemIndex := 0 to Count-1 do
  begin
    FBinaryWriter.Write($2);
    LastResult := LastResult+'2 ';

    LBinItem := Item[ItemIndex];
    for SubItemIndex := 0 to LBinItem.Count-1 do
    begin
      LSubItem := LBinItem.Item[SubItemIndex];
      for ByteIndex := 0 to LSubItem.Count -1 do
      begin
        LByte := LSubItem[ByteIndex];
        FBinaryWriter.Write(LByte);
        LastResult := LastResult+char(LByte);

      end;
        FBinaryWriter.Write($3);
    LastResult := LastResult+' 3 ';
    end;
    FBinaryWriter.Write($4);
    LastResult := LastResult+' 4';
  end;

  FBinaryWriter.Close;
end;

end.
