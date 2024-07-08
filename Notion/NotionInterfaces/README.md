# git


NotionInterfaces

 defines and implements the interfaces and base classes:

  INotionPage = interface
  INotionPagesCollection = interface
  INotionRESTClient = interface
  INotionManager = interface


  TNotionPage
  TNotionPagesCollection
  TNotionDataSet
  TNotionRESTClient
  TLogger
  TNotionManager
  TNotionDataSetFactory
Several types above contain virtual abstract methods, forcing implementation in descendants.

also threading support via

TNotionDatasetFetchInfoThread
TNotionDatasetFetchPagesThread