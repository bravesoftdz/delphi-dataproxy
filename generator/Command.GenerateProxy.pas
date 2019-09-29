unit Command.GenerateProxy;

interface

uses
  System.Classes, System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  Comp.Generator.DataSetCode,
  Comp.Generator.ProxyCode;

type
  TProxyGeneratorCommand = class(TComponent)
  private
    GeneratedCode: TStringList;
    ProxyGenerator: TProxyCodeGenerator;
    DataSetGenerator: TGenerateDataSetCode;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destory;
    function Execute(dataset: TDataSet): String;
  end;

implementation

type
  TStringListHelper = class helper for TStringList
    procedure LineReplace(const LineToReplace, NewLine: string);
  end;

  { TStringListHelper }

procedure TStringListHelper.LineReplace(const LineToReplace, NewLine: string);
begin
  Self.Text := StringReplace(Self.Text, LineToReplace, NewLine, [rfReplaceAll]);
end;

{ TProxyGeneratorCommand }

constructor TProxyGeneratorCommand.Create(AOwner: TComponent);
begin
  inherited;
  GeneratedCode := TStringList.Create;
  ProxyGenerator := TProxyCodeGenerator.Create(Self);
  DataSetGenerator := TGenerateDataSetCode.Create(Self);
end;

destructor TProxyGeneratorCommand.Destory;
begin
  GeneratedCode.Free;
end;

function TProxyGeneratorCommand.Execute(dataset: TDataSet): String;
begin
  ProxyGenerator.dataset := dataset;
  ProxyGenerator.Execute;
  GeneratedCode := ProxyGenerator.Code;
  // -----------
  DataSetGenerator.dataset := dataset;
  DataSetGenerator.IndentationText := '  ';
  DataSetGenerator.Execute;
  // -----------
  with GeneratedCode do
  begin
    LineReplace('  public', '  public' + sLineBreak +
      '    class function CreateMockTable (AOwner: TComponent): TFDMemTable;');
    Add('');
    Add('// -----------------------------------------------------------');
    Add('');
    Add('class function T{ObjectName}Proxy.CreateMockTable (AOwner: TComponent): TFDMemTable;');
    Add('var');
    Add('  ds: TFDMemTable;');
    Add('begin');
    AddStrings(DataSetGenerator.CodeWithStructure);
    AddStrings(DataSetGenerator.CodeWithAppendData);
    Add('  Result := ds;');
    Add('end;');
  end;
  Result := GeneratedCode.Text;
end;

end.
