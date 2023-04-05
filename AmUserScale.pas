unit AmUserScale;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms;
type

  {
    что бы AmUserScale  работал
    procedure TFormMain.FormCreate(Sender: TObject);
    begin
      AmUserScale.AmScale.Init(твое значение с базы или пусто);
    end;
    procedure TFormMain.FormShow(Sender: TObject);
    begin
      AmUserScale.AmScale.Show;
    end;
    procedure TFormMain.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
    NewDPI: Integer);
    begin
      AmUserScale.AmScale.BeforeMonitorDpiChanged(NewDPI,OldDPI);
    end;
    procedure TFormMain.FormBeforeMonitorDpiChanged(Sender: TObject; OldDPI,
    NewDPI: Integer);
    begin
      AmUserScale.AmScale.AfterMonitorDpiChanged(NewDPI,OldDPI);
    end;

    небольшое замечание по динамическому созданию котролов
    после TWinControl.Create
    и до уставновки Parent
    нужно ставить значения высот обычно т.е
    P:=TPanel.Create(self);
    P.ParentFont:=false;
    P.height:=  88;
    P.Font.Size := 8;
    P.parent:=self;



    если изменяем после установки  Parent то
    P.height:=  AmScaleV(88);
    P.Font.Height := AmScaleF(8); 8 это Forn.Size

    что бы постоянно не проверять  наличие Parent можно
    P.height:=  AmScaleV(88,P);
    P.Font.Height := AmScaleF(8,P);// передали Size получили  Height и только так


    иной вариант это устанонить значения без AmScaleV а после вызвать
    AmScale.DinamicScaleApp(P);
  }

  AmScale = class
  private
    class procedure SetScaleAppCustom(New, Old: integer);
    // class procedure MessageEventChangeDpi(Self:TObject; const Sender: TObject; const M: TMessage);static;
    // const  MessageEventChangeDpiMethod: TMethod = (Code: @AmScale.MessageEventChangeDpi; Data: nil);
  protected

  public
    // хранит значение  маштаба по умолчанию
    // AppScaleDesing рекомедую выставить в 100 при создании формы а не здесь
    // WinScaleDPIDesing рекомедую выстовить в 96 при создании формы что равно WinApi.Windows.USER_DEFAULT_SCREEN_DPI  а не здесь
    // эти значения нужно выставить после AmScale.Init;

    // если вы разрабатываете прогу и у вас на компе глобальный маштаб 120 то его и установите по умолчанию в WinScaleDPIDesing
    // если у вас всегда глобальный маштаб 96 то ничего устанавливать не нужно см initialization и  AmScale.Init;

    class var AppScaleDesing: integer; // какой маштаб был на этапе разработки
    class var AppScaleNow: integer; // какой маштаб сейчас в приложении
    class var WinScaleDPIDesing: integer;
    // какой глобальный маштаб системы был  на этапе разработки
    class var WinScaleDPINow: integer;
    // какой глобальный маштаб системы сейчас в приложении
    class var IsInit: boolean; // Init была выполнены
    class var IsShow: boolean; // Show была выполнены
    class var IsShowning: boolean; // сейчас выполняется Show
    class var IsAppScaled: boolean; // сейчас выполняется SetScaleAppCustom
    class var IsWinScaled: boolean;
    // сейчас выполняется WinScaled есть 2 события на форме к ним подключится FormAfterMonitorDpiChanged FormBeforeMonitorDpiChanged

    // при создании главной формы запустить Init
    // можно передать параметр сохраненного маштаба приложения например с какой то базы данных
    // это процент от 30 до 200 обычно это 100 процентов от размера приложения на этапе разработки
    class procedure Init(ASavedProcent: integer = 100);

    // в собыитии FormShow запустить Show
    class procedure Show;

    // запустить в событии главной формы FormBeforeMonitorDpiChanged
    // проиходит когда в системе глобально меняется маштаб
    class procedure BeforeMonitorDpiChanged(NewDPI, OldDPI: integer);
    // запустить в событии главной формы FormAfterMonitorDpiChanged
    // проиходит когда в системе глобально меняется маштаб
    class procedure AfterMonitorDpiChanged(NewDPI, OldDPI: integer);

    // .............................................................
    // Dynamic использовать для динамически создоваемых контролов
    // вначале контролу установить parent а потом value
    // получить новое значение размера для числа val смотрите ниже описание
    // если кратко то  P:=Tpanel.create(self); P.height:=  AmScale.DinamicValue(88);
    class function DynamicValue(val: integer; ForControl: TControl = nil): integer; static;
    // для font.Height := AmScale.DinamicValueFontSize(10);
    // получилось сделать только для font.Height c входным параметром  Font.Size
    // т.к все уперается в матиматику  округления  маленький диапозон  Font.Size  и формулу Font.Size и  font.Height
    class function DynamicValueFontHeight(FontSize: integer; ForControl: TControl = nil): integer; static;
    // .........................................................

    // value с плавающей запятой
    class function DynamicValueNoRound(val: Double; ForControl: TControl = nil) : Double; static;

    // если не использовали для каждого значения DynamicValue
    // то по окончанию создания контрола вызвать
    // DinamicScaleApp это маштаб приложения
    // DinamicScaleWin глобальный маштаб
    class procedure DynamicScaleApp(Control: TWinControl); static;
    class procedure DynamicScaleWin(Control: TWinControl); static;

    // что бы font не был огромным можно его скоректировать
    class function DinamicValueFontSizeCorrect(val: integer): integer; static;

    // конвертация font для текущего маштаба
    class function FontSizeToHeight(val: integer): integer; static;
    class function FontHeightToSize(val: integer): integer; static;

    // ChangeScaleValue
    // есть случаи когда в контроле есть какие-то переменные
    // которые не изменяются при изменении маштаба хотя в вашей логике это заложено
    // например некая переменная ширины другого контрола в текущем или какая константа высоты всех элементов скрол бокса
    // в этот случаи в этом контроле нужно в protected перегрузить процедуру

    //   protected
    //   procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;

    // и посчитать новое значение
    //  inherited;
    //  HTest:= AmScale.ChangeScaleValue(HTest,M, D);
    class function ChangeScaleValue(valOld: integer; M, D: integer) : integer; static;

    // если хотим поменять мастаб всего приложения  SetScaleApp(120,100) увеличится на 20%
    class procedure SetScaleApp(New: integer; Old: integer = 0);

    // получить список для юзера возможных маштабов приложения
    class procedure GetAppToList(L: TStrings);

    // у вас есть значение но не знаете индек его в списке  = найдите
    class function GetIndexFromList(L: TStrings; value: integer = 0): integer;

    // получить значение с строки которая была  получена в GetAppToList
    class function GetValueFromStr(S: String): integer;

    // изменить маштаб когда юзер выбрал новое значение из списка
    class procedure SetAppFromListInt(New: integer);

    // передать одну линию со списка полученного в GetAppToList
    class procedure SetAppFromList(S: String);
  end;

function UserMainScale(val: integer): integer;
function AmScaleV(ValuePosition: integer; ForControl: TControl = nil): integer;
function AmScaleD(ValuePosition: Double; ForControl: TControl = nil): Double;
function AmScaleF(FontSize: integer; ForControl: TControl = nil): integer;

implementation

type
  TLocContrrol = class(TControl);

  { AmScale }
function UserMainScale(val: integer): integer;
begin
  Result := AmScale.DynamicValue(val);
end;

function AmScaleV(ValuePosition: integer; ForControl: TControl = nil): integer;
begin
  Result := AmScale.DynamicValue(ValuePosition, ForControl);
end;

function AmScaleD(ValuePosition: Double; ForControl: TControl = nil): Double;
begin
  Result := AmScale.DynamicValueNoRound(ValuePosition, ForControl);
end;

function AmScaleF(FontSize: integer; ForControl: TControl = nil): integer;
begin
  Result := AmScale.DynamicValueFontHeight(FontSize, ForControl);
end;

class procedure AmScale.GetAppToList(L: TStrings);
begin
  L.Clear;
  if not IsInit then
    exit;
  // L.Add('50 %');
  L.Add('75 %');
  // L.Add('85 %');
  L.Add('100 % (рекомедуется)');
  // L.Add('115 %');
  L.Add('125 %');
  L.Add('150 %');
  L.Add('175 %');
  L.Add('200 %');
end;

class function AmScale.GetIndexFromList(L: TStrings;
  value: integer = 0): integer;
begin
  Result := -1;
  if not IsInit then
    exit;
  if value < 30 then
    value := AppScaleNow;
  for Result := 0 to L.Count - 1 do
    if GetValueFromStr(L[Result]) = value then
      exit;
  Result := -1;
end;

class function AmScale.GetValueFromStr(S: String): integer;
var
  tok: integer;
begin
  Result := 0;
  if not IsInit then
    exit;
  tok := pos(' ', S);
  if (tok <> 1) and (tok <> 0) then
  begin
    S := S.Split([' '])[0];
    TryStrToInt(S, Result);
  end;
end;

class procedure AmScale.SetAppFromList(S: String);
begin
  if not IsInit then
    exit;
  SetAppFromListInt(GetValueFromStr(S));
end;

class procedure AmScale.SetAppFromListInt(New: integer);
begin
  if not IsInit then
    exit;
  SetScaleApp(New, AppScaleNow);
end;

class procedure AmScale.SetScaleApp(New: integer; Old: integer = 0);
begin
  if not IsInit then
    exit;
  if New < 30 then
    exit;
  if Old < 30 then
    Old := AppScaleNow;
  if Old < 30 then
    exit;

  if New <> AppScaleNow then
  begin
    AppScaleNow := New;
    SetScaleAppCustom(New, Old);
  end;
end;

class procedure AmScale.SetScaleAppCustom(New, Old: integer);
var
  i: integer;
begin
  if IsAppScaled then
    exit;
  IsAppScaled := true;
  try
    for i := 0 to Screen.FormCount - 1 do
      Screen.Forms[i].ScaleBy(New, Old);
  finally
    IsAppScaled := false;
  end;
end;

class procedure AmScale.Show;
begin
  if not IsInit then
    exit;
  if not IsShow then
  begin
    IsShow := true;
    if IsShowning then
      exit;
    IsShowning := true;
    try
      SetScaleAppCustom(AppScaleNow, AppScaleDesing);
    finally
      IsShowning := false;
    end;
  end;
end;

class procedure AmScale.BeforeMonitorDpiChanged(NewDPI, OldDPI: integer);
begin
  IsWinScaled := true;
  WinScaleDPINow := NewDPI;
end;

class procedure AmScale.AfterMonitorDpiChanged(NewDPI, OldDPI: integer);
begin
  WinScaleDPINow := NewDPI;
  IsWinScaled := false;
end;

class procedure AmScale.Init(ASavedProcent: integer = 100);
var
  LMonitor: TMonitor;
begin
  if ASavedProcent <= 30 then
    ASavedProcent := 100;
  if ASavedProcent > 300 then
    ASavedProcent := 300;
  AppScaleDesing := 100;
  AppScaleNow := ASavedProcent;

  WinScaleDPINow := USER_DEFAULT_SCREEN_DPI;
  WinScaleDPIDesing := USER_DEFAULT_SCREEN_DPI;

  if (Application <> nil) and (Screen <> nil) then
  begin
    LMonitor := Screen.MonitorFromWindow(Application.Handle);
    if LMonitor <> nil then
      WinScaleDPINow := LMonitor.PixelsPerInch
    else
      WinScaleDPINow := Screen.PixelsPerInch;
    {
      LForm := Application.MainForm;
      if (LForm <> nil)  then
      WinScaleDPIDesing := LForm.PixelsPerInch;
    }

  end
  else if (Screen <> nil) and (Mouse <> nil) then
  begin
    LMonitor := Screen.MonitorFromPoint(Mouse.CursorPos);
    if LMonitor <> nil then
      WinScaleDPINow := LMonitor.PixelsPerInch
    else
      WinScaleDPINow := Screen.PixelsPerInch;
    {
      LForm := Application.MainForm;
      if (LForm <> nil)  then
      WinScaleDPIDesing := LForm.PixelsPerInch;
    }
  end;
  // TMessageManager.DefaultManager.SubscribeToMessage(TChangeScaleMessage,TMessageListenerMethod(MessageEventChangeDpiMethod));
  IsInit := true;
end;
{
  class procedure AmScale.MessageEventChangeDpi(Self:TObject; const Sender: TObject; const M: TMessage);
  begin
  if  M is  TChangeScaleMessage then
  begin
  if TChangeScaleMessage(M).Sender = Application.MainForm  then
  BeforeMonitorDpiChanged(TChangeScaleMessage(M).M,TChangeScaleMessage(M).D);

  end;
  end;
}

class procedure AmScale.DynamicScaleWin(Control: TWinControl);
begin
  if not IsInit then
    exit;
  if (Control.Parent <> nil) and (WinScaleDPINow <> WinScaleDPIDesing) then
    Control.ScaleBy(WinScaleDPINow, WinScaleDPIDesing);
end;

class procedure AmScale.DynamicScaleApp(Control: TWinControl);
begin
  if not IsInit then
    exit;
  if IsShow and (AppScaleNow <> AppScaleDesing) then
    Control.ScaleBy(AppScaleNow, AppScaleDesing);
end;

function __ControlWindowCreate(Control: TControl): boolean;
begin
  Result := false;
  if Assigned(Control) then
  begin
    if Control is TWinControl then
      Result := TWinControl(Control).HandleAllocated
    else if Control.Parent <> nil then
      Result := Control.Parent.HandleAllocated;
  end;

end;

class function AmScale.DynamicValue(val: integer;
  ForControl: TControl = nil): integer;
begin
  Result := val;
  if not IsInit or (val = 0) then
    exit;
  if Assigned(ForControl) and not __ControlWindowCreate(ForControl) then
    exit;

  if (WinScaleDPINow <> WinScaleDPIDesing) then
    Result := MulDiv(Result, WinScaleDPINow, WinScaleDPIDesing);

  if IsShow and (AppScaleNow <> AppScaleDesing) then
    Result := MulDiv(Result, AppScaleNow, AppScaleDesing);

end;

class function AmScale.DynamicValueNoRound(val: Double;
  ForControl: TControl = nil): Double;
begin
  Result := val;
  if not IsInit or (val = 0) then
    exit;
  if Assigned(ForControl) and not __ControlWindowCreate(ForControl) then
    exit;

  if (WinScaleDPINow <> WinScaleDPIDesing) then
    Result := Result * WinScaleDPINow / WinScaleDPIDesing;

  if IsShow and (AppScaleNow <> AppScaleDesing) then
    Result := Result * AppScaleNow / AppScaleDesing;

end;

class function AmScale.DynamicValueFontHeight(FontSize: integer; ForControl: TControl = nil): integer;
var
  D, N: integer;
begin
  if FontSize = 0 then
    exit(0);

  if not IsInit or ( Assigned(ForControl) and not __ControlWindowCreate(ForControl) ) then
  begin
    Result := FontSizeToHeight(FontSize);
    exit;
  end;

  D := WinScaleDPIDesing;
  N := WinScaleDPINow;
  Result := -MulDiv(FontSize, D, 72); // convert Font.Size to Font.Height

  if (N <> D) then
    Result := MulDiv(Result, N, D);

  if IsShow and (AppScaleNow <> AppScaleDesing) then
   Result := MulDiv(Result, AppScaleNow, AppScaleDesing);



  // Result := -MulDiv(Result, 72, Screen.PixelsPerInch);// convert  Font.Height To Font.Size с учетом маштаба при запуске программы

  // D:=-MulDiv(Result, Screen.PixelsPerInch, 72);
  // r:=-(val*Screen.PixelsPerInch/72); // convert Font.Size to Font.Height
  // r:=SimpleRoundTo(r,0);
  // r:=DinamicValueNoRound(r);
  // r:=SimpleRoundTo(r,0);
  // Result:=Round(r);
  // Result:= -MulDiv(Result, 72, Screen.PixelsPerInch);
  // r := -(r*72/Screen.PixelsPerInch);// convert  Font.Height To Font.Size с учетом маштаба при запуске программы
  // Result := Round( SimpleRoundTo(r,0) );
  //
  //  D:=WinScaleDPIDesing;
  //  Result:=-MulDiv(val, D ,72); // convert Font.Size to Font.Height
  //  Result:=DinamicValue(Result);
  //  Result := -MulDiv(Result, 72, Screen.PixelsPerInch);// convert  Font.Height To Font.Size с учетом маштаба при запуске программы

end;

class function AmScale.DinamicValueFontSizeCorrect(val: integer): integer;
var
  D: integer;
begin
  D := WinScaleDPIDesing;
  Result := -MulDiv(val, D, 72); // convert Font.Size to Font.Height
  Result := -MulDiv(Result, 72, Screen.PixelsPerInch);
  // convert  Font.Height To Font.Size с учетом маштаба при запуске программы
end;

class function AmScale.ChangeScaleValue(valOld: integer; M, D: integer)
  : integer;
begin
  if not IsInit or (valOld = 0) then
    exit(valOld);
  Result := MulDiv(valOld, M, D);
end;

class function AmScale.FontHeightToSize(val: integer): integer;
begin
  Result := val;
  Result := -MulDiv(Result, 72, Screen.PixelsPerInch);
  // convert  Font.Height To Font.Size
end;

class function AmScale.FontSizeToHeight(val: integer): integer;
begin
  Result := -MulDiv(val, Screen.PixelsPerInch, 72);
  // convert Font.Size to Font.Height
end;

initialization
begin
  AmScale.AppScaleDesing := 100;
  AmScale.AppScaleNow := 100;
  AmScale.WinScaleDPIDesing := Winapi.Windows.USER_DEFAULT_SCREEN_DPI;
  AmScale.WinScaleDPINow := Winapi.Windows.USER_DEFAULT_SCREEN_DPI;
  AmScale.IsInit := false;
  AmScale.IsShow := false;
  AmScale.IsShowning := false;
  AmScale.IsAppScaled := false;
  AmScale.IsWinScaled := false;
end;

finalization
begin
  // TMessageManager.DefaultManager
  //.Unsubscribe(TChangeScaleMessage,TMessageListenerMethod(AmScale.MessageEventChangeDpiMethod));
end;

end.
