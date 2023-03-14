unit AmHookWin;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,Types,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, System.SyncObjs,
  IOUtils,AmSystemObject,System.Generics.Collections;



  {
    смысл модуля перехватить сообщения windows которые отправляются другому окну или обхекту
    также смотрите еще один модуль AmHookVcl там любые события можно получить здесь только что явно через postmessage sendmessage отправляются

    опищу 1 вариант использования

    вешаем Tdit


    procedure TForm8.FormCreate(Sender: TObject);
    begin
     L:=TAmVclHookList.Create;
     L.OnNewMessage:= Msg;
     L.AddHook(Edit1,[CM_ENTER,CM_EXIT]);   // подключаемся к событию когда edit1 получает фокус ввода и пропадает фокус
     L.AddHook(Edit2,[CM_ENTER,CM_EXIT]);
    end;
    procedure TForm8.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    begin
      FreeAndNil(L);
    end;
    procedure TForm8.Msg(SenderList: TObject; Prm: PAmWinHookPrm);
    begin
      if self.Showing then
      begin
           if Prm.Elem.ListenObject is TComponent then
           case Prm.Message of
                   CM_ENTER:  Memo1.Lines.Add('Сейчас установится фокус на '+TComponent(Prm.Elem.ListenObject).Name);
                   CM_EXIT:   Memo1.Lines.Add('Сейчас удалится фокус с '+TComponent(Prm.Elem.ListenObject).Name);
                   WM_PAINT:  Memo1.Lines.Add('Рисуем '+TComponent(Prm.Elem.ListenObject).Name);
           end;
      end;
    end;
    procedure TForm8.Button3Click(Sender: TObject);
    begin
      L.AddHook(edit1,[WM_PAINT])
    end;
    procedure TForm8.Button3Click(Sender: TObject);
    begin
      L.DeleteHook(edit1,[CM_ENTER])
    end;
    procedure TForm8.Button3Click(Sender: TObject);
    begin
      L.DeleteHook(edit1,[WM_PAINT])
    end;
    procedure TForm8.Button3Click(Sender: TObject);
    begin
      L.DeleteHook(edit1,[0])// все удалить
    end;

    // 2й вариант использования

          procedure TForm1.Button2Click(Sender: TObject);
          var Elem:TAmWinHookElem;
          begin
              Elem:=  AmHook.New;
              Elem.WinMsg:= wm_user;
              Elem.WinHandle:= Form1.Edit1.Handle;
              Elem.ExpVariant:=amwhProc;
              Elem.FromHandle:= Form1.Handle ;
              Elem.FromMsg:=   wm_user+1;
              Elem.FromMsgProc:= Test;
              Elem.Start();

              // Elem должен удалится вместе с объектом который принемает хуки
              здесь это Form1
              т.е в FormClose .. Destroy нужно удалить  Elem.free;
              можно и не удалять тогда он будет висить и пытатся обрабатывать сообщения (бесполезная работа) и отсылать сообщения не существующему окну
              а если вы подключали процедуру как хук TAmWinHookEnum.amwhProc
              то возникнет исключение
              т.к объекта формы уже нет а хуки пытаются вызвать процедуру удаленного объекта
          end;

          // после установки хука кликаем тестируем
          procedure TForm1.Button3Click(Sender: TObject);
          begin
             POstMessage(Edit1.Handle,wm_user,0,0);
             //or
             SendMessage(Edit1.Handle,wm_user,0,0);
             //т.е отпаравляем команду окну Edit1 сообщение wm_user
          end;

          создаем процедуру на форме
            type TForm1 =class.....
            //...    в эти процедуры придут сообщения когда мы отправили сообщения wm_user в  Edit1
            private
              procedure WM1(var M:Tmessage);message wm_user+1; // в эту придет когда  TAmWinHookElem.FromVariant:=amwhSend
              procedure Test(var Param:TAmWinHookParam);       // в эту придет когда  TAmWinHookElem.FromVariant:=amwhProc
            //....

            // обработка сообщения на форме которое было отравлено в edit
            // в edit сообщение дойдет без доп кода если TAmWinHookParam не исправлять
          procedure TForm1.WM1(var M:Tmessage);
          var  Param:PAmWinHookParam;
          begin
             if M.LParam<>0 then
             begin
               //сюда код зайдет если  TAmWinHookElem.ExpVariant:=amwhSend
               Param:= PAmWinHookParam(M.LParam);
               Form1.Memo1.Lines.Add('WM1 '+Param.Elem.Fid.ToString);
             end
             else Form1.Memo1.Lines.Add('WM1 '); //сюда код зайдет если  TAmWinHookElem.ExpVariant:=amwhPost
          end;
          procedure TForm1.Test(var Param:TAmWinHookParam);
          begin
             //сюда код зайдет если  TAmWinHookElem.ExpVariant:=amwhProc
             Form1.Memo1.Lines.Add('Form1='+inttostr(Form1.Handle)+' '+amstr(Param.Elem.Fid));
          end;
          // т.е мы получили уведомление в классе TForm1 что окну Edit1 было отослоно сообщение wm_user
          //которое мы назначили прехватить когда запускали Hook  Elem.WinMsg:= wm_user;
          // это покажется дибильным зачем огород городить если мы сами это сообщение отравили
          // но фишка в том что такое сообщение может и сама Windows отправить или любой другой клас
          //или др программа и что бы это узнать огород нам и поможет
          // это работает для любых окон с любого места на компе(есть исключения)
          // так же сообщение можно изменить или перенапривить что бы  Edit1 вообще его не получил
          // в частности я модуль написал что узнать когда в пользователь просмотрел сообщение от другого пользоватля в минимессанджере

          // p/s лучше всего из тестов показал себя вариант через SendMessage  в самои конце модуля пример использования
    берем переменную AmHook которая уже создана смотрим к какому она классу принадлежит смотрим эьль класс и начинаем понимать как пользоватся
    AmHook использовать только в одном потоке или применять любую синхронизацию
    лучше всего использовать только в главном потоке приложения тогда проблем будет меньше


  }


 type
  TAmWinHookEnum= (amwhPost,amwhSend,amwhProc,amwhNone);//что делать когда нашли сообщение   amwhSend оптимальный вариант

  TAmWinHookElem  = class;
  TAmWinHookList  = class;
  TAmWinHook      = class;// глобал 1 экземпляр в для главного потока приложения
  TAmMsgHookList  = class;// создаем и используем для всех объектов
  TAmVclHookList  = class;// создаем и используем для TWinControl также обрабатывает WM_CREATE WM_DESTROY что бы обновлять handle

  //используется когда наступило сообытие что бы отправить и получить все параметры сообщения когда сообщение перехвачено
  // если  использовать FromMsgProc:TAmWinHookEvent она отправляется  как параметр var процедура при удалении объектов теряется и иногда ошибки вылетают
  // если  использовать SendMessage   она отправляется в lparam   самый лучший вариант  if Msg.LParam<>0 then Param:= PAmWinHookPrm(Msg.LParam)
  // если  использовать PostMessage   lparam=0
  PAmWinHookPrm   = ^TAmWinHookPrm;
  TAmWinHookPrm = record
   private
    FSendTyp:boolean;
    FHandle:Pointer;
    function PostGet: PMsg;
    function SendGet: PCWPStruct;
    function Struct: TCWPStruct;
    function HwdGet: HWND;
    function LPrmGet: LPARAM;
    function MessageGet: UINT;
    function WPrmGet: WPARAM;
    function MessageWinGet: TMessage;
   public
    [weak]Elem:TAmWinHookElem;  // ссылка на объект настроек
    // если  SendTyp = true то обрашатся к  Send   т.е TAmWinHookPrm.Send....
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




  //процедура события когда найдено искомое сообщение
  TAmWinHookEvent = procedure (Prm:PAmWinHookPrm) of object;


  TAmWinHookElemClass = class of TAmWinHookElem;

  TAmWinHookElem = class {это один элемент (то сообщение которое нужно перехватить и что с ним делать)}
     private
      FId:Cardinal;// глобальный id
      [weak]FOwner:TAmWinHook;
      FStarted:boolean;// состояние запушен ли перехрат у этого элемента
      Prm:TAmWinHookPrm;// испозуется для оправки аргумента при событии
      FProp:Pointer;
      [weak]FListenObject:TObject; // любая ваша ссылка если используется TAmVclHookList то ссылка установится сама на wincontrol
      FListenWindowHandle:Cardinal; // handle прослущиваемго объекта
      FLMsg:TList<Cardinal>;// список сообщение о которых нужно сейчас получать события
      FFromVariant: TAmWinHookEnum;
      FFromHandle:Cardinal;
      FFromMsg:Cardinal;
      FFromMsgProc:TAmWinHookEvent;
     protected
      property InternalListMsg: TList<Cardinal> read FLMsg;
      function DeleteList(Source:TList<Cardinal>;AList:TArray<Cardinal>):boolean;  virtual;
      function ListenMsgListGet:  TList<Cardinal>;  virtual;
      procedure ListenObjectSet(const Value: TObject); virtual;
      procedure ListenWindowHandleSet(const Value: Cardinal);  virtual;
     public

      // его ID  счет идет не важно в каком он листе присваевается когда   TAmWinHookElem.Create
      property Id: Cardinal read FId;
      constructor Create(AOwner:TAmWinHook);virtual;
      destructor Destroy; override;
      // свободное поле
      property Prop: Pointer read FProp write FProp;


      ///////////////////////////////////////////////////////////////
      // любая ваша ссылка если используется TAmVclHookList то ссылка установится сама на wincontrol
      property ListenObject:TObject read FListenObject write ListenObjectSet;
       //от кого  сообщение ишем
      property ListenWindowHandle: Cardinal read FListenWindowHandle write ListenWindowHandleSet;
      // список сообщений которые прослушиваем
      procedure ListenMsgAdd(AList:TArray<Cardinal>);
      function ListenMsgDelete(AList:TArray<Cardinal>):boolean;
      property  ListenMsgList: TList<Cardinal> read ListenMsgListGet;
      //////////////////////////////////////////////////////

      ////////////////////////////////////////////////////////////////////
      //что делать когда нашли сообщение нужно PostMessage или SendMessage использовать или процедуру
      property FromVariant: TAmWinHookEnum read FFromVariant write FFromVariant;
      //куда отправить сообщение через Send...Post...Message
      property FromHandle: Cardinal read FFromHandle write FFromHandle;
      //какое отправить сообщение через Send...Post...Message
      property FromMsg: Cardinal read FFromMsg write FFromMsg;
      //процедура события если FromVariant = amwhProc
      property FromMsgProc: TAmWinHookEvent read FFromMsgProc write FFromMsgProc;
      ///////////////////////////////////////////////////////////////////////

      // после настройки параметров запустить если остлеживаем только sendmessage то передать  amwhSend  если и send and post то ничего
      procedure Start(Target:TAmWinHookEnum=amwhNone);
      // временно останавливливает получение сообщений
      procedure Stop;
      property Started: boolean read FStarted;
  end;

  // основан на классе TList и размещает в себе список классов TAmWinHookElem
  TAmWinHookList  =  class
   private
     FLockClear:integer;
   protected
     List:TList;//<TAmWinHookElem>
     function GetItem(index:integer):TAmWinHookElem;
     function GetCount:integer;
     procedure RemoveMi(Elem:TAmWinHookElem);
     procedure AddMi(Elem:TAmWinHookElem);
   public
     function SerchIndexId(Id:Cardinal):integer;
     procedure ClearAndFree;
     property  Items[index:integer]:TAmWinHookElem read GetItem; default;
     property  Count:integer read GetCount;
     constructor Create;
     destructor Destroy; override;
  end;

  TAmWinHook  =  class  //запрещено создавать больше 1 эксемпляра есть готовая переменная AmHook
   protected
     IsGo_CALLWNDPROC,IsGo_GETMESSAGE:boolean;
     CounterId:Cardinal;
     procedure RemoveMi(Elem:TAmWinHookElem);
     procedure AddMi(Elem:TAmWinHookElem);

     {AmHook сам создается  ждет Start сам удаляется }
     {List поместить все сообщения которые нужно перехватывать}
     {Handle обычно не трогается}
     {Start запустить перехват}
     {Stop  выполнится само в Destroy}


     {WH_CALLWNDPROC используется для перехвата SendMessage оообщений}
     var         List_CALLWNDPROC:TAmWinHookList;
               Handle_CALLWNDPROC:HHOOK;
     Procedure  Start_CALLWNDPROC;
     Procedure   Stop_CALLWNDPROC;


     {WH_GETMESSAGE используется для перехвата PostMessage оообщений}
     var         List_GETMESSAGE:TAmWinHookList;
               Handle_GETMESSAGE:HHOOK;
     Procedure  Start_GETMESSAGE;
     Procedure   Stop_GETMESSAGE;


     procedure Stop_CheckZero;
     procedure Start_CheckZero;
   public
   // основа
    function New(ACLass:TAmWinHookElemClass=nil) : TAmWinHookElem;
   // help
    Procedure Delete(Elem:TAmWinHookElem);  // если перехратывать стало не нужно то можно просто удалить  TAmWinHookElem.Free;
    property ListPost: TAmWinHookList read List_GETMESSAGE;
    property ListSend: TAmWinHookList read List_CALLWNDPROC;
    constructor Create;
    destructor Destroy; override;
  end;

  TAmWinHookListEvent = procedure (SenderList:TObject;Prm:PAmWinHookPrm) of object;





  // использовать этот лист что бы получить хуки

  TAmMsgHookElem = class (TAmWinHookElem)
   private
    FLocalList: TAmMsgHookList;
  public
    constructor Create(AOwner:TAmWinHook);override;
    destructor Destroy; override;
  end;
  TAmMsgHookList =class (TAmHandleObject)
   private
    const WM_HOOK= wm_user+1028;
    var FListElem:TList<TAmWinHookElem>;
    FOnNewMessage:TAmWinHookListEvent;
    procedure NewSendHook(var Msg:Tmessage);  message WM_HOOK;
   protected
    function NewMessageHook(Prm:PAmWinHookPrm):Cardinal; virtual;
    function SerchHook(HandleControl,MsgForControl:Cardinal;ListenObject:TObject;out IndexElem,IndexMsg:integer):boolean;
    function AddHookCust(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil):TAmWinHookElem;
   public
    property List: TList<TAmWinHookElem> read FListElem;
    class function GetClassElem:TAmWinHookElemClass;  virtual;
    function AddHook(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil):TAmWinHookElem; overload;
    procedure DeleteHook(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil); overload;
    procedure DeleteHook(ListenObject:TObject; MsgForControl:TArray<Cardinal>);  overload;
    procedure ClearHook;
    constructor Create;
    destructor Destroy; override;
    property OnNewMessage: TAmWinHookListEvent read FOnNewMessage write FOnNewMessage;
  end;





 PWinControl = ^TWinControl;

  // использовать этот лист что бы получить хуки для TWinControl
  // работая с WinControl поммни что их handle может менятся со времянем
  // этот класс решает эту проблему если указан   ListenObject
 TAmVclHookElem = class (TAmMsgHookElem)
  private
    ListMsgSaved:TList<Cardinal>;
    AutoAdd_Msg_Create,
    AutoAdd_Msg_Destroy:boolean;
    ListenPointer:PWinControl;
//    ListenPointerValue:TWinControl;
    procedure SaveList;
    procedure ResetList;
  protected
    procedure ClenerWinControl;
    function DeleteList(Source:TList<Cardinal>;AList:TArray<Cardinal>):boolean;  override;
    function ListenMsgListGet:  TList<Cardinal>;  override;
    procedure ListenObjectSet(const Value: TObject);     override;
    procedure ListenWindowHandleSet(const Value: Cardinal);   override;
  public
    constructor Create(AOwner:TAmWinHook);override;
    destructor Destroy; override;
 end;
 TAmVclHookList = class(TAmMsgHookList)
   protected
    function NewMessageHook(Prm:PAmWinHookPrm):Cardinal; override;
   public
    class function GetClassElem:TAmWinHookElemClass; override;
    function AddHook(ListenObject:TWinControl;MsgForControl:TArray<Cardinal>):TAmWinHookElem;
    procedure DeleteHook(ListenObject:TWinControl;MsgForControl:TArray<Cardinal>);
    //AddHookLink
    // если объект постоянно пересоздается но перемнная которая хранит на него ссылку
    // будет доступна как минимум до разрушения self
    //то можно передать ссылку на переменную как  AddHookLink(@Edit1,[MyMSG])
    // но при удалении  Edit1.Free; или любом другом удалении
    // переменная var Edit1:TEdit; станет равна nil
    function AddHookLink(ListenPointer:PWinControl;MsgForControl:TArray<Cardinal>):TAmWinHookElem;

 end;





  // help внешне не используются
  function AmWinHookProc_CALLWNDPROC(  iNCode: Integer; iWParam: WPARAM; iLParam: LPARAM): LRESULT; stdcall;
  function AmWinHookProc_GETMESSAGE(  iNCode: Integer; iWParam: WPARAM; iLParam: LPARAM): LRESULT; stdcall;
  procedure AmWinHookProc_Event(isSend:boolean;Handle:LPARAM;List:TAmWinHookList);
  // переменная используется для главного потока приложения
 var AmHook:TAmWinHook;
implementation




               {TAmWinHook}

constructor TAmWinHook.Create;
begin
    inherited Create();
    CounterId:=0;
    List_CALLWNDPROC:=  TAmWinHookList.Create;
    IsGo_CALLWNDPROC:=false;
    Handle_CALLWNDPROC:=0;

    List_GETMESSAGE:=   TAmWinHookList.Create;
    IsGo_GETMESSAGE:=false;
    Handle_GETMESSAGE:=0;
end;

destructor TAmWinHook.Destroy;
begin
    Stop_CALLWNDPROC;
    Stop_GETMESSAGE;
    List_CALLWNDPROC.ClearAndFree;
    List_GETMESSAGE.ClearAndFree;
    FreeAndNil(List_CALLWNDPROC);
    FreeAndNil(List_GETMESSAGE);
    inherited;
end;

Procedure  TAmWinHook.Start_GETMESSAGE;
begin
  if IsGo_GETMESSAGE then exit;
  Handle_GETMESSAGE :=   SetWindowsHookEx( WH_GETMESSAGE , AmWinHookProc_GETMESSAGE, 0, GetCurrentThreadID); //
  IsGo_GETMESSAGE:=Handle_GETMESSAGE<>0;
end;
Procedure   TAmWinHook.Stop_GETMESSAGE;
begin
    if IsGo_GETMESSAGE then      
    UnhookWIndowsHookEx(Handle_GETMESSAGE);
    Handle_GETMESSAGE:=0;
    IsGo_GETMESSAGE:=false;
end;

Procedure TAmWinHook.Start_CALLWNDPROC;
begin
  if IsGo_CALLWNDPROC then exit;
  Handle_CALLWNDPROC :=   SetWindowsHookEx( WH_CALLWNDPROC , AmWinHookProc_CALLWNDPROC, 0, GetCurrentThreadID); //
  IsGo_CALLWNDPROC:=Handle_CALLWNDPROC<>0;
end;
Procedure TAmWinHook.Stop_CALLWNDPROC;
begin
    if IsGo_CALLWNDPROC then
    UnhookWIndowsHookEx(Handle_CALLWNDPROC);
    IsGo_CALLWNDPROC:=false;
    Handle_CALLWNDPROC:=0;
end;
procedure TAmWinHook.Stop_CheckZero;
begin
  if ListPost.Count<=0 then
  Stop_GETMESSAGE;
  if ListSend.Count<=0 then
  Stop_CALLWNDPROC;
end;
procedure TAmWinHook.Start_CheckZero;
begin
  if ListPost.Count>0 then
  Start_GETMESSAGE;
  if ListSend.Count>0 then
  Start_CALLWNDPROC;
end;

function TAmWinHook.New(ACLass:TAmWinHookElemClass=nil): TAmWinHookElem;
begin
   if ACLass=nil then
   ACLass:= TAmWinHookElem;
   Result:=ACLass.Create(self);
end;
procedure TAmWinHook.Delete(Elem: TAmWinHookElem);
begin
   if Assigned(Elem) then
   FreeAndNil(Elem);
end;
procedure TAmWinHook.AddMi(Elem: TAmWinHookElem);
begin
   ListPost.AddMi(Elem);
   ListSend.AddMi(Elem);
end;
procedure TAmWinHook.RemoveMi(Elem: TAmWinHookElem);
begin
   if Assigned(ListPost) then    
   ListPost.RemoveMi(Elem);
   if Assigned(ListSend) then
   ListSend.RemoveMi(Elem);
   Stop_CheckZero;
end;




{TElem}
constructor TAmWinHookElem.Create(AOwner:TAmWinHook);
begin
   inherited Create;
   FOwner:= AOwner;
   ListenObject:=nil;
   inc(FOwner.CounterId);
   Fid:=FOwner.CounterId;
   FStarted:=false;
   FillChar(Prm,sizeof(Prm),0);
   FProp:=nil;
   Prm.Elem:=self;
   FListenObject:=nil;
   FLMsg:=TList<Cardinal>.create;
   FListenWindowHandle:=0;
   FromHandle:=0;
   FromMsg:=0;
   FromMsgProc:=nil;
   FromVariant:=amwhNone;
   FOwner.AddMi(self);
end;
destructor TAmWinHookElem.Destroy;
begin
    self.Stop;
    FOwner.RemoveMi(self);
    FOwner:=nil;
    FreeAndNil(FLMsg);
    FListenWindowHandle:=0;
    FromHandle:=0;
    FromMsg:=0;
    FromMsgProc:=nil;
    ListenObject:=nil;
    Fid:=0;
    FromVariant:=amwhNone;
    inherited;
end;
procedure TAmWinHookElem.ListenMsgAdd(AList: TArray<Cardinal>);
begin
  ListenMsgList.AddRange(AList);
end;

function TAmWinHookElem.ListenMsgDelete(AList: TArray<Cardinal>): boolean;
begin
  Result:= DeleteList(ListenMsgList,AList)
end;

function TAmWinHookElem.ListenMsgListGet: TList<Cardinal>;
begin
  Result:= FLMsg;
end;

procedure TAmWinHookElem.ListenObjectSet(const Value: TObject);
begin
  FListenObject := Value;
end;

procedure TAmWinHookElem.ListenWindowHandleSet(const Value: Cardinal);
begin
  FListenWindowHandle := Value;
end;

function TAmWinHookElem.DeleteList(Source:TList<Cardinal>;AList:TArray<Cardinal>):boolean;
var i,x:integer;
begin
   if (length(AList) = 1) and (AList[0] =0) then
   Source.clear;
   for I := 0 to length(AList)-1 do
   begin
      while True do
      begin
        x:=Source.IndexOf(AList[I]);
        if x>=0 then
        Source.Delete(x)
        else break;
      end;
   end;
   Result:= Source.Count = 0;
end;


procedure TAmWinHookElem.Start(Target:TAmWinHookEnum=amwhNone);
begin
  FStarted:=true;
  case Target of
      amwhPost: FOwner.ListSend.RemoveMi(self);
      amwhSend : FOwner.ListPost.RemoveMi(self);
  end;
  FOwner.Start_CheckZero;
end;

procedure TAmWinHookElem.Stop;
begin
  FStarted:=false;
end;


{TAmWinHookList}

constructor TAmWinHookList.Create;
begin
   inherited ;
   List:= Tlist.Create;
   FLockClear:=0;
end;
destructor TAmWinHookList.Destroy;
begin
    ClearAndFree;
    FreeAndNil(List);
    inherited;
end;
function TAmWinHookList.SerchIndexId(Id:Cardinal):integer;
var i:integer;
begin
     Result:=-1;
    for I := 0 to List.Count-1 do
     if TAmWinHookElem(List[I]).Fid = Id then
     begin
       Result:=i;
       break;
     end;
end;
Procedure TAmWinHookList.AddMi(Elem:TAmWinHookElem);
begin
   List.add(Elem);
end;
Procedure TAmWinHookList.ClearAndFree;
var i:integer;
Elem:TAmWinHookElem;
begin
  inc(FLockClear);
  try
    for I := List.Count-1 downto 0 do
    begin
         Elem:=TObject(List[I]) as TAmWinHookElem;
         List.Delete(I);
         if Assigned(Elem) then
         FreeAndNil(Elem);
    end;
    List.Clear;
  finally
    dec(FLockClear);
  end;
end;

function TAmWinHookList.GetItem(index:integer):TAmWinHookElem;
begin
   if (index>=0) and (index<List.Count) then
   Result:= TObject(List[Index]) as TAmWinHookElem
   else  Result:=nil;
end;
procedure TAmWinHookList.RemoveMi(Elem: TAmWinHookElem);
begin
  if FLockClear>0 then exit;
  List.Remove(Elem);
end;

function TAmWinHookList.GetCount:integer;
begin
   Result:=List.Count;
end;







function AmWinHookProc_GETMESSAGE(  iNCode: Integer; iWParam: WPARAM; iLParam: LPARAM): LRESULT; stdcall;
begin
 Result := CallNextHookEx(AmHook.Handle_GETMESSAGE, iNCode, iWParam, iLParam);
 if iNCode=HC_ACTION then
   AmWinHookProc_Event(false,iLParam,AmHook.List_GETMESSAGE);
end;
function AmWinHookProc_CALLWNDPROC(  iNCode: Integer; iWParam: WPARAM; iLParam: LPARAM): LRESULT;
begin
 Result := CallNextHookEx(AmHook.Handle_CALLWNDPROC, iNCode, iWParam, iLParam);
 if iNCode=HC_ACTION then
   AmWinHookProc_Event(true,iLParam,AmHook.List_CALLWNDPROC);
end;
procedure AmWinHookProc_Event(isSend:boolean;Handle:LPARAM;List:TAmWinHookList);
var I:integer;
   Elem:TAmWinHookElem;
   LHandle:LPARAM;
begin
     if (Handle<>0) and Assigned(List) then
     for I := List.Count-1 downto 0 do
     begin
      //  if  Pmsg(Handle).Message = WM_CREATE then
        // Handle:= Handle;
         LHandle:= Handle;
         Elem:= List[i];
         if Assigned(Elem) and Elem.Started then
         begin

              

              if isSend then
              begin

                 { if (HDEDIT = Elem.FListenWindowHandle) and (Elem.FListenWindowHandle = PCWPStruct(LHandle).hwnd)
                  and (Elem.FLMsg.IndexOf(PCWPStruct(LHandle).Message)>=0) then
                  HDEDIT:= HDEDIT;
                  }

                if (Elem.FListenWindowHandle <> 0) and (Elem.FListenWindowHandle <> PCWPStruct(LHandle).hwnd) then
                  LHandle:=0
                else if (Elem.FLMsg.IndexOf(0) < 0) and (Elem.FLMsg.IndexOf(PCWPStruct(LHandle).Message)<0)  then
                  LHandle:=0;
              end
              else
              begin
                if (Elem.FListenWindowHandle <> 0) and (Elem.FListenWindowHandle <> Pmsg(LHandle).hwnd) then
                  LHandle:=0
                else if (Elem.FLMsg.IndexOf(0) < 0) and (Elem.FLMsg.IndexOf(Pmsg(LHandle).Message)<0)  then
                  LHandle:=0;
              end;
              if LHandle<>0 then
              begin
                  Elem.Prm.FSendTyp:=isSend;
                  case Elem.FromVariant of
                      amwhPost:begin

                            if isSend then PostMessage(Elem.FromHandle,Elem.FromMsg,PCWPStruct(LHandle).message,0)
                            else           PostMessage(Elem.FromHandle,Elem.FromMsg,Pmsg(LHandle).message,0);
                      end;

                      amwhSend: begin
                           Elem.Prm.FHandle:= Pointer(LHandle);
                           SendMessage(Elem.FromHandle,Elem.FromMsg,0,Lparam(@Elem.Prm));
                           if Assigned(Elem) and (Elem.FId>0) and  (Elem.Prm.FHandle<>nil) then
                           Elem.Prm.FHandle:=nil;
                      end;
                      amwhProc: begin
                         if Assigned(Elem.FromMsgProc) then
                         begin
                           Elem.Prm.FHandle:= Pointer(LHandle);
                           Elem.FromMsgProc(@Elem.Prm);
                           if Assigned(Elem) and (Elem.FId>0) and  (Elem.Prm.FHandle<>nil) then
                           Elem.Prm.FHandle:=nil;
                         end;
                      end;
                  end;
              end;
         end;
     end;
end;

{ TAmWinHookPrm }

function TAmWinHookPrm.HwdGet: HWND;
begin
   if FSendTyp then Result:= Send.hwnd
   else Result:= Post.hwnd;
end;

function TAmWinHookPrm.LPrmGet: LPARAM;
begin
   if FSendTyp then Result:= Send.lParam
   else Result:= Post.lParam;
end;

function TAmWinHookPrm.WPrmGet: WPARAM;
begin
   if FSendTyp then Result:= Send.wParam
   else Result:= Post.wParam;
end;

function TAmWinHookPrm.MessageGet: UINT;
begin
   if FSendTyp then Result:= Send.Message
   else Result:= Post.Message;
end;

function TAmWinHookPrm.MessageWinGet: TMessage;
begin
    Result.Msg:=Message;
    Result.WParam:= WPrm;
    Result.LParam:= LPrm;
    Result.Result:=  0;
end;

function TAmWinHookPrm.PostGet: PMsg;
begin
  Result:= PMsg(FHandle);
end;

function TAmWinHookPrm.SendGet: PCWPStruct;
begin
  Result:= PCWPStruct(FHandle);
end;

function TAmWinHookPrm.Struct: TCWPStruct;
begin
   if FSendTyp then Result:= Send^
   else
   begin
     Result.lParam:=  Post.lParam;
     Result.wParam:=  Post.wParam;
     Result.message:= Post.message;
     Result.hwnd:=    Post.hwnd;
   end;
end;


{ TAmMsgHookItem }

constructor TAmMsgHookElem.Create(AOwner: TAmWinHook);
begin
   inherited;
    FLocalList:=nil;
end;

destructor TAmMsgHookElem.Destroy;
begin
   if Assigned(FLocalList) then
   FLocalList.FListElem.Remove(self);
   FLocalList:=nil;
  inherited;
end;
{ TAmMsgHookList }

constructor TAmMsgHookList.Create;
begin
  inherited Create;
  FListElem:=TList<TAmWinHookElem>.Create;
end;

destructor TAmMsgHookList.Destroy;
begin
  ClearHook;
  FreeAndNil(FListElem);
  inherited;
end;

class function TAmMsgHookList.GetClassElem: TAmWinHookElemClass;
begin
 Result:= TAmMsgHookElem;
end;

procedure TAmMsgHookList.ClearHook;
var O:TAmWinHookElem;
i:integer;
begin
  for i := FListElem.Count-1 downto 0 do
  begin
      O:= FListElem[i];
      FListElem.Delete(i);
      O.Free;
  end;
  FListElem.Clear;
end;

procedure TAmMsgHookList.DeleteHook(ListenObject:TObject;MsgForControl:TArray<Cardinal>);
begin
   if Assigned(ListenObject) then
   DeleteHook(0,MsgForControl,ListenObject);
   // else  нужно удалить все? то ClearHook
end;

procedure TAmMsgHookList.DeleteHook(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil);
var i,x:integer;
O:TAmWinHookElem;
begin
  if MsgForControl=nil then
  MsgForControl:=[0];
  while True do
  begin
     if not SerchHook(HandleControl,0,ListenObject,i,x) then
     break;
     O:= FListElem[i];
     if O.ListenMsgDelete(MsgForControl) then
     begin
         FListElem.Delete(i);
         O.Free;
     end
     else  break;
  end;
end;

function TAmMsgHookList.SerchHook(HandleControl,MsgForControl:Cardinal;ListenObject:TObject;out IndexElem,IndexMsg:integer):boolean;
var i:integer;
begin

    if  Assigned(ListenObject) then
    begin
      for i := FListElem.Count-1 downto 0 do
      if FListElem[i].ListenObject = ListenObject then
      begin
         IndexElem:=i;
         IndexMsg:=-1;
         if MsgForControl = 0  then
         exit(true);
         IndexMsg:=FListElem[i].ListenMsgList.IndexOf(MsgForControl);
         if IndexMsg>=0 then
         exit(true);
      end;
    end
    else if HandleControl<>0 then
    begin
      for i := FListElem.Count-1 downto 0 do
      if FListElem[i].ListenWindowHandle = HandleControl then
      begin
         IndexElem:=i;
         IndexMsg:=-1;
         if MsgForControl = 0  then
         exit(true);
         IndexMsg:=FListElem[i].ListenMsgList.IndexOf(MsgForControl);
         if IndexMsg>=0 then
         exit(true);
      end;
    end
    else
    begin
      for i := FListElem.Count-1 downto 0 do
      begin
         IndexElem:=i;
         IndexMsg:=-1;
         if MsgForControl = 0  then
         exit(true);
         IndexMsg:=FListElem[i].ListenMsgList.IndexOf(MsgForControl);
         if IndexMsg>=0 then
         exit(true);
      end;
    end;
    Result:=false;
    IndexElem:=-1;
    IndexMsg:=-1;
end;


function TAmMsgHookList.AddHook(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil):TAmWinHookElem;
begin
    Result:= AddHookCust(HandleControl,MsgForControl,ListenObject);
    Result.Start();
end;
function TAmMsgHookList.AddHookCust(HandleControl:Cardinal; MsgForControl:TArray<Cardinal>;ListenObject:TObject=nil):TAmWinHookElem;
begin
    if MsgForControl=nil then
    MsgForControl:=[];
    Result:=  AmHook.New(GetClassElem);
    (Result as TAmMsgHookElem).FLocalList:=self;
    FListElem.Add(Result);
    Result.ListenObject:= ListenObject;
    Result.ListenWindowHandle:= HandleControl;
    Result.ListenMsgAdd(MsgForControl);
    Result.FromVariant:=amwhSEND;
    Result.FromHandle:= Handle ;
    Result.FromMsg:=   WM_HOOK;
end;

function TAmMsgHookList.NewMessageHook(Prm: PAmWinHookPrm):Cardinal;
begin
    Result:=0;
    if Assigned(FOnNewMessage) then
    FOnNewMessage(self,Prm);
end;

procedure TAmMsgHookList.NewSendHook(var Msg: Tmessage);
begin
   if Msg.LParam<>0 then
     NewMessageHook(PAmWinHookPrm(Msg.LParam))
end;


{ TAmWinControlHookList }

type
 TLocWinControl =class(TWinControl);

function ArrayCardinalIndexOf(Source:TArray<Cardinal>;Value:Cardinal):integer;
begin
    for Result := 0 to Length(Source)-1 do
     if Source[Result] = Value then exit;
     Result:=-1;
end;
procedure ArrayCardinalAdd(var Source:TArray<Cardinal>;Value:Cardinal);
begin
   SetLength(Source,length(Source)+1);
   Source[length(Source)-1]:=Value;
end;
function TAmVclHookList.AddHookLink(ListenPointer:PWinControl;MsgForControl:TArray<Cardinal>):TAmWinHookElem;
begin
  if not Assigned(ListenPointer) then
  raise Exception.Create('Error TAmWinControlHookList.AddHook ListenPointer = nil');
  Result:= AddHook(ListenPointer^,MsgForControl);
  (Result as TAmVclHookElem).ListenPointer:=  ListenPointer;
end;

function TAmVclHookList.AddHook(ListenObject: TWinControl;MsgForControl: TArray<Cardinal>): TAmWinHookElem;
var I,X:integer;
 u1,u2:boolean;
begin
  u1:=false;
  u2:=false;
  if MsgForControl=nil then
  MsgForControl:=[];
  Result:=nil;
  if not Assigned(ListenObject) then
  raise Exception.Create('Error TAmWinControlHookList.AddHook ListenObject = nil');
  if csDestroying in ListenObject.ComponentState  then
  exit;
  if not SerchHook(0,0,ListenObject,I,X) then
  begin
     if ArrayCardinalIndexOf(MsgForControl,WM_CREATE)<0 then
     begin
      u1:=true;
      ArrayCardinalAdd(MsgForControl,WM_CREATE);
     end;
     if ArrayCardinalIndexOf(MsgForControl,WM_DESTROY)<0 then
     begin
      u2:=true;
      ArrayCardinalAdd(MsgForControl,WM_DESTROY);
     end;
     Result:=AddHookCust(TLocWinControl(ListenObject).WindowHandle,MsgForControl,ListenObject);
     (Result as TAmVclHookElem).AutoAdd_Msg_Create:=   u1;
     (Result as TAmVclHookElem).AutoAdd_Msg_Destroy:=  u2;
     Result.Start();
     exit;
  end;

  Result:= self.FListElem[I];
  for I := 0 to length(MsgForControl)-1 do
  if Result.ListenMsgList.IndexOf(MsgForControl[i])<0 then
   Result.ListenMsgList.Add(MsgForControl[i]);

  if  Result.ListenMsgList.IndexOf(WM_CREATE)<0 then
   begin
    (Result as TAmVclHookElem).AutoAdd_Msg_Create:=true;
    Result.ListenMsgList.Add(WM_CREATE)
   end;
  if  Result.ListenMsgList.IndexOf(WM_DESTROY)<0 then
   begin
    (Result as TAmVclHookElem).AutoAdd_Msg_Destroy:=true;
    Result.ListenMsgList.Add(WM_DESTROY)
   end;
end;

procedure TAmVclHookList.DeleteHook(ListenObject: TWinControl; MsgForControl:TArray<Cardinal>);
begin
 inherited DeleteHook(ListenObject,MsgForControl);
end;


class function TAmVclHookList.GetClassElem: TAmWinHookElemClass;
begin
  Result:= TAmVclHookElem;
end;

function TAmVclHookList.NewMessageHook(Prm: PAmWinHookPrm): Cardinal;
begin

    if  Prm.Message  = WM_CREATE then
    begin
      if Assigned(Prm.Elem) and (Prm.Elem is TAmVclHookElem) and (Prm = @Prm.Elem.Prm) then
      TAmVclHookElem(Prm.Elem).ClenerWinControl;
    end;

    Result:= inherited;

    if  Prm.Message  = WM_DESTROY then
    begin
      if Assigned(Prm.Elem) and (Prm.Elem is TAmVclHookElem) and (Prm = @Prm.Elem.Prm) then
      TAmVclHookElem(Prm.Elem).ClenerWinControl;
    end;

end;

{ TAmVclHookElem }

constructor TAmVclHookElem.Create(AOwner:TAmWinHook);
begin
  inherited;
  ListMsgSaved:=TList<Cardinal>.create;
  AutoAdd_Msg_Create:=false;
  AutoAdd_Msg_Destroy:=false;
  ListenPointer:=nil;
  SaveList;
end;

destructor TAmVclHookElem.Destroy;
begin
  FreeAndNil(ListMsgSaved);
  ListenPointer:=nil;
  inherited;
end;


function TAmVclHookElem.DeleteList(Source:TList<Cardinal>;AList:TArray<Cardinal>):boolean;
var R1,R2:boolean;
 function loc(L:TList<Cardinal>):boolean;
 begin
     Result:=false;
     if  L.Count>2 then exit;
     R1:= AutoAdd_Msg_Create and (L.IndexOf(WM_CREATE)>=0);
     R2:= AutoAdd_Msg_Destroy and (L.IndexOf(WM_DESTROY)>=0);
     if L.Count = 1 then
     Result:=  R1 or  R2
     else Result:=  R1 and  R2;
 end;
begin
    Result:=  inherited DeleteList(Source,AList);
    if not Result then
    Result:= loc(Source);
end;
function TAmVclHookElem.ListenMsgListGet: TList<Cardinal>;
begin
 if ListenWindowHandle = 0  then
 Result:=  ListMsgSaved
 else Result:= inherited ListenMsgListGet;
end;
procedure TAmVclHookElem.ListenObjectSet(const Value: TObject);
begin
  if FListenObject <> Value then
  begin
     FListenObject:= Value;
     if Assigned(FListenObject) and (FListenObject is TWinControl) then
     ListenWindowHandle:=  TLocWinControl(FListenObject).WindowHandle
     else  ListenWindowHandle:=0;
  end;
  
end;
procedure TAmVclHookElem.ListenWindowHandleSet(const Value: Cardinal);
begin
   if FListenWindowHandle <> Value then
   begin
      if Value = 0  then
      SaveList
      else ResetList;
      FListenWindowHandle:= Value;
   end;
end;

procedure TAmVclHookElem.ResetList;
begin
    FLMsg.Clear;
    ListMsgSaved.TrimExcess;
    FLMsg.AddRange(ListMsgSaved.List);
    ListMsgSaved.Clear;
end;

procedure TAmVclHookElem.SaveList;
begin
    ListMsgSaved.Clear;
    FLMsg.TrimExcess;
    ListMsgSaved.AddRange(FLMsg.List);
    FLMsg.Clear;
    FLMsg.Add(WM_CREATE);
end;

procedure TAmVclHookElem.ClenerWinControl;
//var S:string;
begin
    case Prm.Message of
        WM_CREATE:begin
          if (ListenWindowHandle = 0) and (Prm.Hwd <> 0)  then  // PCREATESTRUCT
          begin
              if (ListenPointer<>nil) and (ListenPointer^<>nil)
              and  (TLocWinControl(ListenPointer^).WindowHandle = Prm.Hwd) then
               ListenObject:= ListenPointer^;

              if Assigned(ListenObject) and  (ListenObject is TWinControl)
              and (TLocWinControl(ListenObject).WindowHandle = Prm.Hwd) then
               ListenWindowHandle:=  Prm.Hwd;
          end;
        end;
        WM_DESTROY:begin
           if Assigned(ListenObject) and  (ListenObject is TWinControl)
           and (csDestroying in TWinControl(Prm.Elem.ListenObject).ComponentState) then
           begin
            ListenObject:=nil;
            if (ListenPointer<>nil) then
            ListenPointer^:=nil;
           end
           else
            ListenWindowHandle:=0;

            //Free;
        end;

    end;
end;






initialization
begin
  AmHook :=  TAmWinHook.Create;
end;

finalization
begin
//AmHook.Free;
 FreeAndNil(AmHook);
end;










(*
    это промежуточное звено определения виден ли контол на экране или нет
    смысл в том что бы получить сообытие стало видно и пропал из виду и был виден n секунд
    можно посмотреть как в реалях пользоваься как добавлять как удалять TAmWinHookElem
    type
     TamIsСontrolToScreen =class;

     TamIsСontrolToScreenHook =class(TamHandleObject)
      private
       const WM_HOOK= wm_user+1028;
      var
       Fscreen:TamIsСontrolToScreen;
       FControl: TWinControl;
       FOnFullScreenPart: TEventFullScreenPart;

       FtimerControlReady: Ttimer;
       ListMsg:Tlist;

        procedure OnTimerControlReady(s:Tobject);
        procedure OnEvent(s:Tobject);
        procedure Start;
        procedure ClearList;
        function CheckControl:boolean;
        procedure SetControl(aControl:TWinControl);

        procedure AddToListHook(Msg:Cardinal);
        procedure OnNewSendMessageHook(var Msg:Tmessage);  message WM_HOOK;
        procedure OnNewMessageProcHook(var Param:TAmWinHookParam);


      public

        constructor Create;
        destructor Destroy; override;
        property  Control:TWinControl read FControl write SetControl;

       property OnFullScreenPart: TEventFullScreenPart read FOnFullScreenPart write FOnFullScreenPart;
     end;


            {TamIsСontrolToScreenHook}

constructor TamIsСontrolToScreenHook.Create;
begin

    inherited create;
    ListMsg:=Tlist.Create;
    Fscreen:=  TamIsСontrolToScreen.Create;
    Fscreen.OnFullScreenPart:=OnEvent;
    FtimerControlReady:=Ttimer.Create(nil);
    FtimerControlReady.Interval:=2000;
    FtimerControlReady.Enabled:=false;
    FtimerControlReady.OnTimer:=  OnTimerControlReady;



end;

destructor TamIsСontrolToScreenHook.Destroy;
begin
   FtimerControlReady.Enabled:=false;
   FtimerControlReady.Free;

   Fscreen.Free;
   Fscreen:=nil;
   ClearList;
   ListMsg.Free;
   inherited;

end;
procedure TamIsСontrolToScreenHook.OnEvent(s:Tobject);
begin
    if Assigned(FOnFullScreenPart) then  FOnFullScreenPart(s);
end;
procedure TamIsСontrolToScreenHook.ClearList;
var Elem:TAmWinHookElem;
i:integer;
begin
    for I := 0 to ListMsg.Count-1 do
    begin
      Elem:=  TAmWinHookElem(ListMsg[0]);
      if Assigned(Elem)then
      begin
         AmHook.List_CALLWNDPROC.Delete(Elem);
         AmHook.List_GETMESSAGE.Delete(Elem);
      end;
    end;
    ListMsg.Clear;
end;
function TamIsСontrolToScreenHook.CheckControl:boolean;
begin
   Result:=(FControl<>nil) and (Assigned(FControl)) and (FControl.Handle>0) and  (GetDC(FControl.Handle)>0)
end;
procedure TamIsСontrolToScreenHook.Start;
begin
    Fscreen.Control:= FControl;
    AddToListHook(WM_PAINT);
    AddToListHook(WM_MOVE);
    AddToListHook(wm_Destroy);
    //CM_VISIBLECHANGED
end;
procedure TamIsСontrolToScreenHook.OnTimerControlReady(s:Tobject);
begin
    if CheckControl then
    begin

        FtimerControlReady.Enabled:=false;
        Start ;
    end;
end;
procedure TamIsСontrolToScreenHook.SetControl(aControl:TWinControl);
var Elem:TAmWinHookElem;
begin
    FControl:= aControl;

    if CheckControl then  Start
    else  FtimerControlReady.Enabled:=true;
end;
procedure TamIsСontrolToScreenHook.AddToListHook(Msg:Cardinal);
var Elem:TAmWinHookElem;
begin


    Elem:=  TAmWinHookElem.Create;
    Elem.WinMsg:=  Msg;
    Elem.WinHandle:= FControl.Handle;
    Elem.ExpVariant:=amwhSEND;
    Elem.FromHandle:= Handle ;
    Elem.FromMsg:=   WM_HOOK;
   // Elem.FromMsgProc:= OnNewMessageHook;

    AmHook.List_GETMESSAGE.Add(Elem);
    AmHook.Start_GETMESSAGE;

    AmHook.List_CALLWNDPROC.Add(Elem);
    AmHook.Start_CALLWNDPROC;

    ListMsg.Add(Elem);

end;
procedure TamIsСontrolToScreenHook.OnNewSendMessageHook(var Msg:Tmessage); //message WM_HOOK;
var Param:TAmWinHookParam;
begin
   if Msg.LParam<>0 then
   begin
       Param:= TAmWinHookParam(Pointer(Msg.LParam)^);
     OnNewMessageProcHook(Param)
   end;
end;
procedure TamIsСontrolToScreenHook.OnNewMessageProcHook(var Param:TAmWinHookParam);
begin
   if FControl.Visible and FControl.CanFocus then
   begin

     case Param.Msg of

          WM_PAINT    : Fscreen.IntupOnPaint;
          WM_MOVE     : Fscreen.IntupOnMovi;
          WM_Destroy  : begin
             //
             if Assigned(Fscreen) then
               FScreen.IntupOnDestroy;
               ClearList;
          end;
     end;
   end;
end;
*)

end.
