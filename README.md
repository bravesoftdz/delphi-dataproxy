﻿# DataProxy Pattern for Delphi

![ Delphi Support ](https://img.shields.io/badge/Delphi%20Support-%20XE8%20..%2010.3%20Rio-blue.svg)
![ version ](https://img.shields.io/badge/version-%200.9-yellow.svg)

-------------------------------------------------------------------
TBD in ver. 1.0 (plan)

1) Remove `TDataProxyFactory` use `TDataProxy.WithDataSet`

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

## Modernizing VCL projects in action

Replacing classic dataset with proxy requires some time to learn and validate in action. This approach could looks a little strange for Delphi developers, but is easy to adopt and learn. With management motivation and senior engineer coaching team will faster adopt code extraction and replacing datasets with proxies technique.

Defined here proxy approach is a simple and safe refactoring technique dedicated for classic VCL application builded in EDP (Event Driven Programming) way. Using this solution in evolution way small, but important parts of business code can be extracted and covered with unit tests. After some time, with a better safety net (unit tests coverage), engineers can swap proxies with OOP DAOs and improve code more using advanced refactorings and architectural patterns.

The modernization process includes following steps: 
1. Business code extraction
1. Proxy generation
1. Dataset replacement with the proxy
1. Unit test introduction
1. Decomposition (big methods into smaller once) with unit test coverage
1. New composable classes creation (unit tests)
1. Proxy retirement (to replace with DAO)

## More proxy samples

1) Books sample demo application
    1) see the setup documentation: [Samples README](./samples/README.md)
    1) Generated proxy = `TBookProxy` in (`Data.Proxy.Book.pas` unit)
    1) Generated mock factory = `function CreateMockTableBook` in (`Data.Mock.Book.pas` unit)

## Additional documentation

1. [Generator App for FireDAC - User Guide](doc/generator-app-guide.md)
