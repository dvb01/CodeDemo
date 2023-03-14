unit AmThreadPoolTask;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Dialogs,
  math,syncobjs,
  Dateutils,FileInfo,
  AmSystemBase,AmSystemObject,
  AmHandleObject,
  AMUserType,
  AmList;


 type
  TAmTaskStatus = (          amPoolTh_None,
                             amPoolTh_Created,
                             amPoolTh_ExecuteStart,//  поток начал жить
                             amPoolTh_ProcRun,    // отпралена команда на запуск новой процедуры
                             amPoolTh_ProcStart,  //процедура сейчас будет запущена в потоке
                             amPoolTh_ProcFinish, //процедура заверщилась
                             amPoolTh_ProcReturn,   //покок ничего не делает ждет amPoolTh_ProcRun
                             amPoolTh_NeedTerminated,
                             amPoolTh_ExecuteFinish //  поток закончил жить sssss ыыы   ыы ыыыыыыыы
                             );








  TAmTaskPoolMannager = class (TAmObject)
     type
        TItem = class sealed (TamThread)
         private
            FSignal:TAmEvent;
            FSignalStart:TAmEvent;
            FSecondWaitForBeforeDestroyThread:Cardinal;
            [Volatile] FIdIndiv:Cardinal;
            Fcs:TAmCs;
            FStatus:TAmTaskStatus;
            FOnSender:TNotifyEvent;
            [Weak] FSenderObj:TObject;
            [Weak] Mannager:TAmTaskPoolMannager;
            Function GetIdIndiv:Cardinal;
            Procedure  SetIdIndiv(const Value:Cardinal);
         protected
            procedure Execute; override;
            procedure ExecuteStart;
            procedure ExecuteFinish;
            function BeforeRun:boolean;
            function AfterRun:boolean;
            procedure Run(Obj:TObject); virtual;
         public
            constructor Create(ASecondWaitForBeforeDestroyThread:Cardinal=180);
            destructor  Destroy; override;
            procedure   Terminate; reintroduce;
            property IdIndiv: Cardinal read GetIdIndiv;
        end;
    private
     CsList:TAmcs;
     CsDestroing:TAmEvent;
     IsDestroing:TAmVarCs<boolean>;
     FListAll:TAmListVar<TItem>;
     FListFree:TAmListVar<TItem>;
     FListRun:TAmListVar<TItem>;
     FSecondWaitForBeforeDestroyThread,
     FMilliSecondSleepBeforeNewCreateThread:Cardinal;
     FOnRunNewThread:TNotifyEvent;
     [Volatile]FCounterIdItem:Cardinal;
     FCountMaxThread:Cardinal;

     Cache_CountAll:integer;
     Cache_CountFree:integer;
     Cache_CountRun:integer;
     function GetNewIndiv:Cardinal;
   protected

   public


      property SecondWaitForBeforeDestroyThread: Cardinal read FSecondWaitForBeforeDestroyThread write FSecondWaitForBeforeDestroyThread;
      property MilliSecondSleepBeforeNewCreateThread: Cardinal read FMilliSecondSleepBeforeNewCreateThread write FMilliSecondSleepBeforeNewCreateThread;
      property CountMaxThread: Cardinal read FCountMaxThread write FCountMaxThread;

      // можно зарезервить кол-во поток что бы потом их не создавать
      // но лучше по мере необходимости получать потоки
      function CreateNewThreads(Count:integer):integer;

      // можно передать наследника TAmObjectTask
      function GetThread(Obj:TObject):boolean;

      // если переданный объект не TAmObjectTask то исполнится это событие в другом потоке
      property OnRunNewThread: TNotifyEvent read FOnRunNewThread write FOnRunNewThread ;

      function GetCountListAll(NotLock:boolean):integer;
      function GetCountListFree(NotLock:boolean):integer;
      function GetCountListRun(NotLock:boolean):integer;

      // если какие то потоки еше рабоатают их попросит завершится
      // когда остановливаете программу запустите SetDestroing(true) or Clear(true)
      // что бы  GetThread перестал выдавать потоки
      procedure Clear(isDestoing:boolean=true);
      procedure SetDestroing(Value:boolean);

      constructor Create();
      destructor  Destroy; override;
  end;

  // если в TAmObjectTask.Start(nil) то будет использоватся пул по умолчанию PoolThreadMannager
  // можно не создавать отдельные TAmTaskPoolMannager
  // а пользоваться общим для всей программы
  // PoolThreadMannager.Clear;  когда остановливаете программу запустите
  // все созданые потоки где то самому хранить в своих листах и их завершать до уничтожения PoolThreadMannager
  function  PoolThreadMannager:TAmTaskPoolMannager;










  type
  // объект который можно использовать как отдельный поток
  TAmObjectTask = class (TAmObject)
    private
     FTerminateEvent :TAmEvent;
     FTerminated:boolean;
     FFreeOnTerminate:boolean;
     FIsRun:TAmVarCs<boolean>;
     FSignalWaitFor:TAmEvent;
     FOnBeforeRun:TNotifyEvent;
     FOnAfterRun:TNotifyEvent;
     FOnTerminate,
     FOnTerminated,
     FOnWaitForAfter:TNotifyEvent;
     FOnTerminatedExternally: TProcDefaultObjVarBoolean;
     [Volatile] FCurrentThread:TAmTaskPoolMannager.TItem;

     // создание хандела только по запросу HandleWndNeeded
     FHandleWnd:Cardinal;
     FHandleWndNeeded:boolean;

     FIsPaused:TAmVarCs<boolean>;
     FSignalPause:TAmEvent;
     FSignalPauseWaitFor:TAmEvent;
     FOnPauseSet,
     FOnPauseUnSet,
     FOnPauseUnSetExp,
     FOnPauseSetExp:TNotifyEvent;



     procedure BeforeRun;
     procedure AfterRun;
     // входная процедура в отдельном потоке параментром передается тот поток в контексте которого эта проц выполняется
     procedure RunWithTask(ACurrentThread:TAmTaskPoolMannager.TItem);
     function GetTerminated:boolean;
     function GetIsRun:boolean;
     function GetCurrentThreadIndiv:Cardinal;
     function GetCurrentThread:TAmTaskPoolMannager.TItem;
     procedure SetIsPaused(Value:boolean);
     function GetIsPaused :boolean;
     function TerminateHandleGet: Cardinal;
     function TerminateObjEventGet: TAmEvent;

     function HandleWndGet: Cardinal;
     procedure HandleWndProc(var Msg: TMessage);
     procedure HandleWndProcMessage;
     function  HandleWndCheckCreate:boolean;
     procedure HandleWndCheckDestoy;
     procedure PeekProcessMessage;
    protected
     FFreeSource:Pointer;//свобдное поле
     FTaskId:Cardinal;
     function SleepAm(Value:Cardinal):TWaitResult;

     // если IsPause true то будет ждать выхода из паузы
     // рекомендовано в самой высоко уровневой Run  сразу запустить PauseCheck вдруг объект сразу хочет стать на паузу
    // или просто  Terminated;
     procedure PauseCheck;
    //вызывать   Terminated только в процедуре отдельного потока т.е только потоке в котором исполняется  Run
    // иначе может прога зависнуть из за установленной паузы
     property Terminated: boolean read GetTerminated;

     // процедура выполнения отдельного  потока
     procedure Run;virtual;  {EXSAMPLE CODE ABSTRACT PROSEDURE}
     procedure PauseChangeSet(NowValue:boolean);virtual;
     procedure PauseChangeSetExp(NowValue:boolean);virtual;


//     procedure PeekProcessMessage;
   //  procedure PeekNewMessage(Sender:TObject; msg :TMsg);
  public
     //свобдное поле
     property FreeSource: Pointer read FFreeSource write FFreeSource;
     //свобдное поле
     property TaskId: Cardinal read FTaskId write FTaskId;

    //не нужно вмещиватся в поток CurrentThread и пыттся его завершить остановить или на паузу поставить
    //  property CurrentThread:  вынесена сюда только для debug
    //нужно завершить процедуру  self.Terminate
    //на паузу пришите свою паузу через цикл ождидания или мьютикс или self.IsPaused
    // проверить нужно ли процедуре заверщится  self.Terminated
    // запушена ли в данный момент процедура в потоке self.IsRun
    // дождатся заверщения выполения процедуры  self.WaitFor
    // даже если процедура не выполняется можно запустить WaitFor она не будет ждать

     property CurrentThreadIndiv: Cardinal read GetCurrentThreadIndiv;
     property CurrentThread: TAmTaskPoolMannager.TItem read GetCurrentThread;

     // handle события о завершении потока удобно знать когда поток попросит завершения что бы в др объектах сразу выйти из цикла ожидания
     // можно вызвать также и  TerminateObjEvent.WaitFor(MyTimeOut);
     // TerminateObjEvent будет в сигнальном когда будет вызвана procedure Terminate; virtual;
     property TerminateHandle: Cardinal read TerminateHandleGet;
     property TerminateObjEvent: TAmEvent read TerminateObjEventGet;
     // обычный sleep но который реагирует и выходит с ожидания когда вызвана procedure Terminate; virtual;
     // в ответе или  wrSignaled т.е Terminated = true или wrTimeout полное время ожидания полностью выполнено
     function SleepTerminate(Value:Cardinal):TWaitResult;



     // что бы запусить объект в отдельном потоке нужно создать глобальную переменную TAmTaskPoolMannager
     //или пользоватся (что лучше уже созданной или передать nil)
     // если все ок то новый поток будет выполнятся в procedure Run;virtual;
     function  Start(Pool:TAmTaskPoolMannager=nil):boolean;

     //удалить объект после выполнения на автомате по умл false
     property FreeOnTerminate: boolean read FFreeOnTerminate write FFreeOnTerminate;

     //попросить завершится
     procedure Terminate; virtual;
     // дождатся завершения
     //если FreeOnTerminate = true то WaitFor не вызывать
     procedure WaitFor;
     //запушена ли процедура в данный момент
     property IsRun: Boolean read GetIsRun;


     //поставить на паузу или узнать значение
     property IsPaused: boolean read GetIsPaused write SetIsPaused;
     // если нужно дождатся момента установки остановки потока
     // поток замрет в процедуре  PauseCheck  в потоке вызывайте переодичеки Terminated
     // сначала ставим  IsPaused:=true;
     // потом вызываем PauseWaitFor
     // bnot = объект не в потоке
     // bfalse  = объект не на паузе
     // btrue = дождались установки паузы
     //IsCheckIsRun = true проверять запушен ли объект в потоке
     // false  нужно ставить при создании объекта что бы  дождатся запуска его в потоке а после продолжить код
     // обычно всегда true
     function PauseWaitFor(IsCheckIsRun:boolean=true;TimeOut:Cardinal=INFINITE):TBoolTri;


     // если нужно что объект в потоке принимал postmessage сообщения
     // после созлания TAmObjectTask и его старта
     //запустить HandleWndNeeded дождатся получения HandleWnd
     // причем в run должна запускатся переодически Terminated
     // после получения HandleWnd можно туда в поток отправить postmessage   или PostMessageHandleWnd
     // Create;
     // Start;
     // HandleWndNeeded(5);
     // PostMessageHandleWnd(msg,w,l);


     // 2й вариант
     // иначе получить HandleWnd можно до запуска Start
     // HandleWndNeeded(0)
     // Start
     // while HandleWnd<=0 then sleep(..);
     // PostMessageHandleWnd(msg,w,l);
     // во 2м варике необязательно проверять часто  Terminated
     //т.к при старте потока до запуска run объект уже будет иметь HandleWnd

     procedure PeekProcessMessagePublic;
     function PostMessageHandleWnd(Msg:Cardinal;W,L:Cardinal):boolean;
     property HandleWnd: Cardinal read HandleWndGet;
     function HandleWndNeeded(SecWaitFor:integer):boolean;



     // 2события перед и после запуска процедуры  Run в отдельном потоке
     property OnRunBefore: TNotifyEvent read FOnBeforeRun write FOnBeforeRun;
     property OnRunAfter: TNotifyEvent read FOnAfterRun write FOnAfterRun;

     // сработает когда запушена Terminate
     property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;

     // сработает когда объект узнал что ему нужно завершить выполнные Run (может сработать многократно)
     property OnTerminated: TNotifyEvent read FOnTerminated write FOnTerminated;

     // когда объект проверяет Terminated выполнится это событие и можно в него установить свое значение
     // причем FTerminated не поменяет своего значения а OnTerminated сработает
     property OnTerminatedExternally: TProcDefaultObjVarBoolean read FOnTerminatedExternally write FOnTerminatedExternally;

     // после ожидания остановки
     property OnWaitForAfter: TNotifyEvent read FOnWaitForAfter write FOnWaitForAfter;

     //перед удалением есть событие в родителе

     // команда  поставлен на паузу отправляется
     property OnPauseSet: TNotifyEvent read FOnPauseSet write FOnPauseSet;

     // команда  снят с паузы отправляется
     property OnPauseUnSet: TNotifyEvent read FOnPauseUnSet write FOnPauseUnSet;

     // команда  поставлен на паузу выполнилась
     property OnPauseSetExp: TNotifyEvent read FOnPauseSetExp write FOnPauseSetExp;

     // команда  снят с паузы выполнилась
     property OnPauseUnSetExp: TNotifyEvent read FOnPauseUnSetExp write FOnPauseUnSetExp;

     constructor Create();
     destructor  Destroy; override;
  end;

  ///////////////////////////////////////////////////////////
  ///
  ///
  ///     MINI  ЗАДАЧИ
  ///
  ///  /////////////////////////////////////////////////////////
  // TAmObjectTaskMini поток для выполнения мелких задач
  // TAmListObjectTaskMini может хранить разные  TAmObjectTaskMini в себе
  // это единоразовое выполнение выполнили и удалились
  // написал что бы хранить разные объекты в vks mini pot
  // создать глобальную переменную и при выкл проги вызвать Clear
  // смысл создать TAmObjectTaskMini он добавится в TAmListObjectTaskMini
  // TAmObjectTaskMini.Start(Pool);
  //  TAmObjectTaskMini.FFreeOnTerminate = true всегда
  // при Clear FFreeOnTerminate меняется на false и дожидается завершения

  TAmListObjectTaskMini =class;
  TAmObjectTaskMini =class;
  TAmListObjTaskMini = TAmList<TAmObjectTaskMini>;

  TAmObjectTaskMini   =class (TAmObjectTask)
   strict private
     [weak]FList:TAmListObjectTaskMini;  // к какому листу мини задач относится эта мини задача
   public
     // если мини задача еще выполняется но к примеру по кнопке кликнули что бы ее завершить можно вызвать это
     // выполнит terminate waitfor
     procedure ControlWantsTerminateThread;virtual;
     constructor Create(AMiniThreadList:TAmListObjectTaskMini);
     destructor  Destroy; override;
  end;

  // когда нужно выполнить другой объект задачи не в его потоке а в отдельном
  // если этот terminated =true то и Clientу передастся
  // Client  terminated =true то и этому передастся
  TAmObjectTaskMiniForOtherObj   =class (TAmObjectTaskMini)
   strict private
      FClient: TAmObjectTask;
      FLockCount:integer;
  private
    function ClientGet: TAmObjectTask;
    protected
     procedure Run;override;
     procedure ClientTerminatedExternally(AClient:Tobject;var V:boolean);
     procedure ClientTerminate(AClient:Tobject);
   public
     constructor Create(AMiniThreadList:TAmListObjectTaskMini;AClient:TAmObjectTask);
     destructor  Destroy; override;
     //другой объект
     property Client: TAmObjectTask read ClientGet;
     function ClientClear:TAmObjectTask;
     procedure Terminate;override;

  end;

  // список мини задач просто хранит лист и при удалении останавливает все задачи
  // если задача заверщилась раньше удаления TAmListObjectTaskMini
  // она просто удалится сразу  при TAmObjectTaskMini.Destroy
  TAmListObjectTaskMini  =class(TAmObjectCs)
   strict private
    FList: TAmListObjTaskMini;
    function ListGet: TAmListObjTaskMini;
   private
    function ListCountGet: integer;
   protected
     // когда TAmObjectTaskMini.Create то Add Когда  Destroy  - Delete
    function Add(Value:TAmObjectTaskMini):boolean;
    procedure Delete(Value:TAmObjectTaskMini);
   public
   //обращаясь к листу только внутри lock unlock TAmListObjectTaskMini
    property List: TAmListObjTaskMini read ListGet;
    property ListCount: integer read ListCountGet;
    procedure Clear;virtual;
    constructor Create();
    destructor  Destroy; override;
  end;

  ///////////////////////////////////////////////////////////


  ///
  ///  ..................................................................
  ///   ГРУППА КЛИЕНТОВ И КЛИЕНТ
  ///  .................................................................
  ///

  TAmClientTaskGroup =class;

  // абстрактная реализация клиентов и группы которая управляет клиентами
  TAmClientTask = class abstract (TAmObjectTask)
    private
     [Volatile] FIsRunWithGroup:boolean;//изменяется только в потоке группы  читать можно откуда угодно
     [Volatile] FIdClient:Cardinal;
     [Weak] FGroup :TAmClientTaskGroup;
     FIsFerstRun:boolean;
     FOnThreadStart,
     FOnThreadReturn,
     FOnReturn,
     FOnFerstRun:TNotifyEvent;
     procedure Return;
     function GetTerminated: boolean;
     function GetIsRunWithGroup: boolean;
     function GetIdClient: Cardinal;
     procedure SetIdClient(const Value:Cardinal);

    protected
     procedure ThreadReturn;
     function ThreadStart:boolean; virtual;
     property Terminated: boolean read GetTerminated;
     procedure Run(); override;final;
     procedure ClientRun;virtual;
     procedure PauseChangeSet(NowValue:boolean);override;



     // был и прямо сейчас  первый запуск в потоке или еще не был
     property IsFerstRun:boolean read FIsFerstRun;
     property Group: TAmClientTaskGroup read FGroup write FGroup;

    public
     property IdClient: Cardinal read GetIdClient;

     //значение переменной изменяется только в потоке группы запушен ли поток
     // удачно ли было получение потока (клиент сейчас работает в потоке?)
     property IsRunWithGroup: boolean read GetIsRunWithGroup;

     //отправляется команда на получение потока и поток получен
     property OnThreadStart: TNotifyEvent read FOnThreadStart write FOnThreadStart;

     //отправляется команда на возврат потока упраление клиентом группе поток почти освобожден
     property OnThreadReturn: TNotifyEvent read FOnThreadReturn write FOnThreadReturn;

     //команда на возврат потока упраление клиентом группе выполнена
     property OnReturn: TNotifyEvent read FOnReturn write FOnReturn;

     // сейчас выполнится первый запуск в потоке
     property OnFerstRun: TNotifyEvent read FOnFerstRun write FOnFerstRun;


     constructor Create(AGroup :TAmClientTaskGroup);
     destructor Destroy;override;
  end;

  TAmListClientTask = TAmList<TAmClientTask>;

  TAmClientTaskGroup = class abstract (TAmHandleThread)
    private
      [Volatile]FCounterIdClient:Cardinal;
      [Volatile]FRunTerminated :boolean;

      FRunCallIsLock:boolean;//изменяется только в потоке группы и предотвращает повторные отправки message Run_CONST
      FList:TAmListClientTask;
      [Weak] FMannager :TAmTaskPoolMannager;
      procedure SetClientId(CLient:TAmClientTask);
      function GetNewIdClient:Cardinal;
      procedure ListClear;
      function ListIndexOfBin(AIdClient:Cardinal):integer;
      procedure ListCheck(AddList:TAmListClientTask;ResultDublicats:boolean);
      function GetRunTerminated :boolean;

      //команда выполнить проверку клиентов на запуск в отдельный поток
      const Run_CONST = wm_user+1;
      procedure Run_BACK(var Msg:TMEssage);message Run_CONST;
      procedure Run_CALL;//должна запускатся только с текушего потока иначе с запускать RunMain;

      const Return_CONST = wm_user+2;
      procedure Return_BACK(var Msg:TMessage);message Return_CONST;
      procedure Return_CALL(ClientId:Cardinal);

      const RunMain_CONST = wm_user+3;
      procedure RunMain_BACK(var Msg:TMEssage);message RunMain_CONST;
      function RunMain_CALL:boolean;




      const ClientsAdd_CONST = wm_user+20;
      procedure ClientsAdd_BACK (var Msg:TMessage);message ClientsAdd_CONST ;
      function ClientsAdd_CALL (AList:TAmListClientTask):boolean;

      const ClientsDeleteAll_CONST = wm_user+21;
      procedure ClientsDeleteAll_BACK (var Msg:TMessage);message ClientsDeleteAll_CONST ;
      function ClientsDeleteAll_CALL :boolean;

      const ClientsDelete_CONST = wm_user+22;
      procedure ClientsDelete_BACK (var Msg:TMessage);message ClientsDelete_CONST ;
      function ClientsDelete_CALL(AList:TAmListClientTask) :boolean;

      const ClientDelete_CONST = wm_user+23;
      procedure ClientDelete_BACK (var Msg:TMessage);message ClientDelete_CONST ;
      function ClientDelete_CALL(Client:TAmClientTask) :boolean;


    protected
      procedure ListLock;
      function ListLockTry:boolean;
      procedure ListUnLock;
      function ListCount:integer;
      function ListIndex(Index:integer):TAmClientTask;

      procedure DoWaitForEventEx(Event:TWaitResult); override;
      procedure DoFinishThread; override;
      procedure Run;virtual;
      procedure rec_ClientsAdd(AList:TAmListClientTask);
      procedure rec_ClientsDeleteAll();
      procedure rec_ClientsDelete(AList:TAmListClientTask);
      procedure rec_ClientDelete(Client:TAmClientTask);

      // просит  procedure Run;virtual; завершится
      //в конце   Run   RunTerminateReset вызовется
      // нужно что бы быстрее обработать другую команду например удаление клиента (остановка)
     //например отправляем команду удалить сообщ в поток и вызываем RunTerminate
     // она завершается если там что то лодго выполняется и поток освододился начинает обработку сообш удаления
     // после сообщ удаления вызывается   Run_CALL
     // и run продолдается
      property RunTerminated: Boolean read GetRunTerminated;
      // было RunTerminated=true станет false
      function RunTerminateReset:boolean;
    public
      function  StartThread():boolean;
      procedure StopThread();

      //обычно нет необходимости вызывать ее
      // отправляет сообщение в поток чтобы запустить  procedure Run;virtual;
      function cmd_Run:boolean;

      // custmom cmd_Run c параметрами как использовать рещается в классах наследниках
      function cmd_Change(ACustomId,ACustomCmd,Msg,W,L:Cardinal):boolean;virtual;

      // передаваймые листы сами удалятся
      function cmd_ClientsAdd(AList:TAmListClientTask):boolean;
      function cmd_ClientsDeleteAll:boolean;
      function cmd_ClientsPauseAll(Value:boolean):boolean;
      function cmd_ClientsDelete(AList:TAmListClientTask):boolean;
      function cmd_PauseClients(AList:TAmListClientTask;Value:boolean):boolean;


      function cmd_ClientAdd(Client:TAmClientTask):boolean;
      function cmd_ClientDelete(Client:TAmClientTask):boolean;
      function cmd_PauseClient(Client:TAmClientTask;Value:boolean):boolean;

      function cmd_ClientIndexOfId(ClientId:Cardinal):integer;
      function cmd_ClientGetId(ClientId:Cardinal):TAmClientTask;
     // попросить procedure Run;virtual; завершится
     // это не команда завершения потока а только процедуры Run; в ней только можно проверять RunTerminated
     // в конце  Run; вызвать RunTerminateReset в любом случаи
     // после любого сообщения в поток с внешки вызвать или cmd_Run или Run_CALL
      procedure RunTerminate;

     constructor Create(AMannager :TAmTaskPoolMannager);
     destructor Destroy;override;
  end;
  //.........................................................................................




 TAmClientTask_EventDate = procedure (Sender:TObject; DateToSleep:TDateTime);
 TAmClientTask_EventDateStr = procedure (Sender:TObject; DateToSleep:TDateTime;ValueLog:string);
 //.............................................................................................
 {если клиенты запускается по определенному таймеру и каждому клиенту нужен отдельный поток}
 // клиент-аккаунт
  TAmClientTaskAcc = class(TAmClientTask)
     private
      [Volatile] FLastPlay:TDateTime;
      [Volatile] FNextPlay:TDateTime;
      FIsFerstCheckRun:boolean;
      FOnFerstCheckRun:TNotifyEvent;
      FOnLastPlayChange: TAmClientTask_EventDateStr;
      FOnNextPlayChange: TAmClientTask_EventDateStr;
      function GetLastPlay:TDateTime;
      procedure SetLastPlay(const Value:TDateTime);
      function GetNextPlay:TDateTime;
      procedure SetNextPlay(const Value:TDateTime);      
     protected

       function  ClientIsNeedCheckNextPlay:boolean;virtual;  //вернуть false когда нужно стандартно обрабатывать клиента если вернуть true то на этой итерации в любом случаи запустится  ClientGetNextPlay
       function  ClientGetNextPlay(const ANowDate:TDateTime;out ValueLog:string):TDateTime;virtual; //нужно вернуть дату когда клиенту запустится
       procedure ClientRun;override; // та процедура которая в отдельном потоке выполняется
       procedure SetLastPlayNow(ValueLog:string); virtual;   // в конце этой процедуры ClientRun вызвать когда последний раз запускались
       property LastPlay: TDateTime read GetLastPlay write SetLastPlay;
       property NextPlay: TDateTime read GetNextPlay write SetNextPlay;

       procedure NextPlaySet(ValueDate:TDateTime;ValueLog:string);       
       procedure DoLastPlayChange(ValueDate:TDateTime;ValueLog:string);virtual;
       procedure DoNextPlayChange(ValueDate:TDateTime;ValueLog:string);virtual;

       // клиент отдат себя под упраление группой впервые т.е первый раз была запушена ClientGetNextPlay
       procedure DoFerstCheckRun;virtual;
     public
     function ThreadStart:boolean; override;
     constructor Create(AGroup :TAmClientTaskGroup);
     destructor Destroy;override;

     // клиент отдат себя под упраление группой впервые т.е первый раз была запушена ClientGetNextPlay
     property OnFerstCheckRun: TNotifyEvent read FOnFerstCheckRun write FOnFerstCheckRun;
     
     property OnLastPlayChange: TAmClientTask_EventDateStr read FOnLastPlayChange write FOnLastPlayChange;
     property OnNextPlayChange: TAmClientTask_EventDateStr read FOnNextPlayChange write FOnNextPlayChange;
  end;


  
  // группа клиент-аккаунтов
  TAmClientTaskGroupAcc =  class(TAmClientTaskGroup)
     private
      FOnAfterRunNewDateToSleep:TAmClientTask_EventDate;
     protected
       DateLastRunThread:TDateTime; // дата последнего запуска клиента в поток (любого из клиентов)
       procedure Run;override; final;
      function RunClients(const NowDate:TDateTime):TDateTime;virtual; //событие проверки всех клиентов на запуск
//      procedure RunNewDay(const NowDate:TDateTime);virtual; //группа узнала что наступил новые сутки т.е сейчас +- полночь
      function DoCanFerstRunClientBeforeRunThread(var DateCanRun:TDateTime;NowDate:TDateTime):boolean; virtual;
      function DoCanRunClientBeforeRunThread(Item:TAmClientTaskAcc;var DateCanRun:TDateTime;NowDate:TDateTime):boolean; virtual;
      function ListCount:integer;
      function ListIndex(Index:integer):TAmClientTaskAcc;
     public
       function cmd_ClientNextPlayReset(ClientId:Cardinal):boolean;

       // группа проверила всех клиентов кого нужно запустила и пошла спать она выйдет из сна в передоваемой дате
       // дату в событии можно не изменять но если надо то ок
       property OnAfterRunNewDateToSleep: TAmClientTask_EventDate read FOnAfterRunNewDateToSleep write FOnAfterRunNewDateToSleep;
       constructor Create(AMannager :TAmTaskPoolMannager);
  end;
 //..........................................................................................


implementation

{ TAmClientTaskGroupAcc }



constructor TAmClientTaskGroupAcc.Create(AMannager: TAmTaskPoolMannager);
begin
  inherited Create(AMannager);

end;

function TAmClientTaskGroupAcc.cmd_ClientNextPlayReset(ClientId: Cardinal): boolean;
var C:TAmClientTask;
begin
  Result:=false;
  self.ListLock;
  try
       C:=self.cmd_ClientGetId(ClientId);
       if (C<>nil) and (C is TAmClientTaskAcc) then
       begin
         TAmClientTaskAcc(C).NextPlay:=now;
         Result:=true;
       end;

  finally
     self.ListUnLock;
  end;
  Result:= Result and cmd_Run;
end;

function TAmClientTaskGroupAcc.ListCount: integer;
begin
   Result:= inherited ListCount;
end;

function TAmClientTaskGroupAcc.ListIndex(Index: integer): TAmClientTaskAcc;
begin
  Result:= inherited ListIndex(Index) as TAmClientTaskAcc;
end;
function TAmClientTaskGroupAcc.DoCanFerstRunClientBeforeRunThread(var DateCanRun:TDateTime;NowDate:TDateTime):boolean;
begin
    Result:=true;
end;
function TAmClientTaskGroupAcc.DoCanRunClientBeforeRunThread(
  Item: TAmClientTaskAcc; var DateCanRun: TDateTime;
  NowDate: TDateTime): boolean;
begin
 Result:=true;
end;

function TAmClientTaskGroupAcc.RunClients(const NowDate:TDateTime):TDateTime;
var MinData:TDateTime;

  procedure LocSetMinDate(D:TDateTime);
  begin
     if MinData>D then
     MinData:= D;
  end;
  function Loc_IsNeedRunItem(Item:TAmClientTaskAcc):boolean;
  var D:TDateTime;
   ValueLog:string;
   IsF:boolean;
  begin
       // проверка даты запуска нужно ли сейчас запустится
       Result:=false;


        // если клиент не в потоке и не на паузе (пауза у клиента может быть даже не в потоке)
       if  not Item.IsRunWithGroup and not Item.IsPaused then
       begin
          // проверяем дату запуска ранее установленную
          D:= Item.NextPlay;
          if (NowDate>= D) or Item.ClientIsNeedCheckNextPlay then
          begin
             IsF:=false;
             try
               // log('===');
               // log('RunCheck Item NextPlay='+D.DataTimeToStringDef);
               // даем возможность клиенту убедится что ему нужно запустится
               // он вернет дату когда он должен быть запушен
                 D:= Item.ClientGetNextPlay(NowDate,ValueLog);
                 Item.NextPlaySet(D,ValueLog);

                 if not Item.FIsFerstCheckRun then
                 begin
                    IsF:=true;
                    Item.FIsFerstCheckRun:=true;
                    Item.DoFerstCheckRun;
                 end;


             except
                on e:exception do
                        log('ErrorCode.TAmClientTaskGroupAcc.RunClients.Loc_IsNeedRunItem '+e.Message,e);
             end;
             Result:= NowDate >= D;
             if not Result then
             begin
             // log('RunCheck Item NextPlay WF='+D.DataTimeToStringDef);
              LocSetMinDate(D);
             end
             else if IsF then                    
             begin
              // log('RunCheck Item NextPlay RUN='+D.DataTimeToStringDef);
               Result:=DoCanFerstRunClientBeforeRunThread(D,NowDate);
               if not Result then
               begin
                if NowDate >= D then
                D:= incSecond(NowDate,3);
                Item.NextPlaySet(D,'Дата запуска отложена при запуске ');
                LocSetMinDate(D);
               end;
               
             end
             else
             begin
               Result:=DoCanRunClientBeforeRunThread(Item,D,NowDate);
               if not Result then
               begin
                if NowDate >= D then
                D:= incSecond(NowDate,1);
                Item.NextPlaySet(D,'Дата запуска отложена ');
                LocSetMinDate(D);
               end;

             end;

          end
          else
          begin
            LocSetMinDate(D);
           // log('===');
            //    log('RunCheck Item NextPlay время не наступило='+D.DataTimeToStringDef);
          end;
       end;
  end;
  function Loc_GetRunItem(var IndexSave:integer;var CountIter:integer;var CountList:integer):TAmClientTaskAcc;
  begin
    Result:=nil;
    ListLock;
    try
       if IndexSave>=ListCount then
       IndexSave:=0;
       CountList:= ListCount;
       while (IndexSave<=CountList-1) and  not RunTerminated  do
       begin
          Result:= ListIndex(IndexSave);
          inc(IndexSave);
          inc(CountIter);
          // проверка даты запуска нужно ли сейчас запустится
          if Loc_IsNeedRunItem(Result) then exit
          else Result:=nil;
       end;
    finally
       ListUnLock;
    end;
  end;
  var
  Item:TAmClientTaskAcc;
  IndexSave,CountIter,CountList,df:integer;
  CountRunNow:Integer;
begin
 MinData:= NowDate+1;
 try
   try
        // проходим по всем клиентам и находим наименьшую дату когда запустится ему
        // если дата уже наступила то и запускаем тут же в новом потоке
        try
          CountRunNow:=0;
          IndexSave:=0;
          CountIter:=0;
          CountList:=1;
          while (CountList>0)and (CountIter<=CountList) and not RunTerminated  do
          begin

            // здесь получаем объект клиента если он <>nil то его нужно запустить
            // слжный цикл т.к иначе cs будет приводит к дедблоку
            Item:=Loc_GetRunItem(IndexSave,CountIter,CountList);
            if RunTerminated  then break;
          
          
            if Assigned(Item) then
            begin
            
              if not Item.ThreadStart then
              begin
                df:= math.RandomRange(10,30);
                LocSetMinDate(DateUtils.IncSecond(NowDate,df));
                log('Ошибка получения потока. группа ждет:'+df.ToString+' секунд');
                break;
              end
              else
              begin
                DateLastRunThread:= NowDate;
                inc(CountRunNow);
                if CountRunNow>50 then
                begin
                  df:= math.RandomRange(500,2000);
                  LocSetMinDate(DateUtils.IncMilliSecond(NowDate,df));
                  log('запушен блок 50 клиентов');
                  self.cmd_Run;
                  break;
                end;
              
              end;
            
            end;

          end;
        except
         on e:exception do
         begin
              LocSetMinDate(DateUtils.IncSecond(now,120));
              log('ErrorCode.TGrThreadItem.RunClients2 главная процедура группы сообщила об ошибке '+e.Message,e);
         end;
        end;

        try
          if RunTerminateReset then
          begin
                df:= math.RandomRange(500,2000);
                LocSetMinDate(DateUtils.IncMilliSecond(NowDate,df));
              //  log('RunTerminateReset');
          end;
        except
        on e:exception do
           log('ErrorCode.TGrThreadItem.RunClients RunTerminateReset '+e.Message,e);
        end;

   except
   on e:exception do
              log('ErrorCode.TAmClientTaskGroupAcc.RunClients '+e.Message,e);
   end;
 finally
   Result:= MinData;
 end;

end;
procedure TAmClientTaskGroupAcc.Run;
var MinDate,ANow:TDateTime;
   Delta:Int64;
begin
 try
    //в этой процедуре Run запускаем RunClients и получаем минимальную дату следущего запуска
    // одного из клиентов
    // эту дату преобразуем в оставщеея время и даем эти секунды текущему обхъекту подождать
    // после этого обратно запустится Run
    ANow:=Now;
    MinDate:=RunClients(ANow);
    try

     if Assigned(FOnAfterRunNewDateToSleep) then
     FOnAfterRunNewDateToSleep(self,MinDate);

    // log('Group TimeOut:'+MinDate.DataTimeToString());

     Delta  :=  DateTimeToMilliseconds(MinDate) - DateTimeToMilliseconds(ANow);
     if Delta>Cardinal.MaxValue then   Delta:=Cardinal.MaxValue
     else if Delta<=0 then Delta:=100;


     self.MiliSecondsTimeOutWaitFor:= Cardinal(Delta);
    except
    on e:exception do
            log('ErrorCode.TAmClientTaskGroupAcc.Run2 '+e.Message);
    end;

  // log('TGrClient min='+MiliSecondsTimeOutWaitFor.ToString +' дата:'+DateUtils.IncMilliSecond(ANow,MiliSecondsTimeOutWaitFor).DataTimeToStringDef);
 except
    on e:exception do
            log('ErrorCode.TAmClientTaskGroupAcc.Run '+e.Message);
 end;


end;

{ TAmClientTaskAcc }
constructor TAmClientTaskAcc.Create(AGroup: TAmClientTaskGroup);
begin
   inherited Create(AGroup);
    LastPlay:=now;
    NextPlay:=LastPlay;
    FIsFerstCheckRun:=false;
end;

destructor TAmClientTaskAcc.Destroy;
begin
  inherited Destroy;
end;

function TAmClientTaskAcc.ThreadStart:boolean; 
var i:integer;
D:TDateTime;
begin
    
    Result:=inherited ThreadStart;
  
    if not Result then
    begin
      I:=math.RandomRange(50,250);
      D:= DateUtils.IncSecond(now,I);
     // if self.IdClient=4 then 
    //  log('Ошибка получения потока. Дата запуска отложена на '+I.ToString+' секунд');
      NextPlaySet(D,'ErrorGetThread '+I.ToString+' sec.'); 
      
    end;
end;
function TAmClientTaskAcc.GetLastPlay:TDateTime;
begin
  Result:= AmAtomic.Getter(FLastPlay);
end;
procedure TAmClientTaskAcc.SetLastPlay(const Value:TDateTime);
begin
   AmAtomic.Setter(FLastPlay,Value);
end;
function TAmClientTaskAcc.GetNextPlay:TDateTime;
begin
  Result:= AmAtomic.Getter(FNextPlay);
end;
procedure TAmClientTaskAcc.SetNextPlay(const Value:TDateTime);
begin
   AmAtomic.Setter(FNextPlay,Value);
end;
procedure TAmClientTaskAcc.DoLastPlayChange(ValueDate:TDateTime;ValueLog:string);
begin
   if Assigned(FOnLastPlayChange) then
   FOnLastPlayChange(self,ValueDate,ValueLog);
end;
procedure TAmClientTaskAcc.DoNextPlayChange(ValueDate:TDateTime;ValueLog:string);
begin      
   if Assigned(FOnNextPlayChange) then
   FOnNextPlayChange(self,ValueDate,ValueLog);
end;
procedure TAmClientTaskAcc.NextPlaySet(ValueDate:TDateTime;ValueLog:string);
begin
    NextPlay:= ValueDate;
    DoNextPlayChange(ValueDate,ValueLog);
   // if self.IdClient=4 then    
    //log('Следущая дата запуска :'+ValueDate.DataTimeToStringDef);
end;
procedure TAmClientTaskAcc.DoFerstCheckRun;
begin
  if Assigned(FOnFerstCheckRun) then
  FOnFerstCheckRun(self);
end;
function  TAmClientTaskAcc.ClientIsNeedCheckNextPlay:boolean;
begin
   Result:= false;
end;
function TAmClientTaskAcc.ClientGetNextPlay(const ANowDate:TDateTime;out ValueLog:string): TDateTime;
begin
 Result:=0;
end;
procedure TAmClientTaskAcc.ClientRun;
begin
end;
procedure  TAmClientTaskAcc.SetLastPlayNow(ValueLog:string);
var V:TDateTime;
begin
   V:=now;
   LastPlay:=V;
   DoLastPlayChange(V,ValueLog);
end;



{ TAmClientTaskGroup }

constructor TAmClientTaskGroup.Create(AMannager: TAmTaskPoolMannager);
begin
    inherited Create();
    FMannager:=AMannager;
    FCounterIdClient:=0;
    FList:=TAmListClientTask.Create;
    FRunCallIsLock:=false;
    FRunTerminated:=false;
end;

destructor TAmClientTaskGroup.Destroy;
begin
  Terminate;
  WaitFor;
  ListClear;
  FreeAndNil(FList);
  inherited;
end;
function TAmClientTaskGroup.GetRunTerminated :boolean;
begin
    Result:= AmAtomic.Getter(FRunTerminated);
    Result:= Result or Terminated;
end;
procedure TAmClientTaskGroup.RunTerminate;
begin
   AmAtomic.Setter(FRunTerminated,true);
end;
function TAmClientTaskGroup.RunTerminateReset:boolean;
begin
   Result:= not Terminated and AmAtomic.Getter(FRunTerminated);
   if Result then
    AmAtomic.Setter(FRunTerminated,false);
end;
procedure TAmClientTaskGroup.ListClear;
var i:integer;
begin
    FList.Cs.Enter;
    try
      for I := 0 to FList.Count-1 do
      FList[i].Free;
      FList.Clear;
    finally
     FList.Cs.Leave;
    end;
end;
procedure TAmClientTaskGroup.ListLock;
begin
   FList.Cs.Enter;
end;
function TAmClientTaskGroup.ListLockTry:boolean;
begin
  Result:= FList.Cs.TryEnter;
end;
procedure TAmClientTaskGroup.ListUnLock;
begin
   FList.Cs.Leave;
end;
function TAmClientTaskGroup.ListCount:integer;
begin
  Result:=FList.Count;
end;
function TAmClientTaskGroup.ListIndex(Index:integer):TAmClientTask;
begin
   Result:= FList[Index];
end;
function TAmClientTaskGroup.ListIndexOfBin(AIdClient:Cardinal):integer;
var B:boolean;
begin
    FList.Cs.Enter;
    try
         B:= AmUSertype.amSerch.BinaryIndex3(Result,0,FList.Count-1,
          function(ind:integer):real
            var p,p2:real;
            begin
              p:= FList[ind].IdClient ;//здесь идет перебор значений
              p2:=AIdClient; //то что ищем и с чем сравниваем
              Result:=p-p2; //от меньшему к большего
            end);
          if not B then  Result:=-1;

    finally
        FList.Cs.Leave;
    end;
end;
procedure TAmClientTaskGroup.ListCheck(AddList:TAmListClientTask;ResultDublicats:boolean);
var i,x:integer;
begin
    FList.Cs.Enter;
    try
      for I := 0 to FList.Count-1 do
      begin
          x:= AddList.IndexOf(FList[i]);
          if ResultDublicats then
          begin
          if x<0 then
          AddList.Delete(x);
          end
          else
          begin
          if x>=0 then
          AddList.Delete(x);
          end;

      end;
    finally
     FList.Cs.Leave;
    end;
end;
function TAmClientTaskGroup.GetNewIdClient:Cardinal;
begin
  repeat
    Result := AmAtomic.Inc(FCounterIdClient);
  until Result <> 0;
end;
procedure TAmClientTaskGroup.SetClientId(CLient:TAmClientTask);
begin
  FList.Cs.Enter;
  try
    Client.SetIdClient(GetNewIdClient);
  finally
   FList.Cs.Leave;
  end;
end;

function TAmClientTaskGroup.StartThread():boolean;
begin
   Result:=not Finished;
   if Result then
   begin
     Start;
     self.HandleThread;
   end;
end;
procedure TAmClientTaskGroup.StopThread();
begin
  Terminate;
  WaitFor;
  ListClear;
end;


                         {cmd_ClientsAdd}
function TAmClientTaskGroup.cmd_ClientsAdd(AList: TAmListClientTask):boolean;
begin
   Result:=false;
   ListCheck(AList,false);
   if AList.Count>0 then
   Result:=ClientsAdd_CALL(AList)
   else AList.Free;
end;
function TAmClientTaskGroup.ClientsAdd_CALL(AList: TAmListClientTask):boolean;
begin
    Result:= PostMessageThread(ClientsAdd_CONST,0,LPARAM(AList));
    if not Result then     
    AList.Free;
end;
procedure TAmClientTaskGroup.ClientsAdd_BACK(var Msg: TMessage);
var AList: TAmListClientTask;
begin
  try
    AList:=  TAmListClientTask(Msg.LParam);
    try
       if Assigned(AList) then       
       rec_ClientsAdd(AList);
    finally
      AList.Free;
    end;
  finally
    Run_CALL;
  end;
end;
procedure TAmClientTaskGroup.rec_ClientsAdd(AList: TAmListClientTask);
begin
  FList.Cs.Enter;
  try
     ListCheck(AList,false);
     if AList.Count>0 then
     begin
       AList.TrimExcess;
       FList.AddRange(AList.List);
       Run_CALL;
     end;
  finally
    FList.Cs.Leave;
  end;
end;
                     {cmd_ClientsDeleteAll}
function TAmClientTaskGroup.cmd_ClientsDeleteAll:boolean;
begin
    Result:=ClientsDeleteAll_CALL;
    if Result then
    RunTerminate;
end;
function TAmClientTaskGroup.ClientsDeleteAll_CALL :boolean;
begin
   Result:= PostMessageThread(ClientsDeleteAll_CONST,0,0);
end;
procedure TAmClientTaskGroup.ClientsDeleteAll_BACK (var Msg:TMessage);//message ClientsDeleteAll_CONST ;
begin
  try
    rec_ClientsDeleteAll;
  finally
    Run_CALL;
  end;
end;
procedure TAmClientTaskGroup.rec_ClientsDeleteAll();
var i:integer;
begin
 try
    FList.Cs.Enter;
    try
       for I := 0 to FList.Count-1 do
       FList[i].Terminate;
       for I := 0 to FList.Count-1 do
       FList[i].WaitFor;
       for I := 0 to FList.Count-1 do
       FList[i].Free;
       FList.Clear;
    finally
      FList.Cs.Leave;
    end;
 except
    on e:exception do
            log('ErrorCode.TAmClientTaskGroup.rec_ClientsDeleteAll '+e.Message,e);
 end;
end;
              {cmd_ClientsPauseAll}
function TAmClientTaskGroup.cmd_ClientsPauseAll(Value:boolean):boolean;
var i:integer;
begin
 Result:=true;
 try
    FList.Cs.Enter;
    try
       for I := 0 to FList.Count-1 do
       FList[i].IsPaused:=Value;
    finally
      FList.Cs.Leave;
    end;
 except
    on e:exception do
            log('ErrorCode.TAmClientTaskGroup.cmd_ClientsPauseAll '+e.Message,e);
 end;
end;
                              {cmd_ClientsDelete}
function TAmClientTaskGroup.cmd_ClientsDelete(AList:TAmListClientTask):boolean;
begin
   Result:=false;
   ListCheck(AList,true);
   if AList.Count>0 then
   Result:=ClientsDelete_CALL(AList)
   else AList.Free;

   if Result then
   RunTerminate;
end;
function TAmClientTaskGroup.ClientsDelete_CALL(AList:TAmListClientTask) :boolean;
begin
   Result:= PostMessageThread(ClientsDeleteAll_CONST,0,LPARAM(AList));
    if not Result then
    AList.Free;
end;
procedure TAmClientTaskGroup.ClientsDelete_BACK (var Msg:TMessage);//message ClientsDelete_CONST ;
var AList:TAmListClientTask;
begin
  try
    AList:= TAmListClientTask(Msg.LParam);
    try
      if Assigned(AList) then
      rec_ClientsDelete(AList);
    finally
       AList.Free;
    end;
  finally
    Run_CALL;
  end;
end;
procedure TAmClientTaskGroup.rec_ClientsDelete(AList:TAmListClientTask);
var i,x:integer;
begin
  FList.Cs.Enter;
  try
     for I := AList.Count-1 downto 0 do
     begin
        x:=FList.IndexOf(AList[i]);
        if x>=0 then
          FList.Delete(x)
        else
        AList.Delete(i);
     end;
  finally
    FList.Cs.Leave;
  end;
     for I := 0 to AList.Count-1 do
     AList[i].Terminate;
     for I := 0 to AList.Count-1 do
     AList[i].WaitFor;
     for I := 0 to AList.Count-1 do
     AList[i].Free;
     AList.Clear;
end;
                             {cmd_PauseClients}
function TAmClientTaskGroup.cmd_PauseClients(AList:TAmListClientTask;Value:boolean):boolean;
var i:integer;
begin
   Result:=true;
   try
      FList.Cs.Enter;
      try
         try
           ListCheck(AList,true);
           for I := 0 to AList.Count-1 do
           AList[i].IsPaused:=Value;
         finally
           AList.Free;
         end;
      finally
        FList.Cs.Leave;
      end;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_PauseClients '+e.Message,e);
   end;
end;
                           {cmd_Change}
function TAmClientTaskGroup.cmd_Change(ACustomId, ACustomCmd, Msg, W,
  L: Cardinal): boolean;
begin
 Result:= False;
end;
                            {cmd_ClientAdd}
function TAmClientTaskGroup.cmd_ClientAdd(Client:TAmClientTask):boolean;
begin
   Result:=false;
   try
      FList.Cs.Enter;
      try
         if FList.IndexOf(Client)<0 then
         begin
            Result:=true;
            FList.Add(Client);
            cmd_Run;
         end;
      finally
        FList.Cs.Leave;
      end;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_AddClient '+e.Message,e);
   end;
end;
                            {cmd_ClientDelete}
function  TAmClientTaskGroup.cmd_ClientDelete(Client:TAmClientTask):boolean;
begin
   Result:=false;
   try
      FList.Cs.Enter;
      try
         if FList.IndexOf(Client)>=0 then
         begin
           //Client.Terminate;
           Result:=ClientDelete_CALL(Client);
         end;
      finally
        FList.Cs.Leave;
      end;
       if Result then
       RunTerminate;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_ClientDelete '+e.Message,e);
   end;

end;
function TAmClientTaskGroup.cmd_ClientGetId(ClientId: Cardinal): TAmClientTask;
var i:integer;
begin
   Result:=nil;
   try
      FList.Cs.Enter;
      try
         for i := 0 to FList.Count-1 do
          if FList.List[i].IdClient = ClientId then exit(FList.List[i]);

      finally
        FList.Cs.Leave;
      end;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_ClientGet '+e.Message,e);
   end;
end;

function TAmClientTaskGroup.cmd_ClientIndexOfId( ClientId: Cardinal): integer;
begin
   Result:=-1;
   try
      FList.Cs.Enter;
      try
         for Result := 0 to FList.Count-1 do
          if FList.List[Result].IdClient = ClientId then exit;
         Result:=-1;
      finally
        FList.Cs.Leave;
      end;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_ClientIndexOfId '+e.Message,e);
   end;
end;

function TAmClientTaskGroup.ClientDelete_CALL(Client:TAmClientTask) :boolean;
begin
    Result:= PostMessageThread(ClientDelete_CONST,0,LPARAM(Client));
end;
procedure TAmClientTaskGroup.ClientDelete_BACK (var Msg:TMessage);//message ClientDelete_CONST ;
var Client:TAmClientTask;
begin
 try
   Client:=  TAmClientTask(Msg.LParam);
   if Assigned(Client) then
   rec_ClientDelete(Client);
 finally
   Run_CALL;
 end;
end;
procedure TAmClientTaskGroup.rec_ClientDelete(Client:TAmClientTask);
var i:integer;
begin
   try
      FList.Cs.Enter;
      try
         i:= FList.IndexOf(Client);
          if i>=0 then
          FList.Delete(i);
      finally
        FList.Cs.Leave;
      end;
      if i>=0 then
      begin
      Client.Terminate;
      Client.WaitFor;
      Client.Free;
      end;

   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.rec_ClientDelete '+e.Message,e);
   end;
end;


                       {cmd_PauseClient}
function TAmClientTaskGroup.cmd_PauseClient(Client:TAmClientTask;Value:boolean):boolean;
var i:integer;
begin
   Result:=false;
   try
      FList.Cs.Enter;
      try
         i:=FList.IndexOf(Client);
         Result:= i>=0;
         if Result then
         begin
            Client.IsPaused:=Value;
         end;
      finally
        FList.Cs.Leave;
      end;
   except
      on e:exception do
              log('ErrorCode.TAmClientTaskGroup.cmd_PauseClient '+e.Message,e);
   end;
end;



procedure TAmClientTaskGroup.DoFinishThread;
begin
  inherited DoFinishThread;
  rec_ClientsDeleteAll;
end;

procedure TAmClientTaskGroup.DoWaitForEventEx(Event:TWaitResult);
begin
  inherited DoWaitForEventEx(Event);
  Run_CALL;
end;


procedure TAmClientTaskGroup.Return_CALL(ClientId:Cardinal);
begin
    self.PostMessageThread(Return_CONST,0,ClientId);
end;
procedure TAmClientTaskGroup.Return_BACK(var Msg: TMessage);
var IdClient:Cardinal;
i:integer;
begin
  try
    IdClient:= Msg.LParam;
    FList.Cs.Enter;
    try
        i:=ListIndexOfBin(IdClient);
        if i>=0 then
         FList[i].Return;
        
    finally
       FList.Cs.Leave;
    end;
  finally
    Run_CALL;
  end;
end;




procedure TAmClientTaskGroup.Run_CALL;
begin
     if not FRunCallIsLock then
     begin
       //log('Run_CALL');
     FRunCallIsLock:=self.PostMessageThread(Run_CONST,0,0);
     end
    // else
    // log('повторый Run_CALL не отправился');
end;
procedure TAmClientTaskGroup.Run_BACK(var Msg: TMEssage);
begin
   // log('Run_BACK');
    FRunCallIsLock:=false;
    Run;
end;
procedure TAmClientTaskGroup.Run;
begin
 raise Exception.Create('Error TAmClientTaskGroup.Run abstract procedure');
end;

function TAmClientTaskGroup.cmd_Run:boolean;
begin
   Result:=RunMain_CALL;
end;
function TAmClientTaskGroup.RunMain_CALL:boolean;
begin
  Result:= self.PostMessageThread(RunMain_CONST,0,0);
end;
procedure TAmClientTaskGroup.RunMain_BACK(var Msg:TMEssage);
begin
   Run_CALL;
end;




{ TAmClientTask }

constructor TAmClientTask.Create(AGroup: TAmClientTaskGroup);
begin
   inherited Create;
   FGroup:= AGroup;
   if Assigned(FGroup) then
   OnLog:= FGroup.LogEvent;
   FIsRunWithGroup:=false;
   FIdClient:=0;
   if Assigned(FGroup) then
   FGroup.SetClientId(self);
   FIsFerstRun:=false;
end;

destructor TAmClientTask.Destroy;
begin
  FGroup:=nil;
  inherited Destroy;

end;
function TAmClientTask.GetTerminated: boolean;
begin
    Result:= inherited Terminated;
end;
function TAmClientTask.GetIsRunWithGroup: boolean;
begin
  Result:= AmAtomic.Getter(FIsRunWithGroup);
end;
function TAmClientTask.GetIdClient: Cardinal;
begin
   Result:= AmAtomic.Getter(FIdClient);
end;
procedure TAmClientTask.SetIdClient(const Value:Cardinal);
begin
   AmAtomic.Setter(FIdClient,Value);
end;
function TAmClientTask.ThreadStart:boolean;
begin
 // log('Run'+self.FIdClient.ToString);
  Result:=false;
  if Assigned(FGroup) then
  Result:=FGroup.FMannager.GetThread(self);
  
  AmAtomic.Setter(FIsRunWithGroup,Result);

  if Result and Assigned(FOnThreadStart) then
  FOnThreadStart(self);
end;
procedure TAmClientTask.ThreadReturn;
begin
   if Assigned(FOnThreadReturn) then
   FOnThreadReturn(self);

   if Assigned(FGroup) then
   FGroup.Return_CALL(FIdClient);
end;
procedure TAmClientTask.Return;
begin
   // log('Return'+self.FIdClient.ToString);
    AmAtomic.Setter(FIsRunWithGroup,false);
    if Assigned(FOnReturn) then
    FOnReturn(self);

    if Assigned(FGroup) then
    FGroup.Run_CALL;
end;
procedure TAmClientTask.PauseChangeSet(NowValue:boolean);
begin
    inherited PauseChangeSet(NowValue);
    if not NowValue and not IsRunWithGroup then
    begin
      if Assigned(FGroup) then
      FGroup.cmd_Run;
    end;

end;
procedure TAmClientTask.Run;
begin


  try

    if not FIsFerstRun then
    begin
      FIsFerstRun:=true;
      if Assigned(FOnFerstRun) then
      FOnFerstRun(self);
    end;
    ClientRun;
  finally
    // if not Terminated then   проблему удаленного клиента решил установкой id для каждого клиента
     ThreadReturn;
  end;
end;
procedure TAmClientTask.ClientRun;
begin
end;











{ TAmObjectTask }
constructor TAmObjectTask.Create;
begin
    inherited;
    FTaskId:=0;
    FreeSource:=nil;
    FOnTerminatedExternally:=nil;
    FFreeOnTerminate:=false;
    FSignalWaitFor:=TAmEvent.Create(true);
    FTerminated:=false;
    FSignalWaitFor.SetEvent;
    FTerminateEvent := TAmEvent.Create(true);
    FTerminateEvent.ResetEvent;
    FIsRun:=TAmVarCs<boolean>.create;
    FIsRun.Val:=false;
    FCurrentThread:=nil;
    FIsPaused:=TAmVarCs<boolean>.Create;
    FIsPaused.Val:=false;
    FSignalPause:=TAmEvent.Create(true);
    FSignalPause.SetEvent;
    FSignalPauseWaitFor:=TAmEvent.Create(true);
    FSignalPauseWaitFor.SetEvent;


    // создание хандела только по запросу HandleWndNeeded
    FHandleWnd:=0;
    FHandleWndNeeded:=false;
end;

destructor TAmObjectTask.Destroy;
begin
   {
   Terminate; убрал это с Destroy т.к нужно самому контролировать их вызов
   когда сюда линия кода приходит объект уже должен быть отстановлен т.е Run не выполняется

   WaitFor;//тоже убрал по той же причине

   Terminate;WaitFor; должны быть вызваны внешне если FFreeOnTerminate = false
   }
  FHandleWnd:=0;
  FHandleWndNeeded:=false;
  inherited Destroy;
  FreeAndNil(FSignalWaitFor);
  FreeAndNil(FIsRun);
  FreeAndNil(FSignalPause);
  FreeAndNil(FSignalPauseWaitFor);
  FreeAndNil(FIsPaused);
  FreeAndNil(FTerminateEvent);
  FreeSource:=nil;
end;

procedure TAmObjectTask.BeforeRun;
begin
   FIsRun.Val:=true;
   FSignalWaitFor.ResetEvent;
   HandleWndCheckCreate;
   if Assigned(FOnBeforeRun) then
   FOnBeforeRun(self);
end;

procedure TAmObjectTask.AfterRun;
begin
   if Assigned(FOnAfterRun) then
   FOnAfterRun(self);
  HandleWndCheckDestoy;
  FIsRun.Val:=false;
  FSignalWaitFor.SetEvent;
end;


procedure TAmObjectTask.Run;
var i:integer;
begin
  i:=0; {EXSAMPLE CODE ABSTRACT PROSEDURE}
  while not Terminated do
  begin
     if i>3 then
     break;
     sleep(1000);
     inc(i);
  end;
  
end;

procedure TAmObjectTask.RunWithTask(ACurrentThread:TAmTaskPoolMannager.TItem);
begin
  try
    try
      AmAtomic.Lock.Exchange<TAmTaskPoolMannager.TItem>(FCurrentThread,ACurrentThread);
      BeforeRun;
      try
        // PauseCheck;
        //закоментил т.к вызывать PauseCheck здесь нельзя тогда функционал урежится.
        // запустить PauseCheck or Terminated нужно на самом высоком уровне Run
         Run;
      finally
         AfterRun;
         AmAtomic.Lock.Exchange<TAmTaskPoolMannager.TItem>(FCurrentThread,nil);
      end;
    finally
       if FFreeOnTerminate then
       Free;
    end;
  except
    on e:exception do
            log('ErrorCode.TAmObjectTask.RunWithTask '+self.ClassName+' '+e.Message,e);
  end;
end;

procedure TAmObjectTask.Terminate;
var R:TAmEvent;
begin
   FTerminated:=true;
   SetIsPaused(false);

   if Assigned(FOnTerminate) then
   FOnTerminate(self);

   R:= AmAtomic.Getter<TAmEvent>(FTerminateEvent);
   R.SetEvent;
end;

function TAmObjectTask.TerminateHandleGet: Cardinal;
var R:TAmEvent;
begin
   R:=AmAtomic.Getter<TAmEvent>(FTerminateEvent);
   Result:= R.Handle;
end;

function TAmObjectTask.TerminateObjEventGet: TAmEvent;
begin
   Result:= AmAtomic.Getter<TAmEvent>(FTerminateEvent);
end;

procedure TAmObjectTask.WaitFor;
begin
  if FFreeOnTerminate then
  raise Exception.Create('Error TAmObjectTask.WaitFor FFreeOnTerminate = true нельзя вызывать WaitFor т.к объект сам будет удален после выполнения самостоятельно');
  FSignalWaitFor.WaitFor(INFINITE);
  if Assigned(FOnWaitForAfter) then
  FOnWaitForAfter(self);
end;
function TAmObjectTask.SleepAm(Value: Cardinal): TWaitResult;
var R:TAmEvent;
begin
  R:= AmAtomic.Getter<TAmEvent>(FTerminateEvent);
  Result:=R.WaitFor(Value);
end;

function TAmObjectTask.SleepTerminate(Value: Cardinal): TWaitResult;
begin
   Result:= SleepAm(Value);
end;

function TAmObjectTask.Start(Pool: TAmTaskPoolMannager=nil):boolean;
begin
  if not Assigned(Pool) then
  Pool:= PoolThreadMannager;
 Result:=Pool.GetThread(self);
end;
function TAmObjectTask.GetIsPaused :boolean;
begin
  Result:= FIsPaused.Val;
end;
procedure TAmObjectTask.PauseChangeSet(NowValue:boolean);
begin
end;
procedure TAmObjectTask.PauseChangeSetExp(NowValue:boolean);
begin
end;
function TAmObjectTask.PauseWaitFor(IsCheckIsRun:boolean=true;TimeOut:Cardinal=INFINITE):TBoolTri;
var I:int64;
    C:Cardinal;
    //TWaitResult = (wrSignaled, wrTimeout, wrAbandoned, wrError, wrIOCompletion);
    Wf:TWaitResult;
begin

  Result:=bfalse;
  try
    if TimeOut<=0 then
    TimeOut:=1;

    I:= Int64(TimeOut);
    while I>0 do
    begin
        if IsCheckIsRun then
        begin
          if not  IsRun then
          begin
            Result:=bnot;
            break;
          end;
        end;

        if not  IsPaused then
        begin
          Result:=bfalse;
          break;
        end;

        C:=Cardinal(min(I,Int64(1000)));
        dec(I,C);
        if C>0 then
        begin
           Wf:=FSignalPauseWaitFor.WaitFor(C);
           case Wf of
                wrSignaled:begin
                  Result:=btrue;
                  break;
                end;
                wrTimeout:;
                else
                begin
                  raise Exception.Create('Error TAmObjectTask.PauseWaitFor Wf='+AmRecordHlp.EnumToStr(Wf)+' '+AmRaise.MsgSystem);
                end;

           end;
        end;
    end;
  finally
     if (Result = btrue)
     and ( (IsCheckIsRun and IsRun) or not IsCheckIsRun )
     and IsPaused then
       Result:= btrue
     else if IsCheckIsRun and not IsRun then
       Result:= bnot
     else if not IsPaused then
       Result:= bfalse;
  end;

end;
procedure TAmObjectTask.SetIsPaused(Value:boolean);
begin
   if FIsPaused.Val<>Value then
   begin
      if Value then
      begin
       FSignalPause.ResetEvent;
       FSignalPauseWaitFor.ResetEvent;
       FIsPaused.Val:= Value;


       if Assigned(FOnPauseSet) then
       FOnPauseSet(self);

      end
      else
      begin

       if Assigned(FOnPauseUnSet) then
       FOnPauseUnSet(self);

       FIsPaused.Val:= Value;
       FSignalPauseWaitFor.SetEvent;
       FSignalPause.SetEvent;
      end;
      PauseChangeSet(Value);
   end;
end;


procedure TAmObjectTask.PauseCheck;
begin
   if IsPaused then
   begin
      if Assigned(FOnPauseSetExp) then
      FOnPauseSetExp(self);
      PauseChangeSetExp(true);
      FSignalPauseWaitFor.SetEvent;
      FSignalPause.WaitFor(INFINITE);

      PauseChangeSetExp(false);
      if Assigned(FOnPauseUnSetExp) then
      FOnPauseUnSetExp(self);
   end;
end;
function TAmObjectTask.GetTerminated:boolean;
begin
   PauseCheck;
   HandleWndProcMessage;
   Result:= FTerminated;

   if Assigned(FOnTerminatedExternally) then
   FOnTerminatedExternally(self,Result);

   if Result and Assigned(FOnTerminated) then
   FOnTerminated(self);

end;
function TAmObjectTask.HandleWndGet: Cardinal;
begin
  Result:= AmAtomic.Getter(FHandleWnd);
end;
procedure TAmObjectTask.HandleWndProc(var Msg: TMessage);
begin
    Dispatch(Msg);
   // DefWindowProc(Handle, Msg.Msg, Msg.WParam, Msg.LParam);
end;
function  TAmObjectTask.HandleWndCheckCreate:boolean;
var Hd:Boolean;
H:Cardinal;
begin
    Result:=false;
    Hd:=AmAtomic.Getter(FHandleWndNeeded);
    if not Hd or not IsRun then
    exit;
    H:= HandleWnd;
    Result:=  H>0;
    if not Result then
    begin
        H:=AllocateHWnd(HandleWndProc);
        AmAtomic.Setter(FHandleWnd,H);
        Result:=  H>0;
    end;

end;
procedure TAmObjectTask.HandleWndCheckDestoy;
var H:Cardinal;
begin
   H:= AmAtomic.Getter(FHandleWnd);
   AmAtomic.Setter(FHandleWnd,0);
   AmAtomic.Setter(FHandleWndNeeded,false);
   if H>0 then
   DeallocateHWnd(H);
end;
procedure TAmObjectTask.PeekProcessMessage;
var msg : TMsg;
begin
    while PeekMessage(msg, 0, 0, 0, PM_REMOVE) do
    begin
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    end;
end;
procedure TAmObjectTask.PeekProcessMessagePublic;
begin
   PeekProcessMessage;
end;
procedure TAmObjectTask.HandleWndProcMessage;
begin
    if  HandleWndCheckCreate then
    PeekProcessMessage;
end;
function TAmObjectTask.PostMessageHandleWnd(Msg:Cardinal;W,L:Cardinal):boolean;
begin
     if HandleWndNeeded(60) then
     Result:=PostMessage(HandleWnd,Msg,W,L)
     else Result:=false;
end;
function TAmObjectTask.HandleWndNeeded(SecWaitFor: integer): boolean;
var Hd:Boolean;
    H:Cardinal;
begin
    H:= HandleWnd;
    Result:= H>0;
    if not Result then
    begin
        Hd:= AmAtomic.Getter(FHandleWndNeeded);
        if not Hd then
        begin
           Hd:=true;
           AmAtomic.Setter(FHandleWndNeeded,Hd);
        end;
        if SecWaitFor>0 then
        ToWaitFor.Go( SecWaitFor,
        function : boolean
        begin
          Result:=HandleWnd > 0;
        end);
        Result:=HandleWnd>0;
    end;

end;

function TAmObjectTask.GetIsRun:boolean;
begin
   Result:= FIsRun.Val;
end;
function TAmObjectTask.GetCurrentThreadIndiv:Cardinal;
var L:TAmTaskPoolMannager.TItem;
begin
    Result:=0;
    L:= GetCurrentThread;
    if Assigned(L) then
    Result:=L.IdIndiv;
end;
function TAmObjectTask.GetCurrentThread:TAmTaskPoolMannager.TItem;
begin
   Result:= AmAtomic.Lock.CompareExchange<TAmTaskPoolMannager.TItem>(FCurrentThread,nil,nil);
end;










               {TAmTaskPoolMannager.TItem}
constructor TAmTaskPoolMannager.TItem.Create(ASecondWaitForBeforeDestroyThread:Cardinal=180);
begin
    inherited Create(true);
    FSecondWaitForBeforeDestroyThread:= max(ASecondWaitForBeforeDestroyThread,1);
    FSignal:=TAmEvent.Create(true);
    FSignalStart:= TAmEvent.Create();
    FSenderObj:=nil;
    FSignalStart.ResetEvent;
    Fcs:=TAmCs.Create;
    FIdIndiv:=0;
end;
destructor  TAmTaskPoolMannager.TItem.Destroy;
begin
   inherited;
   FreeAndNil(FSignal);
   FreeAndNil(FSignalStart);
   FreeAndNil(Fcs);
end;
procedure   TAmTaskPoolMannager.TItem.Terminate;
begin
  inherited Terminate;
  FSignal.SetEvent;
end;
Function TAmTaskPoolMannager.TItem.GetIdIndiv:Cardinal;
begin
  Result:= AmAtomic.Getter(FIdIndiv);
end;
Procedure  TAmTaskPoolMannager.TItem.SetIdIndiv(const Value:Cardinal);
begin
   AmAtomic.Setter(FIdIndiv,Value);
end;
function TAmTaskPoolMannager.TItem.BeforeRun:boolean;
var R:TWaitResult;
begin
   Fcs.Enter;
   try
     FSignal.ResetEvent;
     FStatus:= amPoolTh_ProcReturn;
     FSignalStart.SetEvent;
   finally
    Fcs.Leave;
   end;
   Result:=false;
   R:=FSignal.WaitFor(FSecondWaitForBeforeDestroyThread * 1000);
   case R of
        wrSignaled:begin
           Result:=true;
           Fcs.Enter;
           try
             FStatus:= amPoolTh_ProcStart;
           finally
            Fcs.Leave;
           end;
        end;
        else begin
           Fcs.Enter;
           try
             if FStatus = amPoolTh_ProcRun then
             begin
                Result:=true;
                FStatus:= amPoolTh_ProcStart;
             end
             else
             begin
                 FStatus:=amPoolTh_NeedTerminated;
                 Quit:=true;
             end;
           finally
            Fcs.Leave;
           end;

        end;
   end;
end;
function TAmTaskPoolMannager.TItem.AfterRun:boolean;
var i:integer;
begin
  Result:=true;
  Mannager.CsList.Enter;
  try
     Fcs.Enter;
     try

       FStatus:= amPoolTh_ProcFinish;
       i:=Mannager.FListRun.IndexOfList(self) ;
       if i>=0 then
       begin
          Mannager.FListRun.Delete(i);
          Mannager.FListFree.Add(self);
       end;
       FSenderObj:=nil;
       FSignalStart.ResetEvent;
       FSignal.SetEvent;
     finally
      Fcs.Leave;
     end;
  finally
     Mannager.CsList.Leave;
  end;

end;
procedure TAmTaskPoolMannager.TItem.Run(Obj:TObject);
begin
   try
      if Obj is TAmObjectTask then
         TAmObjectTask(Obj).RunWithTask(self)
      else if Assigned(FOnSender) then
         FOnSender(Obj);
   except
   on e:exception do
            log('ErrorCode.TAmTaskPoolMannager.TItem.Run '+e.Message,e);
   end;
end;

procedure TAmTaskPoolMannager.TItem.Execute;
var R:boolean;
begin
   try
      ExecuteStart;
      try
        while not Quit do
        begin
           R:= BeforeRun;
           if Self.Terminated then
           break;
           try
             if R and Assigned(FSenderObj) then
             Run(FSenderObj);
           finally
             if R then             
              AfterRun;
           end;
        end;
      finally
        ExecuteFinish;
      end;
   except
     on e:exception do
            log('ErrorCode.TAmTaskPoolMannager.TItem.Execute '+e.Message,e);
   end;
end;
procedure TAmTaskPoolMannager.TItem.ExecuteStart;
begin
      Fcs.Enter;
      try
       FStatus:= amPoolTh_ExecuteStart;
      finally
       Fcs.Leave;
      end;
end;
procedure TAmTaskPoolMannager.TItem.ExecuteFinish;
var i:integer;
begin
    Mannager.CsList.Enter;
    try
        Fcs.Enter;
        try
         FStatus:= amPoolTh_ExecuteFinish;
         Quit:=true;
        finally
         Fcs.Leave;
        end;

        if Mannager.IsDestroing.Val then exit;

        i:=Mannager.FListRun.IndexOfList(self);
        if i>=0 then
        Mannager.FListRun.Delete(i);
        i:=Mannager.FListFree.IndexOfList(self);
        if i>=0 then
        Mannager.FListFree.Delete(i);
        i:=Mannager.FListAll.IndexOfList(self);
        if i>=0 then
        Mannager.FListAll.Delete(i);

        self.FreeOnTerminate:=true;
    finally
      Mannager.CsList.Leave;
    end;
end;



{ TAmTaskMannager }
function TAmTaskPoolMannager.GetThread(Obj:TObject):boolean;
var c,i,CountFree:integer;
var Item:TItem;
SleepResult:TWaitResult;
begin
   Result:=false;
   try
      CsList.Enter;
      try
          if IsDestroing.Val then exit;
          CountFree:=FListFree.Count;
      finally
         CsList.Leave;
      end;

      if (CountFree <= 0) then
      begin
          if FMilliSecondSleepBeforeNewCreateThread > 0 then
          begin
             SleepResult:=  CsDestroing.WaitFor(FMilliSecondSleepBeforeNewCreateThread);
             if SleepResult = TWaitResult.wrSignaled then
               exit;
          end;
      end;
      

      CsList.Enter;
      try
        if IsDestroing.Val then exit;
        c:=0;
        while (c < 2 ) and not Result do
        begin

          if (FListFree.Count <= 0) or (c > 0) then
          begin
              if (FListFree.Count<=0) then
              begin
                 if CreateNewThreads(1)<>1 then
                 begin
                    sleep(500);
                    if FListAll.Count>Integer(FCountMaxThread) then
                    begin
                      log('TAmPoolThreadMannager.CreateNewThreads потоков слишком много FCountMaxThread='+FCountMaxThread.ToString);
                      exit;
                    end
                    else
                     log('TAmTaskPoolMannager.GetThread не удлось создать поток create<>1');
                 end;
                // sleep(10);
              end;
          end;


          for I := FListFree.Count-1 downto 0 do
          begin
            Item:= FListFree[i];
            Item.Fcs.Enter;
            try

              if Item.FStatus  <> amPoolTh_ProcReturn then
              begin
                //log('while '+amusertype.AmEnumConverter.EnumToString(Item.FStatus));
                continue;
              end;
              Result:=true;
              Item.FSenderObj:=Obj;
              FListFree.Delete(I);
              FListRun.Add(Item);
              Item.FStatus :=amPoolTh_ProcRun;
              Item.FSignal.SetEvent;
              sleep(10);
              //добавил 10 ms что бы успела выполнится TAmObjectTask.BeforeRun или какая другая инициализация
              // это не критически но всеже надежнее
               exit;
            finally
              Item.Fcs.Leave;
            end;
          end;
          if c>=1 then
          sleep(500);
          inc(c);
        end;
      finally
        CsList.Leave;
      end;

   except
    on e: exception do
      log('ErrorCode.TAmPoolThreadMannager.GetThreadProc '+e.Message,e);
   end;
end;
function TAmTaskPoolMannager.GetNewIndiv:Cardinal;
begin
  repeat
    Result := AmAtomic.Inc(FCounterIdItem);
  until Result <> 0;
end;
function TAmTaskPoolMannager.CreateNewThreads(Count:integer):integer;
var Item:TItem;
i:integer;
R:boolean;
begin
  Result:=0;
  CsList.Enter;
  Item:=nil;
  R:=false;
  try
     try
         if IsDestroing.Val then
          exit;
         for I := 0 to Count-1 do
         begin

              if FListAll.Count > Integer(FCountMaxThread) then
              begin
                log('TAmPoolThreadMannager.CreateNewThreads потоков слишком много FCountMaxThread='+FCountMaxThread.ToString);
                exit;
              end;
              
              try
                Item:=TItem.Create(FSecondWaitForBeforeDestroyThread);
              except
                if not R and Assigned(Item) then
                FreeAndNil(Item);
                log('TAmPoolThreadMannager.CreateNewThreads удаление не удалось создать поток');
                exit;
              end;


              FListAll.Add(Item);
              Item.FOnSender :=FOnRunNewThread;
              Item.Mannager:=self;
              Item.SetIdIndiv(GetNewIndiv);
              Item.OnLog:=LogEvent;
             // Item.OnTimeOutWaitFor:= EventTimeOutWaitFor;
            //  Item.OnStartProc:=      EventProcStart;
            //  Item.OnFinishProc:=     EventProcFinish;
            //  Item.OnStartThread:=    EventStartThread;
            //  Item.OnFinishThread:=   EventFinishThread;
              Item.Start;
              Item.FSignalStart.WaitFor(INFINITE); // ждем пока поток запустится
              FListFree.Add(Item);
              R:=true;
              inc(Result);
         end;
     except
        on e:exception do
        begin
            log('ErrorCode.TAsmPoolThreadMannager.CreateNewThreads Не удалось cоздать поток '+e.Message,e);
            try
              if not R and Assigned(Item) then
              FreeAndNil(Item);
            except
               log('ErrorCode.TAsmPoolThreadMannager.CreateNewThreads Не удалось удалить Item ');
            end;
        end;
     end;
  finally
    CsList.Leave;
  end;
end;
procedure TAmTaskPoolMannager.Clear(isDestoing:boolean);
var i:integer;
New:TAmListVar<TItem>;
begin

  cslist.Enter;
  try
    if isDestoing then
    SetDestroing(isDestoing);
    IsDestroing.Val:=true;
    CsDestroing.SetEvent;
    FListFree.Clear();
    FListRun.Clear();

    for I := 0 to FListAll.Count-1 do
    begin
      FListAll[i].Terminate;
      New.Add(FListAll[i]);
    end;
    FListAll.Clear();
  finally
     cslist.Leave;
  end;

  for I := 0 to New.Count-1 do
   New[i].WaitFor;
  for I := 0 to New.Count-1 do
    New[i].Free;
  New.Free;

end;

constructor TAmTaskPoolMannager.Create();
begin
  inherited Create;
  IsDestroing:=TAmVarCs<boolean>.create;
  IsDestroing.Val:=false;
  CsList:=TAmcs.Create;
  FListAll.Init;
  FListFree.Init;
  FListRun.Init;
  FSecondWaitForBeforeDestroyThread:=250;
  FMilliSecondSleepBeforeNewCreateThread:=20;
  CsDestroing:=TAmEvent.Create(true);
  CsDestroing.ResetEvent;
  FCounterIdItem:=0;
  FCountMaxThread:=1000;
  Cache_CountAll:=0;
  Cache_CountFree:=0;
  Cache_CountRun:=0;
end;
procedure TAmTaskPoolMannager.SetDestroing(Value:boolean);
begin
  CsList.Enter;
  try
    if Value then
    begin
      IsDestroing.Val:=true;
      CsDestroing.SetEvent;
    end
    else
    begin
      IsDestroing.Val:=false;
      CsDestroing.ResetEvent;
    end;
    

  finally
     CsList.Leave;
  end;
end;
destructor TAmTaskPoolMannager.Destroy;
begin
  Clear;
  inherited;
  FreeAndNil(CsList);
  FreeAndNil(CsDestroing);
  FreeAndNil(IsDestroing);
end;
function TAmTaskPoolMannager.GetCountListAll(NotLock:boolean):integer;
begin

  if NotLock then
  begin 
     if CsList.TryEnter then
     begin
        try
           Result:=  FListAll.Count;
           Cache_CountAll:= Result;
        finally
           CsList.Leave;
        end;
     end
     else
       Result:= Cache_CountAll;
  end
  else
  begin
    CsList.Enter;
    try
       Result:=  FListAll.Count;
    finally
       CsList.Leave;
    end;  
  end;

end;
function TAmTaskPoolMannager.GetCountListFree(NotLock:boolean):integer;
begin
  if NotLock then
  begin
     if CsList.TryEnter then
     begin
        try
           Result:=  FListFree.Count;
           Cache_CountFree:= Result;
        finally
           CsList.Leave;
        end;
     end
     else
       Result:= Cache_CountFree;
  end
  else
  begin
    CsList.Enter;
    try
       Result:=  FListFree.Count;
    finally
       CsList.Leave;
    end;  
  end;

end;
function TAmTaskPoolMannager.GetCountListRun(NotLock:boolean):integer;
begin
  if NotLock then
  begin 
     if CsList.TryEnter then
     begin
        try
           Result:=  FListRun.Count;
           Cache_CountRun:= Result;
        finally
           CsList.Leave;
        end;
     end
     else
      Result:= Cache_CountRun;
  end
  else
  begin
    CsList.Enter;
    try
       Result:=  FListRun.Count;
    finally
       CsList.Leave;
    end;  
  end;
end;










{ TAmListObjectTask }
constructor TAmListObjectTaskMini.Create;
begin
  inherited Create;
  FList:= TAmListObjTaskMini.Create;
  FList.Cs;
end;

destructor TAmListObjectTaskMini.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

function TAmListObjectTaskMini.ListCountGet: integer;
begin
  Lock;
  try
     Result:= List.Count;
  finally
    UnLock;
  end;
end;

function TAmListObjectTaskMini.ListGet: TAmListObjTaskMini;
begin
  Result:= AmAtomic.Getter<TAmListObjTaskMini>(FList);
end;
function TAmListObjectTaskMini.Add(Value:TAmObjectTaskMini):boolean;
var L:TAmListObjTaskMini;
begin
    Result:= not DestroyingObject;
    if Result then
    begin
          Lock;
          try
            L:= List;
            Value.FreeOnTerminate:=true;
            L.Add(Value);
          finally
            UnLock;
          end;
    end;
end;
procedure TAmListObjectTaskMini.Delete(Value:TAmObjectTaskMini);
var L:TAmListObjTaskMini;
i:integer;
R:boolean;
begin
    R:= not DestroyingObject;
    if R then
    begin
          Lock;
          try
            L:= List;
            i:=L.SerchObject(Value);
            if i>=0 then
            L.Delete(i);
          finally
            UnLock;
          end;
    end;
end;


procedure TAmListObjectTaskMini.Clear;
var Old,New:TAmListObjTaskMini;
  I: Integer;
begin
  New:=  TAmListObjTaskMini.Create;
  try
     // копируем у другой лист все объекты
     // что бы освободить cs ставим всем FreeOnTerminate:=false;
     // и ждем окончания

    Lock;
    try
       Old:= List;
       New.Capacity:=Old.Count;
       for I := 0 to Old.Count-1 do
       begin
         Old[i].FreeOnTerminate:=false;
         Old[i].Terminate;
         New.Add(Old[i]);
       end;
       Old.Clear;
    finally
      UnLock;
    end;

    for I := 0 to New.Count-1 do
      New[i].WaitFor;
    sleep(5);
    for I := 0 to New.Count-1 do
      New[i].Free;
    New.Clear;
  finally
    New.Free;
  end;
end;



{ TAmObjectTaskMini }

constructor TAmObjectTaskMini.Create(AMiniThreadList: TAmListObjectTaskMini);
begin
 inherited Create;
 FList:=AMiniThreadList;
 FFreeOnTerminate:=true;
 if Assigned(FList) then
  FList.Add(self);
end;

destructor TAmObjectTaskMini.Destroy;
begin
   if Assigned(FList) then
   FList.Delete(self);
   FList:=nil;
  inherited;
end;
procedure TAmObjectTaskMini.ControlWantsTerminateThread;
begin
   if IsRun then
   begin
     FreeOnTerminate:=false;
     Terminate;
     WaitFor;
   end;
end;

{ TAmObjectTaskMiniForOtherObj }

constructor TAmObjectTaskMiniForOtherObj.Create(AMiniThreadList: TAmListObjectTaskMini;
                                               AClient: TAmObjectTask);
begin
   inherited Create(AMiniThreadList);
   FClient:=AClient;
   FLockCount:=0;
   if Assigned(FClient) then
   begin
     FClient.OnTerminatedExternally:= ClientTerminatedExternally;
     FClient.OnTerminate:= ClientTerminate;
   end;
end;

destructor TAmObjectTaskMiniForOtherObj.Destroy;
begin
  ClientClear;
  inherited;
end;
function TAmObjectTaskMiniForOtherObj.ClientClear:TAmObjectTask;
begin
   Result:=AmAtomic.Lock.CompareExchange<TAmObjectTask>(FClient,nil,ClientGet);
end;
function TAmObjectTaskMiniForOtherObj.ClientGet: TAmObjectTask;
begin
  Result:=AmAtomic.Getter<TAmObjectTask>(FClient);
end;
procedure TAmObjectTaskMiniForOtherObj.ClientTerminatedExternally(
  AClient: Tobject; var V: boolean);
begin
  V:= V or self.Terminated;
end;


procedure TAmObjectTaskMiniForOtherObj.ClientTerminate(AClient:Tobject);
var I:Integer;
begin
    I:=AmAtomic.Lock.Increment(FLockCount);
    try
      if I<=1 then
        inherited Terminate;
    finally
       AmAtomic.Lock.Decrement(FLockCount);
    end;
end;

procedure TAmObjectTaskMiniForOtherObj.Terminate;
var I:Integer;
begin
    I:=AmAtomic.Lock.Increment(FLockCount);
    try
      if I<=1 then
      begin
        if Assigned(FClient) then
        FClient.Terminate;
        inherited Terminate;
      end;
    finally
       AmAtomic.Lock.Decrement(FLockCount);
    end;
end;
procedure TAmObjectTaskMiniForOtherObj.Run;
begin
  inherited;
end;


var  LPoolThreadMannager: TAmTaskPoolMannager = nil;
function  PoolThreadMannager:TAmTaskPoolMannager;
begin
  Result:=AmAtomic.Getter<TAmTaskPoolMannager>(LPoolThreadMannager);
end;
procedure PoolThreadMannagerCreate;
begin
   LPoolThreadMannager:=  TAmTaskPoolMannager.Create;
   LPoolThreadMannager.SecondWaitForBeforeDestroyThread:=250;
   LPoolThreadMannager.MilliSecondSleepBeforeNewCreateThread:=20;
   LPoolThreadMannager.CountMaxThread:=1000;
end;
procedure PoolThreadMannagerDestroy;
begin
   if Assigned(LPoolThreadMannager) then
   FreeAndNil(LPoolThreadMannager);
end;

initialization
begin
    PoolThreadMannagerCreate;
end;
finalization
begin
   PoolThreadMannagerDestroy;
end;

end.
