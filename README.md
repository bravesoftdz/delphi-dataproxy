﻿# DataProxy Pattern for Delphi

![ Delphi Support ](https://img.shields.io/badge/Delphi%20Support-%20XE8%20..%2010.3%20Rio-blue.svg)
![ version ](https://img.shields.io/badge/version-%200.9-yellow.svg)

-------------------------------------------------------------------
TBD in ver. 1.0 (plan)

1) Separate two sections:
   * refactoring dataset into `TDataSetProxy`
   * inserting extracted code into unit test harness
1) Remove `TDataProxyFactory` use `WithDataSet`
1) Update docs according to current folder structure:
   * `proxy` -> `src`
   * `generator` -> `tools\generator-app`


-------------------------------------------------------------------
## Overview

TDataSetProxy is a wrapper component for the classic Delphi dataset component. It allows to replace any dataset with a fake dataset (in-memory table). Proxy can be used to separate a business class from datasets, this separation is helpful when the business code needs to be putted into automated test harness (unit tests).

![](./doc/resources/datasetproxy-diagram.png)

**Inspiration**. Idea is based on Proxy GoF pattern and Active Record pattern, defined by Martin Fowler in book **Patterns of Enterprise Application Architecture**

## Why using proxy?

DataSet Proxy pattern is helpful during the business logic extraction. This could be especially useful for improving legacy, highly coupled projects. When production code is dependent on a SQL data and SQL connection, it's really difficult to write unit tests for such code.

Replacing dataset with proxies introduce new abstraction level which can facilitate both: SQL datasets in production code and memory datasets in test project. Proxy has very similar interface (methods list) to classic dataset, which help in easy migration. Fake datasets will allow to verify (assert) production code without connecting to database.

DataSet Proxy together with two companion projects (DataSet Generator, Delphi Command Pattern) gives developers opportunity to introduce unit tests with with safe refactorings. 

Dataset proxy is a temporary solution and after covering code with the tests engineers can apply more advanced refactorings: decoupling code or make it more composable and reusable. As one of these refactorings proxy can be safely replaced by the DAO object or by the model data structures.

Together with code and quality improvement developers will learn how to write cleaner code or how to use test first approach and work better.

Supportive projects
| Project | GitHub Repo |
| --- | --- |
| Command Pattern for Delphi | https://github.com/bogdanpolak/command-delphi |
| DataSet Generator | https://github.com/bogdanpolak/dataset-generator |

## Proxy generation

Project includes source code of base class `TDataSetProxy` and two different types of proxy generators:

1) **Component TDataProxyGenerator**
   - unit `src/Comp.Generator.DataProxy.pas`
   - As an input receives dataset and as an output generates text/code: unit containing proxy class inherited from `TDataSetProxy`
2) Tool: **Generator App for FireDAC**
   - tool source: `tools/generator-app`
   - VCL Forms application written in Delphi which is able to connect to SQL server via FireDAC, then prepare SQL command, fetch result dataset and generate proxy class together with dataset fake

Component is useful when engineer wants to generate proxy for exiting dataset in production code. This is two steps easy task: (1) add component unit to uses section, (2) find code using dataset and call generator execute method:

```pas
// --------------------------------
// curent production code:
dbgridBooks.DataSource.Dataset := fDBConnection.
  ConstructSQLSataSet(aOwner, APPSQL_SelectBooks);
// --------------------------------
// injected generator code:
proxy := TDataProxyGenerator.Create(aOwner);
proxy.ObjectName := 'Books';
proxy.DataSet := dbgridBooks.DataSource.Dataset;
proxy.Execute;
proxy.Code.SaveToFile('Proxy.Books.pas');
```

## TDataSetProxy class

TBD

Sample proxy class created by generator:

```pas
type
  TBookProxy = class(TDatasetProxy)
  private
    FISBN :TWideStringField;
    FTitle :TWideStringField;
    FReleseDate :TDateField;
    FPages :TIntegerField;
    FPrice :TBCDField;
  protected
    procedure ConnectFields; override;
  public
    property ISBN :TWideStringField read FISBN;
    property Title :TWideStringField read FTitle;
    property ReleseDate :TDateField read FReleseDate;
    property Pages :TIntegerField read FPages;
    property Price :TBCDField read FPrice;
  end;
```

## Why engineers need to change?

This project is effect of many years and multiple teams experience. This teams found that classic event based Delphi approach is not only less productive, but even dangerous for the developers, the managers and for the customers.

Working with RDBMS (SQL servers) in Delphi looks to be very productive and simple. Developer drops a `Query` component, enters SQL command, sets Active property, connects all DB-aware controls to query and you are done ... almost done, almost but actually far from being ready to deliver application. 

Using this simple visual pattern developer can expose and modify SQL server data extremely quickly. In reality what looks simple at the begging, latter becomes challenging. Within time engineers create more and more datasets and events, defragmenting business flow and mixing presentation, configuration and domain code. Project becomes more and more messy and coupled. After some years managers and developers lose control over such project: plans and deadlines are not possible to quantify, customers are struggling with unexpected and strange bugs, simple changes require many hours of work.

- **Pros of classic even approach**:
   - Intuitive
   - Easy to learn
   - Productive (in initial phases)
   - Easy prototyping
   - Easy to debug
- **Cons of classic approach**:
   - Messy code
   - Almost no architectural design
   - Massive copy-paste development - difficult to reuse code
   - Mixing layers - manipulation of user controls along with business logic and data in a single class or even in a single method
   - High technical debt
   - Stagnation and team demotivation - developers aren’t motivated to learn, improve and change
   - No or minimalistic unit test coverage

## Using dataset proxy in action

Replacing classic dataset with proxy requires some time to learn and validate in action. This approach looks a little strange for many Delphi Developers, but is easy to adopt. Proper management support and team coaching will allow team faster adopt proxy technique.

Proxy dataset is a simple and safe tool to refactor a classic VCL application builded using EDP (Event Driven Programming) technique. Using this solution some small, but important portions of business code can be extracted and covered with unit tests and after that with better safety net protection code can be improved using more advanced refactoring techniques.

The modernization process includes following steps: 
1. The proxy generation
2. Moving the behavior to the proxy (optional)
3. Create the proxy
4. Replace `TDataSet` with the proxy
5. Replace static DataSet with dynamic

### Step 1. The proxy generation

Using the generator application it's possible to create automatically proxy unit. Sample unit `Data.Proxy.Book.pas` can looks like that:

```pas
unit Data.Proxy.Book;

interface
uses
  Data.DB,
  Data.DataProxy;

type
  TBookProxy = class(TDatasetProxy)
  private
    FISBN :TWideStringField;
    FTitle :TWideStringField;
    FAuthors :TWideStringField;
    FPrice :TBCDField;
    FCurrency :TWideStringField;
  protected
    procedure ConnectFields; override;
  public
    property ISBN :TWideStringField read FISBN;
    property Title :TWideStringField read FTitle;
    property Authors :TWideStringField read FAuthors;
    property Price :TBCDField read FPrice;
    property Currency :TWideStringField read FCurrency;
    // this property should be hidden, but during migration can be usefull
    // property DataSet: TDataSet read FDataSet;
  end;

implementation

uses
  System.SysUtils;

procedure TBookProxy.ConnectFields;
const
  ExpectedFieldCount = 5;
begin
  FISBN := FDataSet.FieldByName('ISBN') as TWideStringField;
  FTitle := FDataSet.FieldByName('Title') as TWideStringField;
  FAuthors := FDataSet.FieldByName('Authors') as TWideStringField;
  FStatus := FDataSet.FieldByName('Status') as TWideStringField;
  FPrice := FDataSet.FieldByName('Price') as TBCDField;
  FCurrency := FDataSet.FieldByName('Currency') as TWideStringField;
  Assert(FDataSet.Fields.Count = ExpectedFieldCount);
end;

end.
```

### Step 2. Moving the behavior to the proxy (optional)

You can immediately replace the classic `TDataSet` with the generated object, but the recommended previous step is to transfer the domain code to the proxy object (behavior). Thanks to this step, you can write some simple unit tests from the very beginning - even using the TDD. Sample behavior for the book data:

```pas
function TBookProxy.ToString: String;
begin
  Result := Format('%s %s (%.2f %s)',[ISBN.Value,Title.Value,
    Price.Value,Currency.Value]);
end;

function TBookProxy.LocateISBN(const ISBN: string): boolean;
begin
  Result := FDataSet.Locate('ISBN',ISBN,[]);
end;

function TBookProxy.CountMoreExpensiveBooks: integer;
var
  CurrentPrice: Extended;
  Count: Integer;
begin
  Count := 0;
  CurrentPrice := Price.Value;
  self.ForEach(
    procedure
    begin
      if Self.Price.Value > CurrentPrice then
        Count := Count + 1;
    end);
  Result := Count;
end;
```

### Step 3. Create the proxy

```pas
uses
  Data.Proxy.Book;

type
  TDataModule1 = class(TDataModule)
    procedure TDataModule1.DataModuleCreate(Sender: TObject);
  public
    BookProxy: TBookProxy;
  end;

procedure TDataModule1.DataModuleCreate(Sender: TObject);
var
begin
  BookProxy := TDataProxyFactory.CreateProxy<TBookProxy>(Self,FDQueryBooks);
end;
```

### Step 4. Replace `TDataSet` with the proxy


```pas
procedure TForm1.Button1Click(Sender: TObject);
begin
  ListBox1.ItemIndex := -1;
  ListBox1.Clear;
   DataModule1.BookProxy.ForEach(
    procedure
    begin
      ListBox1.Items.Add(DataModule1.BookProxy.ToString);
    end);
end;
```

```pas
procedure TForm1.ListBox1Click(Sender: TObject);
begin
  if (ListBox1.ItemIndex >= 0) then
  begin
    DataModule1.BookProxy.LocateISBN(
      GetBookISBN_From_ListBoxCurrentItem(ListBox1) );
    Self.Caption := DataModule1.BookProxy.Title.Value;
  end;
end;
```

```pas
procedure TForm1.Button2Click(Sender: TObject);
begin
  Button2.Caption := Format('More expensive books = %d',
    [DataModule1.BookProxy.CountMoreExpensiveBooks]);
end;
```

### Step 5. Replace static DataSet with dynamic

```pas
// private method
function TDataModule1.CreateSQLDataSet_Book(AOwner: TComponent; 
  AConnection: TFDConnection): TDataSet;
var
  fdq: TFDQuery;
begin
  fdq := TFDQuery.Create(AOwner);
  with fdq do
  begin
    Connection := AConnection;
    SQL.Text := 'SELECT ISBN, Title, Authors, Status, ReleseDate,' +
      ' Pages, Price, Currency, Imported, Description FROM Books';
    Open;
  end;
  Result := fdq;
end;

procedure TDataModule1.DataModuleCreate(Sender: TObject);
var
begin
  BookProxy := TDataProxyFactory.CreateProxy<TBookProxy>(Self,
    CreateSQLDataSet_Book(Self, FDConnection1));
end;
```
## More proxy samples

1) Books sample
    1) see the setup documentation: [Samples README](./samples/README.md)
    1) `TDatasetProxy` class source code is in the `/samples/base` folder
    1) Generated proxy = `TBookProxy` in (`Data.Proxy.Book.pas` unit)
    1) Generated mock factory = `function CreateMockTableBook` in (`Data.Mock.Book.pas` unit)

[... more code - Gist sample (Data.Proxy.Book.pas)](https://gist.github.com/bogdanpolak/b13f0c5a677c3401734918dbfa7ae755)

```pas
unit Data.Mock.Book;

interface

uses
  System.Classes, System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client;

function CreateMemDataSet_Book(AOwner: TComponent): TDataSet;

implementation

function CreateMemDataSet_Book(AOwner: TComponent): TDataSet;
var
  ds: TFDMemTable;
begin
  ds := TFDMemTable.Create(AOwner);
  with ds do
  begin
    FieldDefs.Add('ISBN', ftWideString, 20);
    FieldDefs.Add('Title', ftWideString, 100);
    FieldDefs.Add('ReleseDate', ftDate);
    FieldDefs.Add('Pages', ftInteger);
    with FieldDefs.AddFieldDef do begin
      Name := 'Price';  DataType := ftBCD;  Precision := 12;  Size := 2;
    end;
    CreateDataSet;
  end;
  with ds do
  begin
    Append;
    FieldByName('ISBN').Value := '978-0131177055';
    FieldByName('Title').Value := 'Working Effectively with Legacy Code';
    FieldByName('ReleseDate').Value := EncodeDate(2004,10,1);
    FieldByName('Pages').Value := 464;
    FieldByName('Price').Value := 52.69;
    Post;
  end;
  // ... more rows appended here ...
  Result := ds;
end;
```
[... more code - Gist sample (Data.Mock.Book.pas)](https://gist.github.com/bogdanpolak/1622fcc3e4f1185fb4ead8263c9b8b31)

## Additional documentation

1. [Generator App for FireDAC - User Guide](doc/generator-app-guide.md)
