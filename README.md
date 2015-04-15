# UniversalDataUnit.pas
An universal unit for data processing.


Example:
```
var
  LIniObject : TIniObject;
begin
  LIniObject := TIniObject.Create;
  LIniObject.LoadFromFile('./config.ini');
  
  ShowMessage(LIniObject['sector']['property']);
end;
```
