unit AmSystemItems;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  Dialogs, SyncObjs, Winapi.WinSock, IOUtils, math,
  System.Generics.Collections,
  ShellApi, System.WideStrUtils,
  AmSystemBase, AmSystemObject,
  AmInterfaceBase, AmSystemListBase;

type

  TAmItemObject = class;
  TAmItemClass = class of TAmItemObject;


  // lcChangeCustom  любое другое изменение листа
  // lcChangeItem  изменение в самом одном итеме
  TAmItemsEnum = (lcInvalid, lcChangeCustom, lcChangeItem,
    lcClassItem, lcChildItemAdding, lcChildItemAdd, lcChildItemRemoving,
    lcChildItemRemoved, lcSetCountB, lcSetCount, lcUpdate, lcClearB, lcClear,
    lcDeleteB, lcDelete, lcExtractB, lcExtract, lcExchangeB, lcExchange,
    lcInsertB, lcInsert, lcMoveB, lcMove, lcPutB, lcPut, lcAssignB, lcAssign);

  PAmItemsPrm = ^TAmItemsPrm;

  TAmItemsPrm = record
  var
    Enum: TAmItemsEnum;
    procedure Clear;
    case TAmItemsEnum of
      lcInvalid, lcClearB, lcClear, lcChangeCustom: ();
      lcSetCount, lcSetCountB: (CountOld, CountNew: integer);
      lcChildItemAdding, lcChildItemAdd, lcChildItemRemoving, lcChildItemRemoved:(ItemChild: TObject);
      lcChangeItem:(Operation, W, L: integer; Item: TObject);
      lcClassItem:(AClass: TAmItemClass);
      lcUpdate:(Updating: boolean);
      lcDeleteB, lcDelete, lcExtractB, lcExtract:(Index: integer);
      lcInsertB, lcInsert, lcPutB, lcPut: (IndexVar: integer; PVar: PPointer { Pinterface } );
      lcExchangeB, lcExchange, lcMoveB, lcMove: (Index1 { cur } , Index2 { new } : integer);
    // lcAssignB,lcAssign: (Source:IAmListEmulObject);
  end;

  IAmListItemOwner = interface;
  IAmListItemOwnerPointer = Pointer; // = IAmListItemOwner

  IAmItem = interface(IAmBase)
    ['{1E5C41F9-031B-4690-878B-0B002B5D8470}']
    // private
    function ListGet: IAmListItemOwner;
    procedure ListSet(const Value: IAmListItemOwner);
    function ItemIdGet: Cardinal;
    procedure ItemIdSet(const Value: Cardinal);
    function ItemIndexFieldGet: integer;
    procedure ItemIndexFieldSet(const Value: integer);
    function ItemIndexGet: integer;
    procedure ItemIndexSet(const Value: integer);
    function ItemIndivGet: integer;
    procedure ItemIndivSet(const Value: integer);
    // protected
    function CanChangedList(Now: IAmListItemOwner;
      var New: IAmListItemOwner): boolean;
    procedure Changed(Operation, W, L: integer);
    function Broadcast(Operation, W, L: integer): integer;
    procedure Loaded;
    // событие после загрузки с ресурса формы вызовется у компонента а сюда лист передаст
    // public
    // Release используется для List:=nil или Tobject.Free что именно  решается в самом объекте
    // если рещаете что в вашем объекте надо  Tobject.Free
    // то при вызове Item.Release
    // саму переменную указать как [unsafe] или [weak]
    // var [unsafe] Item:IAmItem;
    // begin
    // ....
    // Item.Release;
    // если в вашем коде полно переменных IAmItem
    // и при удалении выдает ошибку типа не все ссылки удалены то поставьте на переменные  [weak]
    // 2й спопособ принудительного удаления объекта интерфейса через FreeOnRelease or AmIntfFree(Item);
    procedure Release;
    procedure FreeOnRelease(var AInterface);
    property List: IAmListItemOwner read ListGet write ListSet;
    property ItemId: Cardinal read ItemIdGet write ItemIdSet;
    property ItemIndex: integer read ItemIndexGet write ItemIndexSet;
    property ItemIndiv: integer read ItemIndivGet write ItemIndivSet;

    // help  можно вернуть все 0
    function AsPers: TPersistent;
    // если нужно что бы сохранялось и загружалось на автомате то вернуть что то
    function AsRef(Value: Cardinal): Cardinal;
    // произвольное получение чего то с объекта
  end;

  // интерфейс списка для внешнего использования
  IAmListItem = interface(IAmListBase<IAmItem>)
    ['{04813327-BCE6-43C8-A301-1ABD9E050C6B}']
    function EmulListOwner: IAmListItemOwner;
    function IndexOfId(AId: Cardinal): integer;
    function ItemsChangedBroadcast(Operation, W, L: integer): integer;
  end;

  // внутрениий интерфейс списка внешне не использать
  // разве что можно вызывать GetList
  IAmListItemOwner = interface(IAmListEmulEx<IAmItem>)
    ['{FE613C18-56F1-4DBA-B4EF-F304A1582EC5}']
    function GetList: IAmListItem;
    function EmulAdd(Item: IAmItem): integer;
    function EmulRemove(Item: IAmItem): integer;
    function EmulGetNextId: Cardinal;
    procedure EmulChangeItem(Item: IAmItem; Operation, W, L: integer);
  end;

  // события которые происходят в Item
  // можно унаследоватся что бы расщирить своими
  AmItemOperation = class
  const
    IndexChange = 1;
    IndexSet = 2; // w =old  l = new
    ChangeListAfter = 3;
    ChangeListBefore = 4;
    IndivSet = 5;
    Loaded = 6;
  end;

  // для упрощенного создания объекта с интерфесом IAmItem
  // можно тупо скопировать код с TAmItemObject или  TAmItemPersInf
  AmItemHelp = class
  private
    class procedure IndexCurrentSetter(Item: IAmItem);
  public
    // IAmItem
    class procedure ItemListRelease(Item: IAmItem);
    class procedure ItemDestroy(var Item: IAmItem);
    class function ListSet(Item: IAmItem; var Field: IAmListItemOwnerPointer;
      NewValue: IAmListItemOwner): boolean;
    class function IndexGet(Item: IAmItem): integer;
    class procedure IndexSet(Item: IAmItem; const Value: integer);
    class procedure Changed(Item: IAmItem; Operation, W, L: integer);

    class function GetComponentOwner(Item: IAmItem): TComponent;
    class function GetControlParent(Item: IAmItem): TWinControl;
    class function GetSelfPers(Item: IAmItem): TPersistent;
    class function GetSelfObj(Item: IAmItem): TObject;
  end;

  // ниже разные IAmItem для разных целей
  // разница меж ними что они унаследованы от разных классов
  // которые имеют разный функциолал управления подсчета ссылок
  TAmItemObject = class(TAmInterfacedObject, IAmItem)
  private
    FId: Cardinal;
    FIndex: integer;
    FIndiv: integer;
    FList: IAmListItemOwnerPointer;

    // IAmItem
    function IAmItem.ListGet = iListGet;
    procedure IAmItem.ListSet = iListSet;
    function IAmItem.ItemIdGet = iItemIdGet;
    procedure IAmItem.ItemIdSet = iItemIdSet;
    function IAmItem.ItemIndexFieldGet = iItemIndexFieldGet;
    procedure IAmItem.ItemIndexFieldSet = iItemIndexFieldSet;
    function IAmItem.ItemIndexGet = iItemIndexGet;
    procedure IAmItem.ItemIndexSet = iItemIndexSet;
    function IAmItem.ItemIndivGet = iItemIndivGet;
    procedure IAmItem.ItemIndivSet = iItemIndivSet;
    procedure IAmItem.Loaded = iLoaded;
    procedure IAmItem.Changed = ItemChanged;
    function IAmItem.AsPers = iAsPers;
    function IAmItem.AsRef = iAsRef;
    function IAmItem.Broadcast = ItemBroadcast;
    function IAmItem.CanChangedList = ItemCanChangedList;

    function iListGet: IAmListItemOwner;
    procedure iListSet(const Value: IAmListItemOwner);
    function iItemIdGet: Cardinal;
    procedure iItemIdSet(const Value: Cardinal);
    function iItemIndexFieldGet: integer;
    procedure iItemIndexFieldSet(const Value: integer);
    function iItemIndexGet: integer;
    procedure iItemIndexSet(const Value: integer);
    function iItemIndivGet: integer;
    procedure iItemIndivSet(const Value: integer);
    procedure iLoaded;
    function AsObj: TObject;
    procedure FreeOnRelease(var AInterface);
  protected
    function iAsPers: TPersistent; dynamic;
    function iAsRef(Value: Cardinal): Cardinal; dynamic;
    // IAmItem используется когда что то в объекте поменялось
    procedure ItemChanged(Operation, W, L: integer); virtual;
    function ItemCanChangedList(Now: IAmListItemOwner;
      var New: IAmListItemOwner): boolean; virtual;
    function ItemBroadcast(Operation, W, L: integer): integer; virtual;
  public
    constructor Create(AListOwner: IAmListItemOwner); virtual;
    destructor Destroy; override;
    procedure Release; override;
    property ItemId: Cardinal read iItemIdGet;
    property List: IAmListItemOwner read iListGet write iListSet;
    property Index: integer read iItemIndexGet write iItemIndexSet;
    property Indiv: integer read iItemIndivGet write iItemIndivSet;
  end;

  TAmItemPersInf = class(TAmPersInf, IAmItem)
  private
    FId: Cardinal;
    FIndex: integer;
    FIndiv: integer;
    FList: IAmListItemOwnerPointer;

    // IAmItem
    function IAmItem.ListGet = iListGet;
    procedure IAmItem.ListSet = iListSet;
    function IAmItem.ItemIdGet = iItemIdGet;
    procedure IAmItem.ItemIdSet = iItemIdSet;
    function IAmItem.ItemIndexFieldGet = iItemIndexFieldGet;
    procedure IAmItem.ItemIndexFieldSet = iItemIndexFieldSet;
    function IAmItem.ItemIndexGet = iItemIndexGet;
    procedure IAmItem.ItemIndexSet = iItemIndexSet;
    function IAmItem.ItemIndivGet = iItemIndivGet;
    procedure IAmItem.ItemIndivSet = iItemIndivSet;
    procedure IAmItem.Changed = ItemChanged;
    procedure IAmItem.Loaded = iLoaded;
    function IAmItem.AsRef = iAsRef;
    function IAmItem.Broadcast = ItemBroadcast;
    function IAmItem.CanChangedList = ItemCanChangedList;

    function iListGet: IAmListItemOwner;
    procedure iListSet(const Value: IAmListItemOwner);
    function iItemIdGet: Cardinal;
    procedure iItemIdSet(const Value: Cardinal);
    function iItemIndexFieldGet: integer;
    procedure iItemIndexFieldSet(const Value: integer);
    function iItemIndexGet: integer;
    procedure iItemIndexSet(const Value: integer);
    function iItemIndivGet: integer;
    procedure iItemIndivSet(const Value: integer);
    procedure iLoaded;
    function AsPers: TPersistent;
    function AsObj: TObject;
  protected

    function iAsRef(Value: Cardinal): Cardinal; dynamic;
    // IAmItem используется когда что то в объекте поменялось
    procedure ItemChanged(Operation, W, L: integer); virtual;
    function ItemCanChangedList(Now: IAmListItemOwner;
      var New: IAmListItemOwner): boolean; virtual;
    function ItemBroadcast(Operation, W, L: integer): integer; virtual;
  public
    constructor Create(AListOwner: IAmListItemOwner); virtual;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure Release; override;
    property ItemId: Cardinal read iItemIdGet;
    property List: IAmListItemOwner read iListGet write iListSet;
    property Index: integer read iItemIndexGet write iItemIndexSet;
    procedure IndexSetTry(AIndex: integer);
    function IndexGetTry(AIndex: integer): integer;
    property IndexTry: integer read iItemIndexGet write IndexSetTry stored False;
  published
    property Indiv: integer read iItemIndivGet write iItemIndivSet;
  end;

  TAmItemComponent = class(TAmComponent, IAmItem)
  private
    FId: Cardinal;
    FIndex: integer;
    FIndiv: integer;
    FList: IAmListItemOwnerPointer;

    // IAmItem
    function IAmItem.ListGet = iListGet;
    procedure IAmItem.ListSet = iListSet;
    function IAmItem.ItemIdGet = iItemIdGet;
    procedure IAmItem.ItemIdSet = iItemIdSet;
    function IAmItem.ItemIndexFieldGet = iItemIndexFieldGet;
    procedure IAmItem.ItemIndexFieldSet = iItemIndexFieldSet;
    function IAmItem.ItemIndexGet = iItemIndexGet;
    procedure IAmItem.ItemIndexSet = iItemIndexSet;
    function IAmItem.ItemIndivGet = iItemIndivGet;
    procedure IAmItem.ItemIndivSet = iItemIndivSet;
    procedure IAmItem.Changed = ItemChanged;
    procedure IAmItem.Loaded = iLoaded;
    function IAmItem.AsPers = iAsPers;
    function IAmItem.AsObj = iAsObj;
    function IAmItem.AsRef = iAsRef;
    function IAmItem.Broadcast = ItemBroadcast;
    function IAmItem.CanChangedList = ItemCanChangedList;

    function iListGet: IAmListItemOwner;
    procedure iListSet(const Value: IAmListItemOwner);
    function iItemIdGet: Cardinal;
    procedure iItemIdSet(const Value: Cardinal);
    function iItemIndexFieldGet: integer;
    procedure iItemIndexFieldSet(const Value: integer);
    function iItemIndexGet: integer;
    procedure iItemIndexSet(const Value: integer);
    function iItemIndivGet: integer;
    procedure iItemIndivSet(const Value: integer);
    procedure iLoaded;
  protected
    function iAsPers: TPersistent; dynamic;
    function iAsObj: TObject; dynamic;
    function iAsRef(Value: Cardinal): Cardinal; dynamic;

    // IAmItem используется когда что то в объекте поменялось
    procedure ItemChanged(Operation, W, L: integer); virtual;
    function ItemCanChangedList(Now: IAmListItemOwner;
      var New: IAmListItemOwner): boolean; virtual;
    function ItemBroadcast(Operation, W, L: integer): integer; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Release; virtual;
    procedure FreeOnRelease(var AInterface);
    property ItemId: Cardinal read iItemIdGet;
    property List: IAmListItemOwner read iListGet write iListSet;
    property Index: integer read iItemIndexGet write iItemIndexSet;
  published
    property Indiv: integer read iItemIndivGet write iItemIndivSet;
  end;



  // Универсальный лист для разных пронумерованных объектов
  // 1. имеет события на каждое действие
  // 2. может хранит все что угодно унаследованное от  IAmItem
  // IAmItem просто создается в любом классе можно посмотреть пример TAmItemPersInf
  // выше есть часто используемые классы которые можно ложить в  TAmListItem
  // 4. Если не пользуетесь интерфейсом листа IAmListItem то используйте  TAmListItemObj, иначе  TAmListItemInf
  // 5. TAmListItemObj удаляется только через TObject.Free;
  // 6. TAmListItemInf через кол-во ссылок interface(TAmListItemInf) =nil
  // 7. в листе не может быть дубликатов
  // 8. лист напрямую не удаляет свои итемы а вызывает IAmItem.ListRelease,  а там уже выполняется действие free например или List :=nil

  TAmListItemCustom = class abstract(TAmListBaseInterfaced<IAmItem>,
    IAmListItem, IAmListItemOwner)
  type
    TEventCreate = procedure(var NewItem: IAmItem) of object;
  private
    FList: TList<IAmItem>;
    FIdCounter: Cardinal;
    FIsNeedEvent: boolean;
    FEventCreate: TEventCreate;
    FLockChange: integer;

    // IAmListItemOwner
    function EmulGetNextId: Cardinal;
    function EmulAdd(Item: IAmItem): integer;
    function EmulRemove(Item: IAmItem): integer;
    function EmulIndexOf(Value: IAmItem): integer;
    function EmulGetCount: integer;
    function EmulGet(Index: integer): IAmItem;
    function EmulHas(Index: integer): boolean;
    procedure EmulMove(CurIndex, NewIndex: integer);
    function EmulListOwner: IAmListItemOwner;
    procedure EmulChangeItem(Item: IAmItem; Operation, W, L: integer);
    function IAmListItemOwner.GetList = EmulGetList;
    function EmulGetList: IAmListItem;

    procedure InternalItemCreate(var NewItem: IAmItem);
    procedure InternalInsert(Index: integer; const Item: IAmItem);
    procedure InternalPut(Index: integer; const Item: IAmItem);
    procedure InternalDelete(Index: integer);
    function InternalExtract(Index: integer): IAmItem;
    procedure InternalClear;

    procedure ChangeLock;
    procedure ChangeUnLock;

  protected
    procedure Changed(Prm: PAmItemsPrm); virtual;
    procedure DoChanged(Prm: PAmItemsPrm); virtual;
    function ItemsChangedBroadcast(Operation, W, L: integer): integer; virtual;

    // IAmListBase
    function Get(Index: integer): IAmItem; override;
    function GetCount: integer; override;
    procedure Put(Index: integer; Item: IAmItem); override;
    procedure SetCount(NewCount: integer); override;
    function UpdateCountGet: integer; override;

    procedure DoUpdate; override;
    procedure ItemCreate(var NewItem: IAmItem); virtual;
  public
    constructor Create();
    destructor Destroy; override;
    property IsNeedEvent: boolean read FIsNeedEvent write FIsNeedEvent;
    procedure BeforeDestruction; override;
    function IsMyChildObject(ACheckObject: TObject): boolean; override;
    function SupObjToItem(Obj: TObject; IsError: boolean = true): IAmItem; virtual;
    procedure Clear; override;
    function Has(Index: integer): boolean;
    procedure Delete(Index: integer); override;
    function Extract(Index: integer): IAmItem; virtual;
    procedure Exchange(Index1, Index2: integer); override;
    procedure Move(CurIndex, NewIndex: integer); override;
    procedure Insert(Index: integer; Item: IAmItem); override;
    function InsertNew(Index: integer): IAmItem; override;
    function IndexOf(Item: IAmItem): integer; override;
    function IndexOfId(AId: Cardinal): integer;
    function Add(Item: IAmItem): integer; override;
    function AddNew: IAmItem; override;
    function NewItem: IAmItem; virtual;
    function Remove(ItemRemove: IAmItem): integer; override;
    procedure UpdateBegin; override;
    procedure UpdateEnd; override;
    property Count: integer read GetCount write SetCount;
    property Items[Index: integer]: IAmItem read Get write Put; default;
    procedure ItemsUnsafe(Index: integer; var [unsafe] Result: IAmItem); override;
    property UpdateCount: integer read UpdateCountGet;
    // в событии нужно создать один элемент
    property OnItemCreate: TEventCreate read FEventCreate write FEventCreate;
  end;

  // если нужно что бы при удалении объекта не проверялось кол-во ссылок на интерфейс
  // т.е когда основная ссылка на объект это  TAmListItemObj
  // тогда (т.е его надо удалять явно через free)
  TAmListItemObj = class(TAmListItemCustom)
  private
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  // иначе  (этот сам удалится )
  TAmListItemInf = class(TAmListItemCustom)
  end;

  // TAmListItemPers его надо удалять явно через free
  // имеет способность сохранять в файл формы все итемы если они TPersistent и выше
  // что бы выполнялось сох и загрузка запустить в root компонете когда у него вызывается DefineProperties

  TAmListItemPers = class(TAmListItemObj) // IAmListColection
  private type
    TLocWriter = class(TWriter);
    TLocReader = class(TReader);
  protected
    procedure ReadDataBefore(); virtual;
    procedure ReadDataAfter(); virtual;
    procedure ReadData(Reader: TReader); virtual;
    procedure WriteDataBefore(); virtual;
    procedure WriteDataAfter(); virtual;
    procedure WriteData(Writer: TWriter); virtual;
    function CanWriteItem(Item: IAmItem): boolean; virtual;
    // когда   IAmItem не TPersistent то сохр самому и вернуть было ли сохранено   если верунть false то сохранится или загрузится nil
    function WriteInvalidClass(Index: integer; Item: IAmItem; Writer: TWriter): boolean; virtual;
    function ReadCreateItem(AClassName: string; AClass: TClass): IAmItem; virtual;
    procedure ReadInvalidClass(Item: IAmItem; Reader: TReader); virtual;

  public
    procedure Loaded; virtual; // запустить в root при  TComponent.Loaded
    procedure DefineProperties(СonsequenceNameProperty: string; Filer: TFiler); virtual; // запустить в root при  TComponent.DefineProperties
    function WriteSignatureOneItem(Item: IAmItem): string; virtual;
    function ReadSignatureOneItem(Input: string): IAmItem; virtual;
  end;


  // TAmListItemColection также поддерживает интерфейс IAmListColection для управления итемами в режиме разработки
  // IAmListColection  если not  item[index] is TPersistent  то вернет nil
  // а добавлять можно любые итемы  IAmItem
  // если добавить TPersistent который не поддерживает IAmItem будет ошибка
  // удалять явно через Free;

  TAmListItemColection = class(TAmListItemPers, IAmListColection)
  private
    FPersDesingNotify: TAmPersDesingNotifyHelp;
    procedure PersDesingNotifyGetOwner(Sender: TObject;
      var AOwner: TPersistent);

    // IAmListColection
    function IAmListColection.Get = wcGet;
    procedure IAmListColection.Put = wcPut;
    function IAmListColection.IndexOf = wcIndexOf;
    function IAmListColection.Remove = wcRemove;
    function IAmListColection.Add = wcAdd;
    function IAmListColection.AddNew = wcAddNew;
    procedure IAmListColection.Insert = wcInsert;
    function IAmListColection.InsertNew = wcInsertNew;
    function wcGet(Index: integer): TPersistent;
    procedure ItemsUnsafe(Index: integer; var [unsafe] Result: TPersistent);
    procedure wcPut(Index: integer; Item: TPersistent);
    function wcIndexOf(Item: TPersistent): integer;
    function wcAdd(Item: TPersistent): integer;
    function wcAddNew: TPersistent;
    procedure wcInsert(Index: integer; Item: TPersistent);
    function wcInsertNew(Index: integer): TPersistent;
    function wcRemove(Item: TPersistent): integer;
    function AsPersDesingNotify: TPersistent;

  protected
    procedure Changed(Prm: PAmItemsPrm); override;
    procedure DoChanged(Prm: PAmItemsPrm); override;

    // IAmListColection
    // в наследниках перекрыть
    function GetComponentRoot: TComponent; virtual;
    function GetOwner: TPersistent; virtual;
  public
    constructor Create;
    Destructor Destroy; override;
    function IsMyChildObject(ACheckObject: TObject): boolean; override;
  end;





  /// ///////////////////////////////////////////////////////////////////////////
  ///
  ///                               Grid
  ///
  /// ///////////////////////////////////////////////////////////////////////////
  IAmGridLine = interface;
  IAmGrid = interface;

  IAmGridBase = interface(IAmBase)
    ['{0B6469AB-8436-4B8B-AD85-0EC14370AD5D}']
    // вернуть self объект или же см IAmListColection и TAmPersDesingNotifyHelp
    function AsPersDesingNotify: TPersistent;
    function AsItem: IAmItem;
    function IdGet: Cardinal;
    function RectClientGet: TRect;
    property Id: Cardinal read IdGet;
    procedure Release;
    property RectClient: TRect read RectClientGet;

  end;

  IAmGridItem = interface(IAmGridBase)
    ['{12E78FF8-0EDE-4FFC-B8FF-EAB8E2A98934}']
    function IndexLineGet: integer;
    procedure IndexLineSet(const Value: integer);
    function IndexItemGet: integer;
    procedure IndexItemSet(const Value: integer);
    function ControlGet: TControl;
    procedure ControlSet(const Value: TControl);
    function WidthGet: integer;
    procedure WidthSet(const Value: integer);
    function HeightGet: integer;
    procedure HeightSet(const Value: integer);
    function TextGet: string;
    procedure TextSet(const Value: string);
    function ParentLineGet: IAmGridLine;

    property IndexLine: integer read IndexLineGet write IndexLineSet;
    property IndexItem: integer read IndexItemGet write IndexItemSet;
    property Control: TControl read ControlGet write ControlSet;
    property Width: integer read WidthGet write WidthSet;
    property Height: integer read HeightGet write HeightSet;
    property Text: string read TextGet write TextSet;

    property ParentLine: IAmGridLine read ParentLineGet;
  end;

  IAmGridLine = interface(IAmGridBase)
    ['{FD63AFC9-52CC-4294-B4EB-7536F8B8E6A0}']
    function IndexLineGet: integer;
    procedure IndexLineSet(const Value: integer);
    function WidthGet: integer;
    procedure WidthSet(const Value: integer);
    function HeightGet: integer;
    procedure HeightSet(const Value: integer);
    function PaddingGet: integer;
    procedure PaddingSet(const Value: integer);
    function CountGet: integer;
    procedure CountSet(const Value: integer);
    function ItemsGet(Index: integer): IAmGridItem;
    function ParentGridGet: IAmGrid;

    procedure Delete(AIndexItem: integer);
    procedure Clear;
    function Insert(AIndexItem: integer): IAmGridItem;
    function Add(): IAmGridItem;
    property Width: integer read WidthGet write WidthSet;
    property Height: integer read HeightGet write HeightSet;
    property Padding: integer read PaddingGet write PaddingSet;
    property Count: integer read CountGet write CountSet;
    property Items[index: integer]: IAmGridItem read ItemsGet;
    property IndexLine: integer read IndexLineGet write IndexLineSet;
    function ItemIndexOfId(AId: Cardinal): integer;
    function ItemIndexOf(AItem: IAmGridItem): integer;
    property ParentGrid: IAmGrid read ParentGridGet;
  end;

  IAmGrid = interface(IAmGridBase)
    ['{3958300C-5292-44A9-BC63-8E634F56F5EA}']
    function CellGet(AIndexLine, AIndexItem: integer): IAmGridItem;
    function CountItemGet(AIndexLine: integer): integer;
    procedure CountItemSet(AIndexLine: integer; const Value: integer);
    function CountLineGet: integer;
    procedure CountLineSet(const Value: integer);
    function LineGet(AIndexLine: integer): IAmGridLine;
    function ParentControlGet: TWinControl;

    procedure Update;
    property Cell[AIndexLine, AIndexItem: integer]: IAmGridItem read CellGet;
    property CountItem[AIndexLine: integer]: integer read CountItemGet
      write CountItemSet;
    property CountLine: integer read CountLineGet write CountLineSet;
    procedure Delete(AIndexLine, AIndexItem: integer);
    procedure Clear;
    function Insert(AIndexLine, AIndexItem: integer): IAmGridItem;
    function Add(AIndexLine: integer): IAmGridItem;

    property Line[AIndexLine: integer]: IAmGridLine read LineGet;
    function LineAdd: IAmGridLine;
    function LineInsert(ARow: integer): IAmGridLine;
    procedure LineDelete(AIndexLine: integer);
    function LineIndexOfId(AId: Cardinal): integer;
    function LineIndexOf(ALine: IAmGridLine): integer;
    property ParentControl: TWinControl read ParentControlGet;

  end;

implementation

resourcestring
  Rs_TAmItemPersInf_BeforeDestruction =
    'Error TAmItemPersInf.BeforeDestruction  не удалены все ссылки на интерфейс [ "%s" : Лишних ссылок = "%s"]';
  Rs_TAmListItemCustom_SupObjToItem =
    'Error TAmListItemCustom.SupObjToItem объект ["%s"] не поддерживает interface IAmItem';
  Rs_TAmListItemCustom_EmulAdd1 = 'Error TAmListItemCustom.EmulAdd Item = nil';
  Rs_TAmListItemCustom_EmulAdd2 =
    'Error TAmListItemCustom.EmulAdd Item.List <> IAmListItemOwner(self)';
  Rs_TAmListItemCustom_EmulRemove =
    'Error TAmListItemCustom.EmulRemove Item = nil';
  Rs_TAmListItemCustom_DublicateItem =
    'Error TAmListItemCustom.%s  IAmItem уже находится в этом листе выполните move exchange или listSet(nil) прежде чем вызывать %s';

type
  TLocTPersistent = class(TPersistent);

class procedure AmItemHelp.ItemListRelease(Item: IAmItem);
begin
  if Item <> nil then
    Item.List := nil;
end;

class procedure AmItemHelp.ItemDestroy(var Item: IAmItem);
begin
  TAmObject.FreeInterfaceClass(Item);
end;

class function AmItemHelp.ListSet(Item: IAmItem; var Field: IAmListItemOwnerPointer; NewValue: IAmListItemOwner): boolean;
var
  AId: Cardinal;
  AFieldList: IAmListItemOwner;
begin

  AFieldList := IAmListItemOwner(AmAtomic.Getter(Field));

  Result := (Item <> nil)
  and (AFieldList <> NewValue)
  and Item.CanChangedList(AFieldList, NewValue);

  Result := Result and (AFieldList <> NewValue);
  if not Result then
    exit;

  Item.Changed(AmItemOperation.ChangeListBefore, 0, LPARAM(NewValue));
  try
    if AFieldList <> nil then
      AFieldList.EmulRemove(Item);

    AmAtomic.Setter(Field, Pointer(NewValue));

    if NewValue <> nil then
    begin
      AId := NewValue.EmulGetNextId;
      Item.ItemId := AId;
      Item.ItemIndexFieldSet(NewValue.EmulAdd(Item));
      if Item.ItemId <> AId then
        AmRaiseBase.__Program
          ('Error  AmItemHelp.ListSet 2 Не верная логика вашего класса при установке List Item.ItemId <> AId');
    end
    else
    begin
      Item.ItemIndexFieldSet(-1);
      Item.ItemId := 0;
    end;

    if IAmListItemOwner(AmAtomic.Getter(Field)) <> NewValue then
      AmRaiseBase.__Program
        ('Error  AmItemHelp.ListSet Не верная логика вашего класса при установке List Field<>NewValue');

  finally
    Item.Changed(AmItemOperation.ChangeListAfter, 0, 0);
  end;
end;

class procedure AmItemHelp.IndexCurrentSetter(Item: IAmItem);
var
  L: IAmListItemOwner;
  Index: integer;
begin
  L := Item.List;
  index := Item.ItemIndexFieldGet;
  if Assigned(L) and (index >= 0) and (index < L.EmulGetCount) and
    (L.EmulGet(index) = Item) then
  begin
    // нечего делать
  end
  else if Assigned(L) then
  begin
    Item.ItemIndexFieldSet(L.EmulIndexOf(Item));
    index := Item.ItemIndexFieldGet;
    if (index >= 0) and (index < L.EmulGetCount) then
    begin
      // нечего делать
    end
    else
      Item.ItemIndexFieldSet(-1);
  end
  else
    Item.ItemIndexFieldSet(-1);
end;

class procedure AmItemHelp.Changed(Item: IAmItem; Operation, W, L: integer);
begin
  if Item.List <> nil then
    Item.List.EmulChangeItem(Item, Operation, W, L);
end;

class function AmItemHelp.IndexGet(Item: IAmItem): integer;
begin
  IndexCurrentSetter(Item);
  Result := Item.ItemIndexFieldGet;
end;

class procedure AmItemHelp.IndexSet(Item: IAmItem; const Value: integer);
var
  Index: integer;
  L: IAmListItemOwner;
begin
  L := Item.List;
  if Assigned(L) then
  begin
    IndexCurrentSetter(Item);
    Index := Item.ItemIndexFieldGet;
    if (Index >= 0) and (Index <> Value) then
      L.EmulMove(Index, Value);
  end
  else
    Item.ItemIndexFieldSet(-1);
end;

class function AmItemHelp.GetComponentOwner(Item: IAmItem): TComponent;
var
  P: TPersistent;
begin
  Result := nil;
  P := GetSelfPers(Item);
  while (Result = nil) and (P <> nil) do
  begin
    if P is TControl then
      P := TControl(P).Parent
    else if P is TComponent then
      P := TComponent(P).Owner
    else
      P := TLocTPersistent(P).GetOwner;

    if (P <> nil) and (P is TComponent) then
      Result := TComponent(P);
  end;
end;

class function AmItemHelp.GetControlParent(Item: IAmItem): TWinControl;
var
  P: TPersistent;
begin
  Result := nil;
  P := GetSelfPers(Item);
  while (Result = nil) and (P <> nil) do
  begin
    if P is TControl then
      P := TControl(P).Parent
    else if P is TComponent then
      P := TComponent(P).Owner
    else
      P := TLocTPersistent(P).GetOwner;

    if (P <> nil) and (P is TWinControl) then
      Result := TWinControl(P);
  end;
end;

class function AmItemHelp.GetSelfObj(Item: IAmItem): TObject;
begin
  Result := Item as TObject;
end;

class function AmItemHelp.GetSelfPers(Item: IAmItem): TPersistent;
begin
  if (Item <> nil) and (TObject(Item) is TPersistent) then
    Result := TPersistent(Item)
  else
    Result := nil;
end;

{ TAmItemComponent }
constructor TAmItemComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  iItemIdSet(0);
  FList := nil;
  FIndex := -1;
  FIndiv := 0;
end;

destructor TAmItemComponent.Destroy;
begin
  AmItemHelp.ItemListRelease(self);
  inherited;
end;

function TAmItemComponent.ItemCanChangedList(Now: IAmListItemOwner;
  var New: IAmListItemOwner): boolean;
begin
  Result := true;
end;

procedure TAmItemComponent.ItemChanged(Operation, W, L: integer);
begin
  AmItemHelp.Changed(self, Operation, W, L);
end;

function TAmItemComponent.ItemBroadcast(Operation, W, L: integer): integer;
begin
  Result := 0;
  ItemChanged(Operation, W, L);
end;

procedure TAmItemComponent.Release;
begin
  Free;
end;

procedure TAmItemComponent.FreeOnRelease(var AInterface);
begin
  TAmObject.FreeInterfaceClass(AInterface);
end;

function TAmItemComponent.iItemIndexGet: integer;
begin
  Result := AmItemHelp.IndexGet(self)
end;

procedure TAmItemComponent.iItemIndexSet(const Value: integer);
begin
  AmItemHelp.IndexSet(self, Value);
end;

function TAmItemComponent.iItemIndexFieldGet: integer;
begin
  Result := AmAtomic.Getter(FIndex);
end;

procedure TAmItemComponent.iItemIndexFieldSet(const Value: integer);
begin
  if iItemIndexFieldGet <> Value then
  begin
    AmAtomic.Setter(FIndex, Value);
    ItemChanged(AmItemOperation.IndexChange, 0, 0);
  end;
end;

function TAmItemComponent.iItemIndivGet: integer;
begin
  Result := AmAtomic.Getter(FIndiv);
end;

procedure TAmItemComponent.iItemIndivSet(const Value: integer);
begin
  if iItemIndivGet <> Value then
  begin
    AmAtomic.Setter(FIndiv, Value);
    ItemChanged(AmItemOperation.IndivSet, 0, 0);
  end;
end;

function TAmItemComponent.iListGet: IAmListItemOwner;
begin
  Result := IAmListItemOwner(AmAtomic.Getter(FList));
end;

procedure TAmItemComponent.iListSet(const Value: IAmListItemOwner);
begin
  AmItemHelp.ListSet(self, FList, Value);
end;

procedure TAmItemComponent.iLoaded;
begin
  ItemChanged(AmItemOperation.Loaded, 0, 0);
end;

function TAmItemComponent.iItemIdGet: Cardinal;
begin
  Result := AmAtomic.Getter(FId);
end;

procedure TAmItemComponent.iItemIdSet(const Value: Cardinal);
begin
  AmAtomic.Setter(FId, Value);
end;

function TAmItemComponent.iAsPers: TPersistent;
begin
  Result := AmItemHelp.GetSelfPers(self);
end;

function TAmItemComponent.iAsRef(Value: Cardinal): Cardinal;
begin
  Result := 0;
end;

function TAmItemComponent.iAsObj: TObject;
begin
  Result := self;
end;

{ TAmItemPersInf }
constructor TAmItemPersInf.Create(AListOwner: IAmListItemOwner);
begin
  inherited Create;
  iItemIdSet(0);
  FList := nil;
  FIndex := -1;
  FIndiv := 0;
  List := AListOwner;

end;

destructor TAmItemPersInf.Destroy;
begin
  AmItemHelp.ItemListRelease(self);
  inherited Destroy;
end;

procedure TAmItemPersInf.BeforeDestruction;
var
  C: integer;
begin
  // перед удалением объекта допустимо иметь только одну ссылку на интерфейс
  // и только хранящиюся в листе родителя
  // если list =nil то  RefCounter должен быть   0
  C := RefCounter;
  if (List <> nil) then
    dec(C);
  if C <> 0 then
    raise Exception.CreateResFmt(@Rs_TAmItemPersInf_BeforeDestruction,
      [self.ClassName, C.ToString]);
  inherited BeforeDestruction;

end;

function TAmItemPersInf.ItemCanChangedList(Now: IAmListItemOwner;  var New: IAmListItemOwner): boolean;
begin
  Result := true;
end;

procedure TAmItemPersInf.ItemChanged(Operation, W, L: integer);
begin
  AmItemHelp.Changed(self, Operation, W, L);
end;

function TAmItemPersInf.IndexGetTry(AIndex: integer): integer;
begin
  Result := -1;
  if (self.List <> nil) and (List.GetList <> nil) then
  begin
    if AIndex < 0 then
      AIndex := 0;
    if AIndex > List.GetList.Count - 1 then
      AIndex := List.GetList.Count - 1;
    Result := AIndex;
  end;
end;

procedure TAmItemPersInf.IndexSetTry(AIndex: integer);
begin
  Index := IndexGetTry(AIndex);
end;

function TAmItemPersInf.ItemBroadcast(Operation, W, L: integer): integer;
begin
  Result := 0;
  ItemChanged(Operation, W, L);
end;

procedure TAmItemPersInf.Release;
begin
  Free;
end;

function TAmItemPersInf.iItemIndexGet: integer;
begin
  Result := AmItemHelp.IndexGet(self)
end;

procedure TAmItemPersInf.iItemIndexSet(const Value: integer);
begin
  AmItemHelp.IndexSet(self, Value);
end;

function TAmItemPersInf.iItemIndexFieldGet: integer;
begin
  Result := AmAtomic.Getter(FIndex);
end;

procedure TAmItemPersInf.iItemIndexFieldSet(const Value: integer);
begin
  if iItemIndexFieldGet <> Value then
  begin
    AmAtomic.Setter(FIndex, Value);
    ItemChanged(AmItemOperation.IndexChange, 0, 0);
  end;
end;

function TAmItemPersInf.iItemIndivGet: integer;
begin
  Result := AmAtomic.Getter(FIndiv);
end;

procedure TAmItemPersInf.iItemIndivSet(const Value: integer);
begin
  if iItemIndivGet <> Value then
  begin
    AmAtomic.Setter(FIndiv, Value);
    ItemChanged(AmItemOperation.IndivSet, 0, 0);
  end;
end;

function TAmItemPersInf.iListGet: IAmListItemOwner;
begin
  Result := IAmListItemOwner(AmAtomic.Getter(FList));
end;

procedure TAmItemPersInf.iListSet(const Value: IAmListItemOwner);
begin
  AmItemHelp.ListSet(self, FList, Value);
end;

procedure TAmItemPersInf.iLoaded;
begin
  ItemChanged(AmItemOperation.Loaded, 0, 0);
end;

function TAmItemPersInf.iItemIdGet: Cardinal;
begin
  Result := AmAtomic.Getter(FId);
end;

procedure TAmItemPersInf.iItemIdSet(const Value: Cardinal);
begin
  AmAtomic.Setter(FId, Value);
end;

function TAmItemPersInf.AsPers: TPersistent;
begin
  Result := self;
end;

function TAmItemPersInf.iAsRef(Value: Cardinal): Cardinal;
begin
  Result := 0;
end;

function TAmItemPersInf.AsObj: TObject;
begin
  Result := self;
end;

{ TAmItemObject }
constructor TAmItemObject.Create(AListOwner: IAmListItemOwner);
begin
  inherited Create;
  iItemIdSet(0);
  FList := nil;
  FIndex := -1;
  FIndiv := 0;
  List := AListOwner;
end;

destructor TAmItemObject.Destroy;
begin
  AmItemHelp.ItemListRelease(self);
  inherited;
end;

procedure TAmItemObject.FreeOnRelease(var AInterface);
begin
end;

function TAmItemObject.ItemCanChangedList(Now: IAmListItemOwner;
  var New: IAmListItemOwner): boolean;
begin
  Result := true;
end;

procedure TAmItemObject.ItemChanged(Operation, W, L: integer);
begin
  AmItemHelp.Changed(self, Operation, W, L);
end;

function TAmItemObject.ItemBroadcast(Operation, W, L: integer): integer;
begin
  Result := 0;
  ItemChanged(Operation, W, L);
end;

procedure TAmItemObject.Release;
begin
  AmItemHelp.ItemListRelease(self);
end;

function TAmItemObject.iItemIndexGet: integer;
begin
  Result := AmItemHelp.IndexGet(self)
end;

procedure TAmItemObject.iItemIndexSet(const Value: integer);
begin
  AmItemHelp.IndexSet(self, Value);
end;

function TAmItemObject.iItemIndexFieldGet: integer;
begin
  Result := AmAtomic.Getter(FIndex);
end;

procedure TAmItemObject.iItemIndexFieldSet(const Value: integer);
begin
  if iItemIndexFieldGet <> Value then
  begin
    AmAtomic.Setter(FIndex, Value);
    ItemChanged(AmItemOperation.IndexChange, 0, 0);
  end;
end;

function TAmItemObject.iItemIndivGet: integer;
begin
  Result := AmAtomic.Getter(FIndiv);
end;

procedure TAmItemObject.iItemIndivSet(const Value: integer);
begin
  if iItemIndivGet <> Value then
  begin
    AmAtomic.Setter(FIndiv, Value);
    ItemChanged(AmItemOperation.IndivSet, 0, 0);
  end;
end;

function TAmItemObject.iListGet: IAmListItemOwner;
begin
  Result := IAmListItemOwner(AmAtomic.Getter(FList));
end;

procedure TAmItemObject.iListSet(const Value: IAmListItemOwner);
begin
  AmItemHelp.ListSet(self, FList, Value);
end;

procedure TAmItemObject.iLoaded;
begin
  ItemChanged(AmItemOperation.Loaded, 0, 0);
end;

function TAmItemObject.iItemIdGet: Cardinal;
begin
  Result := AmAtomic.Getter(FId);
end;

procedure TAmItemObject.iItemIdSet(const Value: Cardinal);
begin
  AmAtomic.Setter(FId, Value);
end;

function TAmItemObject.iAsRef(Value: Cardinal): Cardinal;
begin
  Result := 0;
end;

function TAmItemObject.iAsPers: TPersistent;
begin
  Result := nil;
end;

function TAmItemObject.AsObj: TObject;
begin
  Result := self;
end;


{ TAmListItemCustom }

constructor TAmListItemCustom.Create;
begin
  inherited Create;
  FList := TList<IAmItem>.Create;
  FIdCounter := 0;
  FIsNeedEvent := true;
  FLockChange := 0;
end;

destructor TAmListItemCustom.Destroy;
begin
  InternalClear;
  inherited Destroy;
  FreeAndNil(FList);
end;

procedure TAmListItemCustom.BeforeDestruction;
begin
  inherited BeforeDestruction;
end;

function TAmListItemCustom.IsMyChildObject(ACheckObject: TObject): boolean;
var
  Item: IAmItem;
begin
  Result := False;
  if ACheckObject = nil then
    exit;
  Result := inherited IsMyChildObject(ACheckObject);
  if not Result then
  begin
    Item := SupObjToItem(ACheckObject, False);
    if Item <> nil then
      Result := Item.List = IAmListItemOwner(self);
  end;
end;

function TAmListItemCustom.SupObjToItem(Obj: TObject; IsError: boolean) : IAmItem;
begin
  Result := nil;
  if Obj <> nil then
  begin
    if (not Supports(Obj, IAmItem, Result) or (Result = nil)) and IsError then
      raise Exception.CreateResFmt(@Rs_TAmListItemCustom_SupObjToItem,[Obj.ClassName]);
  end;
end;

function TAmListItemCustom.EmulAdd(Item: IAmItem): integer;
var
  Prm: TAmItemsPrm;
begin

  ChangeLock;
  try
    if Item = nil then
      raise Exception.CreateResFmt(@Rs_TAmListItemCustom_EmulAdd1, [])
    else if Item.List <> IAmListItemOwner(self) then
      raise Exception.CreateResFmt(@Rs_TAmListItemCustom_EmulAdd2, []);

    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcChildItemAdding;
      Prm.ItemChild := Item.AsObj;
      DoChanged(@Prm);
    end;

    Result := FList.Add(Item);

    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcChildItemAdd;
      Prm.ItemChild := Item.AsObj;
      DoChanged(@Prm);
    end;

  finally
    ChangeUnLock;
  end;

end;

procedure TAmListItemCustom.EmulChangeItem(Item: IAmItem;
  Operation, W, L: integer);
var
  Prm: TAmItemsPrm;
begin
  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcChangeItem;
      Prm.Item := Item.AsObj;
      Prm.Operation := Operation;
      Prm.W := W;
      Prm.L := L;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;

end;

function TAmListItemCustom.EmulRemove(Item: IAmItem): integer;
var
  Prm: TAmItemsPrm;
begin
  Result := -1;
  ChangeLock;
  try
    if Item = nil then
      raise Exception.CreateResFmt(@Rs_TAmListItemCustom_EmulRemove, []);

    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcChildItemRemoving;
      Prm.ItemChild := Item.AsObj;
      DoChanged(@Prm);
    end;

    if Count > 0 then
    begin
      if FList.Last = Item then
      begin
        Result := Count - 1;
        FList.Delete(Count - 1);
      end
      else
      begin
        Result := Item.ItemIndexFieldGet;
        if (Result >= 0) and (Result < Count) and (FList[Result] = Item) then
          FList.Delete(Result)
        else
          Result := FList.Remove(Item);
      end;
    end;

    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcChildItemRemoved;
      Prm.ItemChild := Item.AsObj;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

function TAmListItemCustom.EmulIndexOf(Value: IAmItem): integer;
begin
  if Value <> nil then
    Result := FList.IndexOf(Value)
  else
    Result := -1;
end;

function TAmListItemCustom.EmulListOwner: IAmListItemOwner;
begin
  Result := self;
end;

function TAmListItemCustom.EmulGetCount: integer;
begin
  Result := FList.Count;
end;

function TAmListItemCustom.EmulGetList: IAmListItem;
begin
  Result := self;
end;

function TAmListItemCustom.EmulGet(Index: integer): IAmItem;
begin
  Result := FList[Index];
end;

function TAmListItemCustom.EmulHas(Index: integer): boolean;
begin
  Result := Has(Index);
end;

procedure TAmListItemCustom.EmulMove(CurIndex, NewIndex: integer);
begin
  Move(CurIndex, NewIndex);
end;

function TAmListItemCustom.EmulGetNextId: Cardinal;
begin
  Result := AmAtomic.NewId(FIdCounter);
end;

function TAmListItemCustom.Has(Index: integer): boolean;
begin
  Result := (Index >= 0) and (Index < FList.Count)
end;

procedure TAmListItemCustom.DoChanged(Prm: PAmItemsPrm);
begin
  if ((FLockChange <= 1) or (Prm.Enum = lcUpdate))
  and not self.DestroyingObject  then
    Changed(Prm);
end;

procedure TAmListItemCustom.Changed(Prm: PAmItemsPrm);
begin
end;

procedure TAmListItemCustom.ChangeLock;
begin
  inc(FLockChange);
end;

procedure TAmListItemCustom.ChangeUnLock;
begin
  dec(FLockChange);
end;

procedure TAmListItemCustom.ItemCreate(var NewItem: IAmItem);
begin
  if Assigned(FEventCreate) then
    FEventCreate(NewItem);
end;

function TAmListItemCustom.ItemsChangedBroadcast(Operation, W,
  L: integer): integer;
var
  i: integer;
begin
  Result := 0;
  if (FList <> nil) and (FList.Count > 0) then
  begin
    for i := FList.Count - 1 downto 0 do
      if FList[i] <> nil then
      begin
        Result := FList[i].Broadcast(Operation, W, L);
        if Result <> 0 then
          exit();
      end;
  end;
end;

procedure TAmListItemCustom.InternalItemCreate(var NewItem: IAmItem);
begin
  if NewItem <> nil then
    exit;
  ItemCreate(NewItem);
  if NewItem = nil then
    AmRaiseBase.__Program('TAmListItemCustom.InternalItemCreate NewItem = nil');
end;

procedure TAmListItemCustom.InternalClear;
var
  i: integer;
begin
  if (FList <> nil) and (FList.Count > 0) then
  begin
    for i := FList.Count - 1 downto 0 do
      InternalDelete(i);
    FList.Clear;
  end;
end;

procedure TAmListItemCustom.InternalInsert(Index: integer; const Item: IAmItem);
var
  OldIndex: integer;
begin
  if Item <> nil then
  begin
    if Item.List <> IAmListItemOwner(self) then
    begin
      Item.List := self;

      if (Item.List = IAmListItemOwner(self)) and (Item.ItemIndex <> Index) then
      begin
        OldIndex := Item.ItemIndex;
        FList.Move(OldIndex, Index);
        FList[Index].ItemIndexFieldSet(Index);
        FList[Index].Changed(AmItemOperation.IndexSet, OldIndex, Index);
      end;
    end
    // else raise Exception.Create('Error  TAmListItemCustom.InternalInsert повтроное добавление IAmItem в лист');
    // закоментил т.к InternalInsert вызывается не только при Insert
  end
  else
    FList.Insert(Index, Item);
end;

procedure TAmListItemCustom.InternalPut(Index: integer; const Item: IAmItem);
begin
  InternalDelete(Index);
  InternalInsert(Index, Item);
end;

procedure TAmListItemCustom.InternalDelete(Index: integer);
var
  [unsafe] Item: IAmItem;
  AItem: IAmItem;
begin
  AItem := FList[Index];
  Item := AItem;
  AItem := nil;
  if Item <> nil then
    Item.Release
  else
    FList.Delete(Index);
end;

function TAmListItemCustom.InternalExtract(Index: integer): IAmItem;
begin
  Result := FList[Index];
  if Result <> nil then
    Result.List := nil
  else
    FList.Delete(Index);
end;

function TAmListItemCustom.AddNew: IAmItem;
begin
  Result := InsertNew(Count);
end;

function TAmListItemCustom.Add(Item: IAmItem): integer;
begin
  Result := Count;
  Insert(Result, Item);
end;

procedure TAmListItemCustom.Clear;
var
  Prm: TAmItemsPrm;
begin

  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcClearB;
      DoChanged(@Prm);
    end;
    if FList.Count > 0 then
    begin
      UpdateBegin;
      try
        InternalClear;
        Update;
      finally
        UpdateEnd;
      end;
    end;
    if FIsNeedEvent then
    begin
      Prm.Enum := lcClear;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

procedure TAmListItemCustom.Delete(Index: integer);
var
  Prm: TAmItemsPrm;
begin
  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcDeleteB;
      Prm.Index := Index;
      DoChanged(@Prm);
      Index := Prm.Index;
    end;

    self.InternalDelete(Index);

    if FIsNeedEvent then
    begin
      Prm.Enum := lcDelete;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

function TAmListItemCustom.Extract(Index: integer): IAmItem;
var
  Prm: TAmItemsPrm;
begin
  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcExtractB;
      Prm.Index := Index;
      DoChanged(@Prm);
      Index := Prm.Index;
    end;

    Result := self.InternalExtract(Index);

    if FIsNeedEvent then
    begin
      Prm.Enum := lcExtract;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

procedure TAmListItemCustom.Exchange(Index1, Index2: integer);
var
  Prm: TAmItemsPrm;
  old: integer;
begin
  if Index1 = Index2 then
    exit;
  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcExchangeB;
      Prm.Index1 := Index1;
      Prm.Index2 := Index2;
      DoChanged(@Prm);
      Index1 := Prm.Index1;
      Index2 := Prm.Index2;
    end;

    FList.Exchange(Index1, Index2);

    if FList[Index1] <> nil then
    begin
      FList[Index1].ItemIndexFieldSet(Index1);
      FList[Index1].Changed(AmItemOperation.IndexSet, Index2, Index1);
    end;

    if FList[Index2] <> nil then
    begin
      FList[Index2].ItemIndexFieldSet(Index2);
      FList[Index2].Changed(AmItemOperation.IndexSet, Index1, Index2);
    end;

    if FIsNeedEvent then
    begin
      Prm.Enum := lcExchange;
      DoChanged(@Prm);
    end;

  finally
    ChangeUnLock;
  end;
end;

function TAmListItemCustom.Get(Index: integer): IAmItem;
begin
  Result := FList[Index];
end;

procedure TAmListItemCustom.ItemsUnsafe(Index: integer; var [unsafe] Result: IAmItem);
var
  R: IAmItem;
begin
  R := FList[Index];
  Result := R;
  R := nil;
end;

function TAmListItemCustom.GetCount: integer;
begin
  Result := FList.Count;
end;

function TAmListItemCustom.IndexOf(Item: IAmItem): integer;
begin
  if Item <> nil then
    Result := FList.IndexOf(Item)
  else
    Result := -1;
end;

function TAmListItemCustom.IndexOfId(AId: Cardinal): integer;
begin
  for Result := 0 to FList.Count - 1 do
    if FList[Result].ItemId = AId then
      exit;
  Result := -1;
end;

procedure TAmListItemCustom.Insert(Index: integer; Item: IAmItem);
var
  Prm: TAmItemsPrm;
begin
  if (Item <> nil) and (Item.List = IAmListItemOwner(self)) then
    raise Exception.CreateResFmt(@Rs_TAmListItemCustom_DublicateItem, ['Insert']);

  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcInsertB;
      Prm.IndexVar := Index;
      Prm.PVar := @Item;
      DoChanged(@Prm);
      if @Item <> Prm.PVar then
        Item := IAmItem(Prm.PVar^);
      Index := Prm.IndexVar;
    end;

    InternalInsert(Index, Item);

    if FIsNeedEvent then
    begin
      Prm.Enum := lcInsert;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

function TAmListItemCustom.NewItem: IAmItem;
begin
  Result := nil;
  InternalItemCreate(Result);
end;

function TAmListItemCustom.InsertNew(Index: integer): IAmItem;
begin
  Result := NewItem;
  Insert(Index, Result);
end;

procedure TAmListItemCustom.Move(CurIndex, NewIndex: integer);
var
  Prm: TAmItemsPrm;
begin
  if CurIndex = NewIndex then
    exit;

  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcMoveB;
      Prm.Index1 := CurIndex;
      Prm.Index2 := NewIndex;
      DoChanged(@Prm);
      CurIndex := Prm.Index1;
      NewIndex := Prm.Index2;
    end;

    FList.Move(CurIndex, NewIndex);

    if FList[NewIndex] <> nil then
    begin
      FList[NewIndex].ItemIndexFieldSet(NewIndex);
      FList[NewIndex].Changed(AmItemOperation.IndexSet, CurIndex, NewIndex);
    end;

    if FIsNeedEvent then
    begin
      Prm.Enum := lcMove;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

procedure TAmListItemCustom.Put(Index: integer; Item: IAmItem);
var
  Prm: TAmItemsPrm;
begin
  if FList[Index] = Item then
    exit;
  if (Item <> nil) and (Item.List = IAmListItemOwner(self)) then
    raise Exception.CreateResFmt(@Rs_TAmListItemCustom_DublicateItem, ['Put']);

  ChangeLock;
  try
    if FIsNeedEvent then
    begin
      Prm.Clear;
      Prm.Enum := lcPutB;
      Prm.IndexVar := Index;
      Prm.PVar := @Item;
      DoChanged(@Prm);
      if @Item <> Prm.PVar then
        Item := IAmItem(Prm.PVar^);
      Index := Prm.IndexVar;
    end;

    if FList[Index] <> Item then
      InternalPut(Index, Item);

    if FIsNeedEvent then
    begin
      Prm.Enum := lcPut;
      DoChanged(@Prm);
    end;
  finally
    ChangeUnLock;
  end;
end;

function TAmListItemCustom.Remove(ItemRemove: IAmItem): integer;
var
  [unsafe]
  AItem: IAmItem;
begin
  Result := -1;
  AItem := ItemRemove;
  ItemRemove := nil;
  if AItem = nil then
    exit();
  if AItem.List = IAmListItemOwner(self) then
  begin
    Result := AItem.ItemIndex;
    if Result >= 0 then
      Delete(Result);
  end;
end;

procedure TAmListItemCustom.SetCount(NewCount: integer);
var
  Prm: TAmItemsPrm;
  old, i: integer;
begin
  ChangeLock;
  try
    if FList.Count <> NewCount then
    begin
      if FIsNeedEvent then
      begin
        Prm.Clear;
        Prm.Enum := lcSetCountB;
        Prm.CountOld := FList.Count;
        Prm.CountNew := NewCount;
        DoChanged(@Prm);
        NewCount := Prm.CountNew;
      end;
      if FList.Count <> NewCount then
      begin
        old := FList.Count;
        if NewCount < old then
        begin
          for i := old - 1 downto NewCount do
            InternalDelete(i);
        end
        else
        begin
          for i := old to NewCount - 1 do
            self.InternalInsert(i, NewItem);
        end;

        if FIsNeedEvent then
        begin
          Prm.Clear;
          Prm.Enum := lcSetCount;
          Prm.CountOld := old;
          Prm.CountNew := FList.Count;
          DoChanged(@Prm);
        end;
      end;
    end;
  finally
    ChangeUnLock;
  end;
end;

procedure TAmListItemCustom.UpdateBegin;
begin
  inherited UpdateBegin;
end;

function TAmListItemCustom.UpdateCountGet: integer;
begin
  Result := inherited UpdateCountGet;
end;

procedure TAmListItemCustom.DoUpdate;
var
  Prm: TAmItemsPrm;
begin
  inherited DoUpdate;
  if FIsNeedEvent then
  begin
    Prm.Clear;
    Prm.Enum := lcUpdate;
    Prm.Updating := False;
    DoChanged(@Prm);
  end;
end;

procedure TAmListItemCustom.UpdateEnd;
begin
  inherited UpdateEnd;
end;

{ TAmListItemObj<T> }

procedure TAmListItemObj.AfterConstruction;
begin
end;

procedure TAmListItemObj.BeforeDestruction;
begin
  DestroyingObjectSet;
  DoDestroyBefore;
end;

{ TAmItemsPrm }

procedure TAmItemsPrm.Clear;
begin
  AmRecordHlpBase.RecFinal(self);
  Enum := lcInvalid;
end;

{ TAmListItemPers<T> }

procedure TAmListItemPers.DefineProperties(СonsequenceNameProperty: string;
  Filer: TFiler);
begin
  Filer.DefineProperty(СonsequenceNameProperty, ReadData, WriteData, Count > 0);
end;

procedure TAmListItemPers.Loaded;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    if Items[i] <> nil then
      Items[i].Loaded;

end;

procedure TAmListItemPers.ReadData(Reader: TReader);
var
  VTyp, VTypValue: string;

  procedure LocAddObject(ANameClass: string);
  var
    Item: IAmItem;
    AClass: TClass;
  begin
    AClass := System.Classes.GetClass(ANameClass);
    Item := ReadCreateItem(ANameClass, AClass);
    if (Item <> nil) and (Item.AsPers <> nil) then
    begin
      while not Reader.EndOfList do
        TLocReader(Reader).ReadProperty(Item.AsPers);
    end
    else
      ReadInvalidClass(Item, Reader);
    Add(Item);
  end;

begin
  self.UpdateBegin;
  try
    ReadDataBefore;
    try
      if Reader.NextValue <> vaCollection then
        raise Exception.Create
          ('Error TAmListItemColection.ReadData invalid property');
      Reader.ReadValue;
      if not Reader.EndOfList then
        Clear;
      while not Reader.EndOfList do
      begin
        if Reader.NextValue in [vaCollection, vaInt8, vaInt16, vaInt32] then
          Reader.ReadInteger;
        Reader.ReadListBegin;
        VTyp := Reader.ReadStr;
        VTypValue := Reader.ReadString;
        if (VTyp = 'typsys') and (VTypValue <> 'nil') then
          LocAddObject(VTypValue)
        else if (VTyp = 'typsys') and (VTypValue = 'nil') then
          Add(nil);
        Reader.ReadListEnd;
      end;
      Reader.ReadListEnd;
    finally
      ReadDataAfter;
    end;
    self.Update;
  finally
    self.UpdateEnd;
  end;
end;

procedure TAmListItemPers.ReadDataAfter;
begin
end;

procedure TAmListItemPers.ReadDataBefore;
begin
end;

function TAmListItemPers.ReadCreateItem(AClassName: string;
  AClass: TClass): IAmItem;
begin
  Result := nil;
  InternalItemCreate(Result);
end;

procedure TAmListItemPers.ReadInvalidClass(Item: IAmItem; Reader: TReader);
var
  C: string;
begin
  if Item <> nil then
    C := TObject(Item).ClassName
  else
    C := 'nil';
  raise Exception.Create('Error TAmListItemColection.ReadInvalidClass [' + C + ']');
end;

function TAmListItemPers.CanWriteItem(Item: IAmItem): boolean;
begin
  Result := true;
end;

procedure TAmListItemPers.WriteData(Writer: TWriter);
var
  i: integer;
  OldAncestor: TPersistent;
  SavePropPath: string;
  [weak]  P: IAmItem;
begin
  OldAncestor := Writer.Ancestor;
  Writer.Ancestor := nil;
  SavePropPath := Writer.PropPath;
  Writer.PropPath := '';
  try
    WriteDataBefore;
    try
      TLocWriter(Writer).WriteValue(vaCollection);
      for i := 0 to GetCount - 1 do
      begin
        P := Items[i];
        if (P <> nil) and (P.AsPers <> nil) and not CanWriteItem(P) then
          continue;

        Writer.WriteListBegin;
        try
          if (P <> nil) and (P.AsPers <> nil) then
          begin
            TLocWriter(Writer).WritePropName('typsys');
            Writer.WriteString(P.AsPers.ClassName);
            TLocWriter(Writer).WriteProperties(P.AsPers);
          end
          else if not WriteInvalidClass(i, P, Writer) then
          begin
            TLocWriter(Writer).WritePropName('typsys');
            Writer.WriteString('nil');
          end;
        finally
          Writer.WriteListEnd;
        end;
      end;
      Writer.WriteListEnd;
    finally
      WriteDataAfter;
    end;
  finally
    Writer.Ancestor := OldAncestor;
    Writer.PropPath := SavePropPath;
  end;
end;

procedure TAmListItemPers.WriteDataAfter;
begin
end;

procedure TAmListItemPers.WriteDataBefore;
begin
end;

function TAmListItemPers.WriteSignatureOneItem(Item: IAmItem): string;
var
  Writer: TWriter;
  ms: TMemoryStream;
  Sm: TStringstream;
begin
  if Item.AsPers = nil then
    exit('');
  WriteDataBefore;
  try
    ms := TMemoryStream.Create;
    Sm := TStringstream.Create;
    try
      Writer := TWriter.Create(ms, 4096);
      try
        Writer.WriteSignature;
        Writer.WriteUTF8Str(Item.AsPers.ClassName);
        Writer.WriteUTF8Str('');
        Writer.WriteProperties(Item.AsPers);
        Writer.WriteListEnd;
        Writer.WriteListEnd;
      finally
        Writer.Free;
      end;
      ms.Position := 0;
      ObjectBinaryToText(ms, Sm);
      Result := Sm.DataString;
    finally
      ms.Free;
      Sm.Free;
    end;
  finally
    WriteDataAfter;
  end;
end;

function TAmListItemPers.ReadSignatureOneItem(Input: string): IAmItem;
var
  ms: TMemoryStream;
  Sm: TStringstream;
  Reader: TReader;
  AClass: TClass;
  ANameClass: string;
begin
  self.UpdateBegin;
  try
    ReadDataBefore;
    try
      ms := TMemoryStream.Create;
      Sm := TStringstream.Create(Input);
      try
        Sm.Position := 0;
        ObjectTextToBinary(Sm, ms);
        ms.Position := 0;
        Reader := TReader.Create(ms, 4096);
        try
          Reader.BeginReferences;
          try
            Reader.ReadSignature;
            Reader.Root := Application.MainForm;

            ANameClass := Reader.ReadStr;
            Reader.ReadStr;
            AClass := System.Classes.GetClass(ANameClass);
            Result := ReadCreateItem(ANameClass, AClass);
            while not Reader.EndOfList do
              TLocReader(Reader).ReadProperty(Result.AsPers);
            Reader.ReadListEnd;
            Reader.ReadListEnd;
            Reader.FixupReferences;
            Add(Result);
            self.Update;
          finally
            Reader.EndReferences;
          end;
        finally
          Reader.Free;
        end;
      finally
        ms.Free;
        Sm.Free;
      end;
    finally
      ReadDataAfter;
    end;
  finally
    self.UpdateEnd;
  end;
end;

function TAmListItemPers.WriteInvalidClass(Index: integer; Item: IAmItem;
  Writer: TWriter): boolean;
var
  C: string;
begin
  Result := False;
  if Item <> nil then
    C := TObject(Item).ClassName
  else
    C := 'nil';
  if C <> '' then
    raise Exception.Create('Error TAmListItemColection.ReadInvalidClass [Index:'
      + Index.ToString + ' Class:' + C + ']');
end;

{ TAmListItemColection }

constructor TAmListItemColection.Create;
begin
  inherited Create;
  FPersDesingNotify := TAmPersDesingNotifyHelp.Create(PersDesingNotifyGetOwner);
end;

destructor TAmListItemColection.Destroy;
begin
  InternalClear;
  FPersDesingNotify.Free;
  FPersDesingNotify := nil;
  inherited Destroy;
end;

function TAmListItemColection.GetComponentRoot: TComponent;
begin
  Result := nil;
end;

function TAmListItemColection.GetOwner: TPersistent;
begin
  Result := nil;
end;

function TAmListItemColection.IsMyChildObject(ACheckObject: TObject): boolean;
begin
  Result := False;
  if ACheckObject = nil then
    exit;
  Result := FPersDesingNotify = ACheckObject;
  if not Result then
    Result := inherited IsMyChildObject(ACheckObject);
end;

procedure TAmListItemColection.PersDesingNotifyGetOwner(Sender: TObject;
  var AOwner: TPersistent);
begin
  AOwner := GetOwner;
end;

function TAmListItemColection.AsPersDesingNotify: TPersistent;
begin
  Result := FPersDesingNotify;
end;

function TAmListItemColection.wcAdd(Item: TPersistent): integer;
begin
  Result := inherited Add(SupObjToItem(Item));
end;

function TAmListItemColection.wcAddNew: TPersistent;
var
  Item: IAmItem;
begin
  Result := nil;
  Item := inherited AddNew();
  if Item <> nil then
    Result := Item.AsPers;
end;

procedure TAmListItemColection.Changed(Prm: PAmItemsPrm);
begin
  inherited Changed(Prm);
  if AmDesing.IsDesingTime then
    case Prm.Enum of
      // lcInvalid,
      // lcChangeCustom,//любое другое изменение листа
      // lcChangeItem,//изменение в самом одном итеме
      // lcClassItem,
      // lcChildItemAdd,
      // lcChildItemRemoving,
      // lcSetCountB,
      lcSetCount, lcUpdate,
      // lcClearB,
      lcClear,
      // lcDeleteB,
      lcDelete,
      // lcExtractB,
      lcExtract,
      // lcExchangeB,
      lcExchange,
      // lcInsertB,
      lcInsert,
      // lcMoveB,
      lcMove,
      // lcPutB,
      lcPut,
      // lcAssignB,
      lcAssign:
        begin
          AmDesing.Modified(FPersDesingNotify);
        end;
    end;
end;

procedure TAmListItemColection.DoChanged(Prm: PAmItemsPrm);
var
  AItem: TPersistent;
  function LocGetItem: TPersistent;
  begin
    if (Prm.ItemChild <> nil) and (Prm.ItemChild is TPersistent) then
      Result := TPersistent(Prm.ItemChild)
    else
      Result := nil;
  end;

begin
  if AmDesing.IsDesingTime then
    case Prm.Enum of
      lcChildItemAdd:
        begin
          AItem := LocGetItem;
          AmDesing.NotifyItemAdd(FPersDesingNotify, AItem);
        end;
      lcChildItemRemoving:
        begin
          AItem := LocGetItem;
          AmDesing.NotifyItemRemove(FPersDesingNotify, AItem);
        end;
    end;

  inherited DoChanged(Prm);
end;

function TAmListItemColection.wcInsertNew(Index: integer): TPersistent;
var
  Item: IAmItem;
begin
  Result := nil;
  Item := inherited InsertNew(Index);
  if Item <> nil then
    Result := Item.AsPers;
end;

procedure TAmListItemColection.wcInsert(Index: integer; Item: TPersistent);
begin
  inherited Insert(Index, SupObjToItem(Item));
end;

function TAmListItemColection.wcGet(Index: integer): TPersistent;
var
  Item: IAmItem;
begin
  Result := nil;
  Item := inherited Get(Index);
  if Item <> nil then
    Result := Item.AsPers;
end;

procedure TAmListItemColection.ItemsUnsafe(Index: integer; var [unsafe] Result: TPersistent);
var
  R: TPersistent;
begin
  R := wcGet(Index);
  Result := R;
end;

function TAmListItemColection.wcIndexOf(Item: TPersistent): integer;
begin
  Result := inherited IndexOf(SupObjToItem(Item, False));
end;

procedure TAmListItemColection.wcPut(Index: integer; Item: TPersistent);
begin
  inherited Put(Index, SupObjToItem(Item));
end;

function TAmListItemColection.wcRemove(Item: TPersistent): integer;
begin
  Result := inherited Remove(SupObjToItem(Item, False));
end;

end.
