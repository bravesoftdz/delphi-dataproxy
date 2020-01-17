﻿unit Test.ProxyGenerator;

interface

uses
  DUnitX.TestFramework,
  System.Classes, System.SysUtils, System.Variants,
  Data.DB,
  FireDAC.Comp.Client,
  Wrapper.TProxyGenerator;

{$M+}

type

  [TestFixture]
  TestGenerator = class(TObject)
  private
    fOwner: TComponent;
    fGenerator: TTestProxyDataGenerator;
    MemDataSet: TFDMemTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    // -------------
    procedure Test_UnitHeader_IsEmpty;
    procedure Test_UsesSection;
    procedure Test_ClassDeclaration_DataSetNil;
    procedure Test_ClassDeclaration_DataSetOneField;
    procedure Test_MethodConnectFields_DataSetNil;
    procedure Test_MethodConnectFields_DataSetOneField;
  end;

implementation

// -----------------------------------------------------------------------
// Utils section
// -----------------------------------------------------------------------

// -----------------------------------------------------------------------
// Setup and TearDown section
// -----------------------------------------------------------------------

procedure TestGenerator.Setup;
begin
  fOwner := TComponent.Create(nil);
  fGenerator := TTestProxyDataGenerator.Create(fOwner);
  with fGenerator do
  begin
    GenCommentsWithPublicDataSet := false;
  end;
  MemDataSet := TFDMemTable.Create(fOwner);
end;

procedure TestGenerator.TearDown;
begin
  fOwner.Free;
end;

// -----------------------------------------------------------------------
// Templates
// -----------------------------------------------------------------------

type
  TProxyTemplates = class
  const
    SingeCodeIndentation = '  ';
    Section_Uses =
    (* *) 'uses→' +
    (* *) '◇Data.DB,→' +
    (* *) '◇Data.DataProxy,→' +
    (* *) '◇System.SysUtils,→' +
    (* *) '◇System.Classes,→' +
    (* *) '◇FireDAC.Comp.Client;→';
    Section_ClassDeclatarion =
    (* *) 'type→' +
    (* *) '◇T{ObjectName}Proxy = class(TDatasetProxy)→' +
    (* *) '◇private→' +
    (* *) '◇protected→' +
    (* *) '◇◇procedure ConnectFields; override;→' +
    (* *) '◇public→' +
    (* *) '◇end;→';
    Section_ClassDeclatarion_WithIntField =
    (* *) 'type→' +
    (* *) '◇T{ObjectName}Proxy = class(TDatasetProxy)→' +
    (* *) '◇private→' +
    (* *) '◇◇FFieldInteger :TIntegerField;→' +
    (* *) '◇protected→' +
    (* *) '◇◇procedure ConnectFields; override;→' +
    (* *) '◇public→' +
    (* *) '◇◇property FieldInteger :TIntegerField read FFieldInteger;→' +
    (* *) '◇end;→';
    Section_MethodConnectFields =
    (* *) 'procedure T{ObjectName}Proxy.ConnectFields;→' +
    (* *) 'const→' +
    (* *) '◇ExpectedFieldCount = 0;→' +
    (* *) 'begin→' +
    (* *) '◇Assert(FDataSet.Fields.Count = ExpectedFieldCount);→' +
    (* *) 'end;→';
    Section_MethodConnectFields_WithIntegerField =
    (* *) 'procedure T{ObjectName}Proxy.ConnectFields;→' +
    (* *) 'const→' +
    (* *) '◇ExpectedFieldCount = 1;→' +
    (* *) 'begin→' +
    (* *) '◇FFieldInteger := FDataSet.FieldByName(''FieldInteger'') as TIntegerField;→'
      +
    (* *) '◇Assert(FDataSet.Fields.Count = ExpectedFieldCount);→' +
    (* *) 'end;→';
  strict private
    class var Expected: string;
    class function ReplaceArrowsAndDiamonds(const s: String): string;
  public
    class procedure Asset_UsesSection(Code: TStrings);
    class procedure Assert_ClassDeclaration(Code: TStrings);
    class procedure Assert_ClassDeclaration_WithIntegerField(Code: TStrings);
    class procedure Assert_MethodConnectFields(Code: TStrings);
    class procedure Assert_MethodConnectFields_WithIntegerField(Code: TStrings);
  end;

class function TProxyTemplates.ReplaceArrowsAndDiamonds
  (const s: String): string;
begin
  Result := StringReplace(s, '→', #13#10, [rfReplaceAll]);
  Result := StringReplace(Result, '◇', SingeCodeIndentation, [rfReplaceAll])
end;

class procedure TProxyTemplates.Asset_UsesSection(Code: TStrings);
begin
  Expected := ReplaceArrowsAndDiamonds(Section_Uses);
  Assert.AreEqual(Expected, Code.Text);
end;

class procedure TProxyTemplates.Assert_ClassDeclaration(Code: TStrings);
begin
  Expected := ReplaceArrowsAndDiamonds(Section_ClassDeclatarion);
  Assert.AreEqual(Expected, Code.Text);
end;

class procedure TProxyTemplates.Assert_ClassDeclaration_WithIntegerField
  (Code: TStrings);
begin
  Expected := ReplaceArrowsAndDiamonds(Section_ClassDeclatarion_WithIntField);
  Assert.AreEqual(Expected, Code.Text);
end;

class procedure TProxyTemplates.Assert_MethodConnectFields(Code: TStrings);
begin
  Expected := ReplaceArrowsAndDiamonds(Section_MethodConnectFields);
  Assert.AreEqual(Expected, Code.Text);
end;

class procedure TProxyTemplates.Assert_MethodConnectFields_WithIntegerField
  (Code: TStrings);
begin
  Expected := ReplaceArrowsAndDiamonds
    (Section_MethodConnectFields_WithIntegerField);
  Assert.AreEqual(Expected, Code.Text);
end;


// -----------------------------------------------------------------------
// Tests: Unit Header / Uses Section
// -----------------------------------------------------------------------


procedure TestGenerator.Test_UnitHeader_IsEmpty;
begin
  fGenerator.Generate_UnitHeader;
  Assert.AreEqual('', fGenerator.Code.Text);
end;

procedure TestGenerator.Test_UsesSection;
begin
  fGenerator.Generate_UsesSection;
  TProxyTemplates.Asset_UsesSection(fGenerator.Code);
end;


// -----------------------------------------------------------------------
// Tests: Class Declaration
// -----------------------------------------------------------------------


procedure TestGenerator.Test_ClassDeclaration_DataSetNil;
begin
  fGenerator.Generate_ClassDeclaration;
  TProxyTemplates.Assert_ClassDeclaration(fGenerator.Code);
end;

procedure TestGenerator.Test_ClassDeclaration_DataSetOneField;
begin
  with MemDataSet do
  begin
    FieldDefs.Add('FieldInteger', ftInteger);
    CreateDataSet;
  end;
  fGenerator.DataSet := MemDataSet;
  fGenerator.Generate_ClassDeclaration;
  TProxyTemplates.Assert_ClassDeclaration_WithIntegerField
    (fGenerator.Code);
end;


// -----------------------------------------------------------------------
// Tests: Method ConnectFields
// -----------------------------------------------------------------------


procedure TestGenerator.Test_MethodConnectFields_DataSetNil;
begin
  fGenerator.Generate_MethodConnectFields;
  TProxyTemplates.Assert_MethodConnectFields(fGenerator.Code);
end;

procedure TestGenerator.Test_MethodConnectFields_DataSetOneField;
begin
  with MemDataSet do
  begin
    FieldDefs.Add('FieldInteger', ftInteger);
    CreateDataSet;
  end;
  fGenerator.DataSet := MemDataSet;
  fGenerator.Generate_MethodConnectFields;
  TProxyTemplates.Assert_MethodConnectFields_WithIntegerField
    (fGenerator.Code);
end;


initialization

TDUnitX.RegisterTestFixture(TestGenerator);

end.
