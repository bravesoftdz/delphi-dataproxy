﻿# DataProxy Pattern for Delphi

## Overview

TDataSetProxy is a wrapper component for the TDataSet component (Delphi). It allows to replace a data set component with a mock - memory table. Solution can be used to separate a business class from used by this class datasets during unit testing.

![](./doc/resources/datasetproxy-01.png)

**Inspiration**. Idea is based on Proxy GoF Pattern and Table Module Pattern (from: Martin Fowler - Patterns of Enterprise Application Architecture). 

## Generator Application

This project includes the source code of the Generator application which automatically creates Delphi source code based od sample SQL query (eg. SELECT statement). This application is based on FireDAC's data connections, but it's possible to extend support to other Delphi DAC components (eg. AnyDAC). 

![](./doc/resources/generator-app.png)

Main generator's goals are:
* Receive a SQL statement 
  * Connects to RDBMS database with `FireDAC`, paste, enter or edit a SQL statement
  * Checks a structure and data in the result data set
* Generate a proxy
  * Using a SQL statement structure creates a Delphi code with new DAO class based on the TProxyDataSet
* Generate a dataset mock `MemTable`
  * Creates a Delphi code which builds a `TFDMemTable` component with the same structure as the input dataset
  * Creates a Delphi code that clones data using the `Append` procedure

## Samples

Check `samples` subfolder

1) Books sample
    1) see the setup documentation: [Samples README](./samples/README.md)
    1) `TDatasetProxy` class source code is in the `/samples/base` folder
    1) Generated proxy = `TBookProxy` in (`Data.Proxy.Book.pas` unit)
    1) Generated mock factory = `function CreateMockTableBook` in (`Data.Mock.Book.pas` unit)

<script src="https://gist.github.com/bogdanpolak/b13f0c5a677c3401734918dbfa7ae755.js"></script>

<script src="https://gist.github.com/bogdanpolak/1622fcc3e4f1185fb4ead8263c9b8b31.js"></script>

## Documentation

1. [Proxy Generator User Guide](doc/generator-guide.md)
1. [Using TProxyDataSet in the project](doc/using-proxydataset.md)

## More

[TBD]
