unit Notion.Interfaces;

interface

uses
  System.Generics.Collections, System.JSON;

type
  INotionPage = interface
    ['{12345678-1234-1234-1234-1234567890AB}']
    function GetName: string;
    function GetID: string;
    function GetReferenceID: string;
    function GetBackReferenceList: TObjectDictionary<String, INotionPage>;

    property Name: string read GetName;
    property ID: string read GetID;
    property Reffers: string read GetReferenceID;
    property BackReference: TObjectDictionary<String, INotionPage> read GetBackReferenceList;
    function ToString: String;
    function ToJSON: TJSONObject;
  end;


  INotionPagesCollection = interface
    ['{12345678-2345-2345-2345-1234567890AB}']
    function GetName: string;
    procedure SetName(name: String);
    function GetPages: TObjectDictionary<String, INotionPage>;
    function GetQuerySize: Integer;
    procedure SetQuerySize(querySize: Integer);
    function GetDBID: String;
    procedure SetDBID(id: String);
    function GetIsObserver: Boolean;
    function LoadPages(pagesJSON: TJSONObject): boolean;
    function FetchPages: boolean;
    procedure Initialize;
    function PageById(id: string): INotionPage;
    function ToJSON: TJSONObject;
    function ToString: string;

    // Observer notification
    procedure UpdateReferences;

    property Name: String read GetName write SetName;
    property Pages: TObjectDictionary<String, INotionPage> read GetPages;
    property QuerySize: Integer read GetQuerySize write SetQuerySize;
    property DbID: String read GetDBID write SetDBID;
    property IsObserver: Boolean read GetIsObserver;
  end;

  INotionRESTClient = interface
    ['{12345678-3456-3456-3456-1234567890AB}']
    function Search(strSearch: string; LimitTo: integer=0): TJSONObject;
    function DOPost(const Resource: string; Body: string): TJSONObject;
    function DOGet(const Resource: string; Body: string): TJSONObject;
    function DOPatch(const Resource: string; Body: string): TJSONObject;
    function Clone(postFix: string): INotionRESTClient;
  end;


  INotionManager = interface
    ['{12345678-4567-4567-4567-1234567890AB}']
    procedure LogMessage(const Msg: string);
    function Search(strSearch: String; const pageSize: Integer=0): INotionPagesCollection;
    function FabricateNotionPage(pageType: String; obj: TJSONObject): INotionPage;
    function LoadDataSets: Integer;
    procedure DoWhatYouHaveToDo;

    // getters
    function GetNotionClient: INotionRESTClient;
    function GetIsThreaded: Boolean;
    function GetDataSets: TObjectDictionary<String, INotionPagesCollection>;
    function GetPagesIndex: TObjectDictionary<String, INotionPage>;
    function GetPublicName: String;

    // Observer related
    procedure AttachObserver(Observer: INotionPagesCollection);
    procedure DetachObserver(Observer: INotionPagesCollection);
    procedure NotifyObservers;

    // properties
    property PublicName: String read GetPublicName;
    property Client: INotionRESTClient read GetNotionClient;
    property IsThreaded: Boolean read GetIsThreaded;
    property DataSets: TObjectDictionary<String, INotionPagesCollection> read GetDataSets;
    property PagesIndex: TObjectDictionary<String, INotionPage> read GetPagesIndex;
  end;


const
  Notion_Generic_DataSet = 'Generic';

implementation

end.
