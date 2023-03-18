unit AmHookWinMsg;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Types,
  System.Variants,
  System.Classes,
  System.SyncObjs,
  System.IOUtils,
  System.Math,
  Vcl.Controls;

type
  // что делать когда нашли сообщение   amwhSend оптимальный вариант
  TAmWinHookFromEnum = (amwinhookFromNone,
                       amwinhookFromPost,
                       amwinhookFromSend,
                       amwinhookFromProc);

  TAmWinHookElement = class;
  TAmWinHookElementClass = class of TAmWinHookElement;

  // TAmWinHookList  = class;
  // глобал 1 экземпляр в для главного потока приложения
  // критических секций для защиты листов нет.
  // использование класса допустимо только для потока кто его создал
  TAmWinHook = class;
  // создаем и используем для всех объектов
  // TAmMsgHookList  = class;
  // создаем и используем для TWinControl также обрабатывает WM_CREATE WM_DESTROY что бы обновлять handle
  // TAmVclHookList  = class;

  // используется когда наступило сообытие что бы отправить и получить все параметры сообщения когда сообщение перехвачено
  // если  использовать FromMsgProc:TAmWinHookEvent она отправляется  как параметр var процедура при удалении объектов теряется и иногда ошибки вылетают
  // если  использовать SendMessage   она отправляется в lparam   if Msg.LParam<>0 then Param:= PAmWinHookMessage(Msg.LParam)
  // если  использовать PostMessage   lparam=0
  PAmWinHookMessage = ^TAmWinHookMessage;

  TAmWinHookMessage = record
  private
    FSendTyp: boolean;
    FHandle: Pointer;
    [weak]
    FElement: TAmWinHookElement;
    function PostGet: PMsg;
    function SendGet: PCWPStruct;
    function Struct: TCWPStruct;
    function HwdGet: HWND;
    function LPrmGet: LPARAM;
    function MessageGet: UINT;
    function WPrmGet: WPARAM;
    function MessageWinGet: TMessage;
  public
    // ссылка на объект настроек
    property Element: TAmWinHookElement read FElement;

    // если  SendTyp = true то обрашатся к  Send
    property SendTyp: boolean read FSendTyp;
    property Send: PCWPStruct read SendGet;
    property Post: PMsg read PostGet;

    // получить копию структуры
    property StructCopy: TCWPStruct read Struct;
    property HandleSource: Pointer read FHandle;

    // параметры по частям
    property Hwd: HWND read HwdGet;
    property Message: UINT read MessageGet;
    property LPrm: LPARAM read LPrmGet;
    property WPrm: WPARAM read WPrmGet;
    property MessageWin: TMessage read MessageWinGet;
  end;

  // процедура события когда найдено искомое сообщение
  TAmWinHookEvent = procedure(Prm: PAmWinHookMessage) of object;

  // объект настроек что именно перехватиывать куда пересылать
  TAmWinHookElement = class
  private
    // глобальный id
    FId: Cardinal;
    [weak]
    FOwner: TAmWinHook;

    // состояние запушен ли перехрат у этого элемента
    FStarted: boolean;
    // испозуется для оправки аргумента при событии
    FPrmMessage: TAmWinHookMessage;

    // свободное поле
    FProp: Pointer;

    // любая ваша ссылка если используется TAmVclHookList то ссылка установится сама на wincontrol
    [weak]
    FListenObject: TObject;

    // handle прослущиваемго объекта
    FListenWindowHandle: Cardinal;

    // список сообщение о которых нужно сейчас получать события
    FListenMsgList: TList;

    // параметры куда пересылать сообщение
    FFromEnum: TAmWinHookFromEnum;
    FFromHandle: Cardinal;
    FFromMsg: Cardinal;
    FFromMsgProc: TAmWinHookEvent;
  protected
    property InternalListenMsgList: TList read FListenMsgList;
    function DeleteList(Source: TList; AList: TArray<Cardinal>)
      : boolean; virtual;
    function ListenMsgListGet: TList; virtual;
    procedure ListenObjectSet(const Value: TObject); virtual;
    procedure ListenWindowHandleSet(const Value: Cardinal); virtual;
  public
    constructor Create(AOwner: TAmWinHook); virtual;
    destructor Destroy; override;

    // его ID  счет идет не важно в каком он листе
    property Id: Cardinal read FId;

    // свободное поле
    property Prop: Pointer read FProp write FProp;

    /// ////////////////////////////////////////////////////////////
    // любая ваша ссылка если используется TAmVclHookList то ссылка установится сама на wincontrol
    property ListenObject: TObject read FListenObject write ListenObjectSet;
    // от кого  сообщение ишем
    property ListenWindowHandle: Cardinal read FListenWindowHandle
      write ListenWindowHandleSet;
    // список сообщений которые прослушиваем
    procedure ListenMsgAdd(AList: TArray<Cardinal>);
    function ListenMsgDelete(AList: TArray<Cardinal>): boolean;
    property ListenMsgList: TList read ListenMsgListGet;
    /// ///////////////////////////////////////////////////

    /// /////////////////////////////////////////////////////////////////
    // что делать когда нашли сообщение нужно PostMessage или SendMessage использовать или процедуру
    property FromEnum: TAmWinHookFromEnum read FFromEnum write FFromEnum;
    // куда отправить сообщение через Send...Post...Message
    property FromHandle: Cardinal read FFromHandle write FFromHandle;
    // какое отправить сообщение через Send...Post...Message
    property FromMsg: Cardinal read FFromMsg write FFromMsg;
    // процедура события если FromVariant = amwhProc
    property FromMsgProc: TAmWinHookEvent read FFromMsgProc write FFromMsgProc;
    /// ////////////////////////////////////////////////////////////////////

    // после настройки параметров запустить если остлеживаем только sendmessage то передать  amwinhookFromSend  если и send and post то ничего
    procedure Start; overload;
    procedure Start(Target: TAmWinHookFromEnum); overload;
    // временно останавливливает получение сообщений
    procedure Stop;
    property Started: boolean read FStarted;
  end;

  TAmWinHookListElement = class
  private
    FList: TList; // <TAmWinHookElement>
    FListEnumerator: TListEnumerator;
    procedure ClearAndFree;
    procedure AddMi(Elem: TAmWinHookElement);
    procedure RemoveMi(Elem: TAmWinHookElement);
    function CountGet: integer;
    function CountStartedGet: integer;
  protected
    function GetEnumerator: TListEnumerator;
  public
    property Count: integer read CountGet;
    property CountStarted: integer read CountStartedGet;
    constructor Create;
    destructor Destroy; override;
  end;

  TListEnumeratorHelper = class helper for TListEnumerator
    procedure Reset;
  end;

  // используется только для главного потока
  TAmWinHook = class
  private
    class var FMainThreadHook: TAmWinHook;
  var
    FLock: integer;
  protected
    class var CounterId: Cardinal;
    procedure RemoveMi(Elem: TAmWinHookElement);
    procedure AddMi(Elem: TAmWinHookElement);

    // WH_CALLWNDPROC используется для перехвата SendMessage оообщений
  var
    FSMList: TAmWinHookListElement;
    FSMHandle: HHook;
    procedure SMStart;
    procedure SMStop;

    // WH_GETMESSAGE используется для перехвата PostMessage оообщений
  var
    FPMList: TAmWinHookListElement;
    FPMHandle: HHook;
    procedure PMStart;
    procedure PMStop;

    procedure Stop_CheckZero;
    procedure Start_CheckZero;
  public
    class function NewElement(ACLass: TAmWinHookElementClass = nil) : TAmWinHookElement;
    property ListPost: TAmWinHookListElement read FPMList;
    property ListSend: TAmWinHookListElement read FSMList;
    class property MainThreadHook: TAmWinHook read FMainThreadHook;
    constructor Create;
    destructor Destroy; override;
  end;

  // help внешне не используются
  // SendMesssage
function AmWinHookSystemProc_CallWndProc(iNCode: integer; iWParam: WPARAM;
  iLParam: LPARAM): LRESULT; stdcall;
// PostMessage
function AmWinHookSystemProc_GetMessage(iNCode: integer; iWParam: WPARAM;
  iLParam: LPARAM): LRESULT; stdcall;

procedure AmWinHookProc_CommonEvent(isSend: boolean; Handle: LPARAM;
  List: TListEnumerator);

implementation
 resourcestring
    Rs_TAmWinHook_ChaningListInProgressExecuteEvent  = 'Error AmHookWinMsg.TAmWinHook.%s запрещено изменять лист элементов хуков во время выполнения цикла исполнения события AmHookWinMsg.AmWinHookProc_CommonEvent';


{ TListEnumeratorHelper }
procedure TListEnumeratorHelper.Reset;
begin
  with self do
    FIndex := -1;
end;

{ TAmWinHookList }

constructor TAmWinHookListElement.Create;
begin
  inherited;
  FList := TList.Create;
  FListEnumerator := TListEnumerator.Create(FList);
end;

destructor TAmWinHookListElement.Destroy;
begin
  ClearAndFree;
  FreeAndNil(FListEnumerator);
  FreeAndNil(FList);
  inherited;
end;

function TAmWinHookListElement.GetEnumerator: TListEnumerator;
begin
  Result := FListEnumerator;
  Result.Reset;
end;

Procedure TAmWinHookListElement.AddMi(Elem: TAmWinHookElement);
begin
  FList.Add(Elem);
end;

procedure TAmWinHookListElement.RemoveMi(Elem: TAmWinHookElement);
begin
  if FList.Count>0 then
  begin
    if FList.Last = Elem then
      FList.Delete(FList.Count - 1)
    else
      FList.Remove(Elem);
  end;
end;

Procedure TAmWinHookListElement.ClearAndFree;
var
  i: integer;
begin
  for i := FList.Count - 1 downto 0 do
    TObject(FList[i]).Free;
  FList.Clear;
end;

function TAmWinHookListElement.CountGet: integer;
begin
  Result := FList.Count;
end;

function TAmWinHookListElement.CountStartedGet: integer;
var
  i: integer;
begin
  Result := Count;
  if Result <= 0 then
    exit;
  for i := 0 to FList.Count - 1 do
    if TAmWinHookElement(FList[i]).Started then
      inc(Result);
end;

{ TAmWinHook }

constructor TAmWinHook.Create;
begin
  if FMainThreadHook <> nil then
    raise Exception.Create('Error  TAmWinHook.Create FMainThreadHook <> nil');
  if MainThreadId <> GetCurrentThreadId then
    raise Exception.Create
      ('Error TAmWinHook.Create  MainThreadId <> GetCurrentThreadId');

  inherited Create();
  CounterId := 0;
  FSMList := TAmWinHookListElement.Create;
  FSMHandle := 0;
  FPMList := TAmWinHookListElement.Create;
  FSMHandle := 0;
  FLock:=0;
end;

destructor TAmWinHook.Destroy;
begin
  SMStop;
  PMStop;
  FreeAndNil(FSMList);
  FreeAndNil(FPMList);
  inherited;
end;

Procedure TAmWinHook.PMStart;
begin
  if FPMHandle <> 0 then
    exit;
  FPMHandle := SetWindowsHookEx(WH_GETMESSAGE, AmWinHookSystemProc_GetMessage,
    0, GetCurrentThreadId); //
end;

Procedure TAmWinHook.PMStop;
begin
  if FPMHandle <> 0 then
    UnhookWIndowsHookEx(FPMHandle);
  FPMHandle := 0;
end;

Procedure TAmWinHook.SMStart;
begin
  if FSMHandle <> 0 then
    exit;
  FSMHandle := SetWindowsHookEx(WH_CALLWNDPROC, AmWinHookSystemProc_CallWndProc,
    0, GetCurrentThreadId); //
end;

Procedure TAmWinHook.SMStop;
begin
  if FSMHandle <> 0 then
    UnhookWIndowsHookEx(FSMHandle);
  FSMHandle := 0;
end;

procedure TAmWinHook.Stop_CheckZero;
begin
  if ListPost.CountStarted <= 0 then
    PMStop;
  if ListSend.CountStarted <= 0 then
    SMStop;
end;

procedure TAmWinHook.Start_CheckZero;
begin
  if ListPost.CountStarted > 0 then
    PMStart;
  if ListSend.CountStarted > 0 then
    SMStart;
end;

class function TAmWinHook.NewElement(ACLass: TAmWinHookElementClass = nil)
  : TAmWinHookElement;
begin
  if ACLass = nil then
    ACLass := TAmWinHookElement;
  Result := ACLass.Create(TAmWinHook.FMainThreadHook);
end;

procedure TAmWinHook.AddMi(Elem: TAmWinHookElement);
begin
  if FLock > 0 then
  raise Exception.CreateResFmt(@Rs_TAmWinHook_ChaningListInProgressExecuteEvent,['AddMi']);
  ListPost.AddMi(Elem);
  ListSend.AddMi(Elem);
end;

procedure TAmWinHook.RemoveMi(Elem: TAmWinHookElement);
begin
  if FLock > 0 then
  raise Exception.CreateResFmt(@Rs_TAmWinHook_ChaningListInProgressExecuteEvent,['RemoveMi']);
  if Assigned(ListPost) then
    ListPost.RemoveMi(Elem);
  if Assigned(ListSend) then
    ListSend.RemoveMi(Elem);
  Stop_CheckZero;
end;

{ TAmWinHookMessage }

function TAmWinHookMessage.HwdGet: HWND;
begin
  if FSendTyp then
    Result := Send.HWND
  else
    Result := Post.HWND;
end;

function TAmWinHookMessage.LPrmGet: LPARAM;
begin
  if FSendTyp then
    Result := Send.LPARAM
  else
    Result := Post.LPARAM;
end;

function TAmWinHookMessage.WPrmGet: WPARAM;
begin
  if FSendTyp then
    Result := Send.WPARAM
  else
    Result := Post.WPARAM;
end;

function TAmWinHookMessage.MessageGet: UINT;
begin
  if FSendTyp then
    Result := Send.Message
  else
    Result := Post.Message;
end;

function TAmWinHookMessage.MessageWinGet: TMessage;
begin
  Result.Msg := Message;
  Result.WPARAM := WPrm;
  Result.LPARAM := LPrm;
  Result.Result := 0;
end;

function TAmWinHookMessage.PostGet: PMsg;
begin
  Result := PMsg(FHandle);
end;

function TAmWinHookMessage.SendGet: PCWPStruct;
begin
  Result := PCWPStruct(FHandle);
end;

function TAmWinHookMessage.Struct: TCWPStruct;
begin
  if FSendTyp then
    Result := Send^
  else
  begin
    Result.LPARAM := Post.LPARAM;
    Result.WPARAM := Post.WPARAM;
    Result.Message := Post.Message;
    Result.HWND := Post.HWND;
  end;
end;

{ TElem }
constructor TAmWinHookElement.Create(AOwner: TAmWinHook);
begin
  if AOwner = nil then
    raise Exception.Create('Error TAmWinHookElement.Create AOwner =  nil ');
  if MainThreadId <> GetCurrentThreadId then
    raise Exception.Create
      ('Error TAmWinHookElement.Create  MainThreadId <> GetCurrentThreadId');
  inherited Create;
  FOwner := AOwner;
  ListenObject := nil;
  FId := AtomicIncrement(TAmWinHook.CounterId);
  FStarted := false;
  FillChar(FPrmMessage, sizeof(FPrmMessage), 0);
  FPrmMessage.FElement := self;
  FProp := nil;
  FListenObject := nil;
  FListenWindowHandle := 0;
  FListenMsgList := TList.Create;
  FFromEnum := amwinhookFromNone;
  FFromHandle := 0;
  FFromMsg := 0;
  FFromMsgProc := nil;

  FOwner.AddMi(self);

end;

destructor TAmWinHookElement.Destroy;
begin
  self.Stop;
  FOwner.RemoveMi(self);
  FPrmMessage.FElement := nil;
  FOwner := nil;
  FreeAndNil(FListenMsgList);
  FListenWindowHandle := 0;
  FFromHandle := 0;
  FFromMsg := 0;
  FFromMsgProc := nil;
  FListenObject := nil;
  FId := 0;
  FFromEnum := amwinhookFromNone;
  inherited;
end;

procedure TAmWinHookElement.ListenMsgAdd(AList: TArray<Cardinal>);
var
  L: TList;
  i: integer;
begin
  L := ListenMsgList;
  L.Capacity := max(L.Count + length(AList), L.Capacity);
  for i := 0 to length(AList) - 1 do
    L.Add(Pointer(AList[i]));
end;

function TAmWinHookElement.ListenMsgDelete(AList: TArray<Cardinal>): boolean;
begin
  Result := DeleteList(ListenMsgList, AList)
end;

function TAmWinHookElement.DeleteList(Source: TList;
  AList: TArray<Cardinal>): boolean;
var
  i, x: integer;
begin
  if (length(AList) = 1) and (AList[0] = 0) then
    Source.Clear;
  for i := 0 to length(AList) - 1 do
  begin
    while True do
    begin
      x := Source.IndexOf(Pointer(AList[i]));
      if x >= 0 then
        Source.Delete(x)
      else
        break;
    end;
  end;
  Result := Source.Count = 0;
end;

function TAmWinHookElement.ListenMsgListGet: TList;
begin
  Result := FListenMsgList;
end;

procedure TAmWinHookElement.ListenObjectSet(const Value: TObject);
begin
  FListenObject := Value;
end;

procedure TAmWinHookElement.ListenWindowHandleSet(const Value: Cardinal);
begin
  FListenWindowHandle := Value;
end;

procedure TAmWinHookElement.Start;
begin
  Start(amwinhookFromNone);
end;

procedure TAmWinHookElement.Start(Target: TAmWinHookFromEnum);
begin

  FStarted := True;
  case Target of
    amwinhookFromPost:
      FOwner.ListSend.RemoveMi(self);
    amwinhookFromSend:
      FOwner.ListPost.RemoveMi(self);
  end;
  FOwner.Start_CheckZero;
end;

procedure TAmWinHookElement.Stop;
begin
  FStarted := false;
  FOwner.Stop_CheckZero;
end;

// PostMessage
function AmWinHookSystemProc_GetMessage(iNCode: integer; iWParam: WPARAM;
  iLParam: LPARAM): LRESULT; stdcall;
begin
  Result := Winapi.Windows.CallNextHookEx(TAmWinHook.FMainThreadHook.FPMHandle,
    iNCode, iWParam, iLParam);
  if iNCode = HC_ACTION then
  begin
     inc(TAmWinHook.FMainThreadHook.FLock);
     try
        AmWinHookProc_CommonEvent(False, iLParam,
          TAmWinHook.FMainThreadHook.FPMList.GetEnumerator);
     finally
       dec(TAmWinHook.FMainThreadHook.FLock);
     end;
  end;
end;

// SendMessage
function AmWinHookSystemProc_CallWndProc(iNCode: integer; iWParam: WPARAM;
  iLParam: LPARAM): LRESULT; stdcall;
begin
  Result := Winapi.Windows.CallNextHookEx(TAmWinHook.FMainThreadHook.FSMHandle,
    iNCode, iWParam, iLParam);
  if iNCode = HC_ACTION then
  begin
     inc(TAmWinHook.FMainThreadHook.FLock);
     try
      AmWinHookProc_CommonEvent(True, iLParam,
        TAmWinHook.FMainThreadHook.FSMList.GetEnumerator);
     finally
       dec(TAmWinHook.FMainThreadHook.FLock);
     end;
  end;
end;

procedure AmWinHookProc_CommonEvent(isSend: boolean; Handle: LPARAM; List: TListEnumerator);
var
  Elem: TAmWinHookElement;
  LHandle: LPARAM;
begin
  if (Handle = 0) or not Assigned(List) then
    exit;

  while List.MoveNext do
  begin
    LHandle := Handle;
    Elem := TAmWinHookElement(List.Current);
    // Pointer должен быть TAmWinHookElement
    if not Assigned(Elem) or not Elem.Started then
      continue;

    if isSend then
    begin
      if (Elem.FListenWindowHandle <> 0) and
        (Elem.FListenWindowHandle <> PCWPStruct(LHandle).HWND) then
        LHandle := 0
      else if (Elem.FListenMsgList.IndexOf(Pointer(0)) < 0) and
        (Elem.FListenMsgList.IndexOf(Pointer(PCWPStruct(LHandle).Message)) < 0) then
        LHandle := 0;
    end
    else
    begin
      if (Elem.FListenWindowHandle <> 0) and
        (Elem.FListenWindowHandle <> PMsg(LHandle).HWND) then
        LHandle := 0
      else if (Elem.FListenMsgList.IndexOf(Pointer(0)) < 0) and
        (Elem.FListenMsgList.IndexOf(Pointer(PMsg(LHandle).Message)) < 0) then
        LHandle := 0;
    end;
    if LHandle = 0 then
      continue;
    // amwinhookFromPost,amwinhookFromSend,amwinhookFromProc
    Elem.FPrmMessage.FSendTyp := isSend;
    case Elem.FromEnum of
      amwinhookFromPost:
        begin
          if isSend then
            PostMessage(Elem.FromHandle, Elem.FromMsg,
              PCWPStruct(LHandle).Message, 0)
          else
            PostMessage(Elem.FromHandle, Elem.FromMsg,
              PMsg(LHandle).Message, 0);
        end;
      amwinhookFromSend:
        begin
          Elem.FPrmMessage.FHandle := Pointer(LHandle);
          SendMessage(Elem.FromHandle, Elem.FromMsg, 0,
            LPARAM(@Elem.FPrmMessage));
          if Assigned(Elem) and (Elem.FId > 0) and
            (Elem.FPrmMessage.FHandle <> nil) then
            Elem.FPrmMessage.FHandle := nil;
        end;
      amwinhookFromProc:
        begin
          if not Assigned(Elem.FromMsgProc) then
            continue;
          Elem.FPrmMessage.FHandle := Pointer(LHandle);
          Elem.FromMsgProc(@Elem.FPrmMessage);
          if Assigned(Elem) and (Elem.FId > 0) and
            (Elem.FPrmMessage.FHandle <> nil) then
            Elem.FPrmMessage.FHandle := nil;
        end;
    end;
  end;
end;

initialization
begin
  TAmWinHook.FMainThreadHook := nil;
  TAmWinHook.FMainThreadHook := TAmWinHook.Create;
end;

finalization
begin
  FreeAndNil(TAmWinHook.FMainThreadHook);
end;

end.
