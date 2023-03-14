unit AmComboBox;

interface
uses
  Winapi.Windows,Winapi.Messages,
  Winapi.CommCtrl,
  System.SysUtils,
  Types,
  UITypes,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  System.Generics.Collections,
  Math,
  TypInfo,
  AmUserScale,
  AmsystemBase,
  AmControlClasses,
  AmScrollBar,
  AmListBox,AmButton,AmPanel,AmLayBase,AmMenu,
  AmGraphic.Canvas.Help;


  type
   TAmComboCaptionClass = class of TAmComboCaptionCustom;
   TAmComboDropClass = class of  TAmComboDropCustom;
   TAmComboAbstract = class;
   TAmComboDropCustom= class;

   TAmComboCaptionCustom  = class abstract(TComponent)
    private
      FCombo: TAmComboAbstract;
    protected
      procedure CaptionSet(const Value:TCaption);virtual;abstract;
      function CaptionGet():TCaption;virtual;abstract;
      property Combo: TAmComboAbstract read FCombo;
      procedure ChangeDropIndex(Drop:TAmComboDropCustom;Index:integer);virtual;abstract;
      procedure ChangeParentCombo;virtual;abstract;
      procedure ChangeNameCombo;virtual;abstract;
      procedure ChangeSizeCombo;virtual;abstract;
    public
      Constructor Create(AOwner:TAmComboAbstract);reintroduce;virtual;
      destructor Destroy;override;
      property Caption: TCaption read CaptionGet write CaptionSet;
   end;

   TAmComboButton   =  class  (TAmButton)
      protected
       procedure Paint;override;
      public
       function ClientRectContent:TRect;override;
   end;

   TAmComboCaptionButton  = class  (TAmComboCaptionCustom)
    private
      FBut:TAmComboButton;
    protected
      procedure CaptionSet(const Value:TCaption);override;
      function CaptionGet():TCaption;override;
      procedure ChangeDropIndex(Drop:TAmComboDropCustom;Index:integer);override;
      procedure ButClick(Sender:TObject);dynamic;
      procedure ChangeParentCombo;override;
      procedure ChangeNameCombo; override;
      procedure ChangeSizeCombo;override;
    public
      Constructor Create(AOwner:TAmComboAbstract);override;
      destructor Destroy;override;
      property But: TAmComboButton read FBut;
   end;


   TAmComboDropCustom = class abstract(TComponent)
     private
      FCombo: TAmComboAbstract;
      FLay:TAmLayout;
      FPopup:TAmPopupControl;

      procedure PopapClose(Sender:TObject);
     protected

      procedure ItemIndexSet(const Value: integer); virtual; abstract;
      function ItemIndexGet: integer;  virtual;  abstract;
      procedure  ItemsSet(Index:integer;const Value:string);virtual;abstract;
      function ItemsGet(Index:integer):string;virtual;abstract;
      procedure ObjectsSet(Index:integer;const Value:TObject);virtual;abstract;
      function  ObjectsGet(Index:integer):TObject;virtual;abstract;
      property Combo: TAmComboAbstract read FCombo;
      procedure ChangeIndex();dynamic;
      procedure CloseUp;dynamic;
      procedure OpenUp;dynamic;
      procedure ChangeParentCombo;virtual;
      procedure ChangeNameCombo;virtual;
      procedure ChangeSizeCombo;virtual;
      property Popup: TAmPopupControl read FPopup;
      property Lay: TAmLayout read FLay;
     public
      Constructor Create(AOwner:TAmComboAbstract);reintroduce;virtual;
      destructor Destroy;override;
      property Items[index:integer]: string read ItemsGet write ItemsSet;
      property Objects[index:integer]: TObject read ObjectsGet write ObjectsSet;
      property ItemIndex: integer read ItemIndexGet write ItemIndexSet;

      procedure Open;dynamic;
      procedure Close;dynamic;

   end;


   TAmComboDropLBLink = class (TAmComboDropCustom)
     private
      type
        TSavePrmLb = record
          Al:TAlign;
          Visible:boolean;
          Parent:TWinControl;
          Md:TMouseEvent;
        end;
      var
      [weak]FListBox:TCustomListBox;
      FSave:TSavePrmLb;
      FItemIndexSave:integer;
      procedure LbChange(Sender:TObject;Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
      procedure ListBoxSet(const Value: TCustomListBox);
     protected
      procedure OpenUp;override;
      procedure CloseUp;override;
      procedure ChangeParentCombo;override;
      procedure ItemIndexSet(const Value: integer); override;
      function ItemIndexGet: integer;  override;
      procedure Notification(AComponent: TComponent; Operation: TOperation); override;
      procedure ItemsSet(Index:integer;const Value:string);override;
      function ItemsGet(Index:integer):string;override;
      procedure  ObjectsSet(Index:integer;const Value:TObject);override;
      function ObjectsGet(Index:integer):TObject;override;
     public
      constructor Create(AOwner:TAmComboAbstract);override;
      destructor Destroy;override;
      property ListBox: TCustomListBox read FListBox write ListBoxSet;
   end;





   TAmComboChange = procedure (Sender:TObject;Index:integer) of object;
   TAmComboSetCaption = procedure (Sender:TObject;Index:integer;Var CanContinue:boolean) of object;

   TAmComboAbstract  = class abstract(TAmLayBase)
    private
      [weak]FComboCaption:TAmComboCaptionCustom;
      [weak]FComboDrop:TAmComboDropCustom;
      FChangeIndex:TAmComboChange;
      FChange:TNotifyEvent;
      FOnDropDown:TNotifyEvent;
      FOnDropClose: TNotifyEvent;
      FDropAutoClose:boolean;
      FOnSetCaption:TAmComboSetCaption;
      FDropedState:boolean;
      FDropResetSession:boolean;
      FDropStateSessionChanged:boolean;
      FCloseLock:integer;
      FCloseLastTime:Cardinal;
      function ItemCaptionGet: TCaption;
      procedure ItemCaptionSet(const Value: TCaption);
      function ItemIndexGet: integer;
      procedure ItemIndexSet( Value: integer);
      function DropAnimateGet: TAmWinAnimateEnum;
      procedure DropAnimateSet(const Value: TAmWinAnimateEnum);
      function DropAnimateTimeGet: integer;
      procedure DropAnimateTimeSet(const Value: integer);
      function DropCanMoveGet: boolean;
      procedure DropCanMoveSet(const Value: boolean);
      function DropCanResizeGet: boolean;
      procedure DropCanResizeSet(const Value: boolean);
      function DropColorGet: TColor;
      procedure DropColorSet(const Value: TColor);
      function DropPaddingSizeGet: integer;
      procedure DropPaddingSizeSet(const Value: integer);
      procedure DropedStateSet(const Value: boolean);
      procedure DropResetSessionSet(const Value: boolean);
    protected
      procedure SetParent(W:TWinControl);override;
      procedure SetName(const NewName: TComponentName);override;
      procedure Resize;override;
      procedure ComboDropSet(const Value: TAmComboDropCustom);virtual;
      procedure ComboCaptionSet(const Value: TAmComboCaptionCustom); virtual;
      procedure ChangeIndex(Index:integer);dynamic;
      procedure ChangeClose;dynamic;

      property ComboCaption: TAmComboCaptionCustom read FComboCaption write ComboCaptionSet;
      property ComboDrop: TAmComboDropCustom read FComboDrop write ComboDropSet;

      function ItemValueSelectedList(ValueSelected:string):boolean;virtual;
    public
      Constructor Create(AOwner:TComponent);override;
      destructor Destroy;override;
      property ItemIndex: integer read ItemIndexGet write ItemIndexSet;
      property ItemCaption: TCaption read ItemCaptionGet write ItemCaptionSet;
      procedure ItemValueSelected(ValueSelected:string;NeedDropDown:boolean); virtual;
      procedure DropDown(NeedShowList:boolean=true);dynamic;
      procedure DropClose; dynamic;
      property DropedState: boolean read FDropedState write DropedStateSet;
    published
      property DropCanMove :boolean read DropCanMoveGet write DropCanMoveSet;
      property DropCanResize :boolean read DropCanResizeGet write DropCanResizeSet;
      property DropAnimate:TAmWinAnimateEnum read DropAnimateGet write DropAnimateSet;
      property DropAnimateTime:integer read DropAnimateTimeGet write DropAnimateTimeSet;
      property DropPaddingSize:integer read DropPaddingSizeGet write DropPaddingSizeSet;
      property DropColor:TColor read DropColorGet write DropColorSet;
      property DropAutoClose: boolean read FDropAutoClose write FDropAutoClose default true;
      //DropResetSession =true если не был выбран элемент но лист закрывается то выбраный раньше индекс сбросится
      property DropResetSession: boolean read FDropResetSession write DropResetSessionSet default False;


      property OnChangeIndex: TAmComboChange read FChangeIndex write FChangeIndex;
      property OnChange: TNotifyEvent read FChange write FChange;
      property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
      property OnDropClose: TNotifyEvent read FOnDropClose write FOnDropClose;
      property OnSetCaption: TAmComboSetCaption read FOnSetCaption write FOnSetCaption;
      property Height default 26;
      //property DropDowned: boolean read FDropDowned write DropDownedSet stored false default false;
   end;

   TAmComboButListBoxAbstract = class abstract(TAmComboAbstract)
     private
      procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
      procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;

      function ButtonGet: TAmButton;
      function ItemsGet: TStrings;
      function DropListBoxGet: TCustomListBox;
      procedure DropListBoxSet(value: TCustomListBox);
      function ComboCaptionGet: TAmComboCaptionButton;
      function ComboDropGet: TAmComboDropLBLink;
      function DropHeightGet: integer;
      procedure DropHeightSet(const Value: integer);
     protected
      property ComboCaption: TAmComboCaptionButton read ComboCaptionGet;
      property ComboDrop: TAmComboDropLBLink read ComboDropGet;
      procedure ChangeIndex(Index:integer);override;
      procedure ChangeClose;override;
      function ItemValueSelectedList(ValueSelected:string):boolean;override;
     public
      Constructor Create(AOwner:TComponent);override;
      destructor Destroy;override;
     published
      property Button: TAmButton read ButtonGet;
      property Items: TStrings read ItemsGet;
      property DropListBox: TCustomListBox read DropListBoxGet write DropListBoxSet;
      property DropHeight:integer read DropHeightGet write DropHeightSet default 120;

   end;

   // нужно установить ссылку на ListBox
   TAmComboListBox  = class (TAmComboButListBoxAbstract)
   end;


   // лист бокс идет в комплекте combobox
   TAmComboBox = class (TAmComboListBox)
     private
      function DropListBoxGet: TAmListBox;
     protected
       procedure SetName(const NewName: TComponentName);override;
     public
      Constructor Create(AOwner:TComponent);override;
      destructor Destroy;override;
     published
      property DropListBox: TAmListBox read DropListBoxGet;
   end;

     procedure Register;

implementation
procedure Register;
begin
  RegisterComponents('Am', [TAmComboBox,TAmComboListBox]);
end;
type
 TLocComponent= class(TComponent);
 TLocCustomListBox= class(TCustomListBox);

{ TAmComboCaptionCustom }

constructor TAmComboCaptionCustom.Create(AOwner: TAmComboAbstract);
begin
 inherited Create(AOwner);
 FCombo:=AOwner;
 FCombo.ComboCaption:=self;
end;

destructor TAmComboCaptionCustom.Destroy;
begin
  FCombo:=nil;
  inherited;
end;

{ TAmComboDropCustom }

constructor TAmComboDropCustom.Create(AOwner: TAmComboAbstract);
begin
 inherited Create(AOwner);
 FCombo:=AOwner;
 FLay:=TAmLayout.Create(self);
 FLay.Height:=120;
 FLay.Left:=-500;
 FLay.Top:=500;
 FLay.Visible:=false;
 FLay.BevelOuter:=bvNone;
 FPopup:=TAmPopupControl.Create(self);
 FPopup.OnPopapClose := PopapClose;
 FPopup.PopupPaddingSize:=4;
 FPopup.PopupControl:= FLay;
 include(TLocComponent(FLay).FComponentStyle, csSubComponent);
 include(TLocComponent(FPopup).FComponentStyle, csSubComponent);
 FCombo.ComboDrop:=self;
end;

destructor TAmComboDropCustom.Destroy;
begin
  FPopup.OnPopapClose :=nil;
  FCombo:=nil;
  FLay:=nil;
  FPopup:=nil;
  inherited;
end;


procedure TAmComboDropCustom.Open;
begin
   if Assigned(FPopup)  then
   begin
      if not FPopup.IsShow and FCombo.HandleAllocated then
      OpenUp;
   end;

end;
procedure TAmComboDropCustom.OpenUp;
var P:TPoint;
begin
    ChangeSizeCombo;
    P:=FCombo.ClientToScreen(Point(0,0));
    inc(P.Y,FCombo.ClientHeight);
    FPopup.PopupOpen(P.X,P.Y);
end;

procedure TAmComboDropCustom.Close;
begin
  if Assigned(FPopup)  then
    if  FPopup.IsShow then
      FPopup.PopupClose;
end;

procedure TAmComboDropCustom.PopapClose(Sender: TObject);
begin
   CloseUp;
end;

procedure TAmComboDropCustom.ChangeIndex;
begin
   FCombo.ChangeIndex(ItemIndex);
end;

procedure TAmComboDropCustom.ChangeNameCombo;
begin
    FLay.Name:='Lay';
    FPopup.Name:='Popup';
end;

procedure TAmComboDropCustom.ChangeParentCombo;
begin
   if Combo.Parent<>nil then
   FLay.Parent:=  Combo;
end;

procedure TAmComboDropCustom.ChangeSizeCombo;
begin
     Lay.Width:=  Combo.Width - (FPopup.PopupPaddingSize*2);
end;



procedure TAmComboDropCustom.CloseUp;
begin
   FCombo.ChangeClose;
end;



{ TAmComboButton }

function TAmComboButton.ClientRectContent: TRect;
begin
  Result:= inherited ClientRectContent;
  Result.Right:= Result.Right - AmScaleV(30);
end;

procedure TAmComboButton.Paint;
var R,rd:TRect;
  function LocSizeDown:integer;
  var S:integer;
  begin
    S:= Font.Size;
    if      S< 8 then  Result:= AmScaleV(1)
    else if S< 12 then  Result:= AmScaleV(2)
    else if S< 16 then  Result:= AmScaleV(3)
    else if S< 20 then  Result:= AmScaleV(4)
    else Result:= AmScaleV(5);
  end;
begin
  inherited Paint;
  Canvas.Font:=self.Font;
  if  not EnabledTop then
   Canvas.Font.Color:=   AmGraphicCanvasHelp.ColorBlend(Canvas.Font.Color,clgray,50);

  R:=inherited ClientRectContent;
  rd:=Rect(R.Right - AmScaleV(30), R.Top, R.Right, R.Bottom );
  Canvas.Pen.Width:=1;
  AmGraphicCanvasHelp.CanvasPaintTriangleDown(Canvas,Canvas.Font.Color,rd.CenterPoint,LocSizeDown);

end;

{ TAmComboCaptionButton }
constructor TAmComboCaptionButton.Create(AOwner: TAmComboAbstract);
begin
  FBut:=nil;
  inherited;
  FBut:=TAmComboButton.Create(self);
  FBut.OnClick:= ButClick;
  FBut.Align:=alClient;
  include(TLocComponent(FBut).FComponentStyle, csSubComponent);
end;

destructor TAmComboCaptionButton.Destroy;
begin
  FBut:=nil;
  inherited;
end;

procedure TAmComboCaptionButton.ButClick(Sender: TObject);
begin
   if GetTickCount - FCombo.FCloseLastTime > 200  then    
   FCombo.DropDown;
end;

function TAmComboCaptionButton.CaptionGet: TCaption;
begin
   Result:= FBut.Caption;
end;

procedure TAmComboCaptionButton.CaptionSet(const Value: TCaption);
begin
   FBut.Caption:=  Value;
end;

procedure TAmComboCaptionButton.ChangeDropIndex(Drop: TAmComboDropCustom; Index: integer);
begin
   if Index >=0 then
   FBut.Caption:=   Drop.Items[Index]
   else
   FBut.Caption:='';
end;

procedure TAmComboCaptionButton.ChangeNameCombo;
begin
   FBut.Name:='But';
   FBut.Caption:='';
end;

procedure TAmComboCaptionButton.ChangeParentCombo;
begin
  if FCombo.Parent<>nil then
  FBut.Parent:= FCombo;
end;

procedure TAmComboCaptionButton.ChangeSizeCombo;
begin
end;

{ TAmComboDropLBLink }

procedure TAmComboDropLBLink.ChangeParentCombo;
begin
  inherited ChangeParentCombo;
   if (Combo.Parent<>nil) and (FListBox<>nil) then
   FListBox.Parent:=  Lay;
end;

constructor TAmComboDropLBLink.Create(AOwner: TAmComboAbstract);
begin
  FListBox:=nil;
  FItemIndexSave:=-1;
   AmRecordHlpBase.RecFinal(FSave);
  inherited;
  FListBox:=nil;
end;

destructor TAmComboDropLBLink.Destroy;
begin
  FListBox:=nil;
  inherited;
end;

function TAmComboDropLBLink.ItemIndexGet: integer;
begin
  if self.Popup.IsShow then
  begin
    if Assigned(FListBox) then Result:= FListBox.ItemIndex
    else Result:=FItemIndexSave;
  end
  else Result:=  FItemIndexSave;
  if Result<-1 then
  Result:=-1;
end;

procedure TAmComboDropLBLink.ItemIndexSet(const Value: integer);
begin
  if self.Popup.IsShow then
  begin
      if Assigned(FListBox) then
      FListBox.ItemIndex:=Value
      else FItemIndexSave:=Value;
  end
  else
     FItemIndexSave:=  Value;
  LbChange(nil,TMouseButton.mbLeft,[],0,0);
end;

function TAmComboDropLBLink.ItemsGet(Index: integer): string;
begin
 if Assigned(FListBox) then
  Result:= FListBox.Items[Index]
  else Result:='';
end;

procedure TAmComboDropLBLink.ItemsSet(Index: integer; const Value: string);
begin
 if Assigned(FListBox) then
   FListBox.Items[Index] := Value;
end;



procedure TAmComboDropLBLink.LbChange(Sender:TObject;Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
begin
  if (Sender<>nil) and Assigned(FSave.Md) then
  FSave.Md(Sender,Button,Shift,X, Y);
  FItemIndexSave:=self.ItemIndex;
  ChangeIndex();
end;

procedure TAmComboDropLBLink.ListBoxSet(const Value: TCustomListBox);
begin
  if FListBox = Value  then exit;
  if FListBox<>nil then
  begin
    FListBox.Align:=  FSave.Al;
    FListBox.Visible:= FSave.Visible;
    FListBox.Parent:=FSave.Parent;
    TLocCustomListBox(FListBox).OnMouseDown:= FSave.Md;
    if FSave.Parent<>nil then
    FSave.Parent.RemoveFreeNotification(self);
    FListBox.RemoveFreeNotification(self);
  end;

  FListBox := Value;

  if FListBox<>nil then
  begin
    FListBox.FreeNotification(self);
    FSave.Al:=      FListBox.Align;
    FSave.Visible:= FListBox.Visible;
    FSave.Parent:=  FListBox.Parent;
    FSave.Md:=    nil;//  TLocCustomListBox(FListBox).OnMouseDown;
    if FSave.Parent<>nil then
    FSave.Parent.FreeNotification(self);
  end;
end;

procedure TAmComboDropLBLink.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (FListBox = AComponent) then
  begin
    FListBox:=nil;
    AmRecordHlpBase.RecFinal(FSave);
  end;
  if (Operation = opRemove) and (FSave.Parent = AComponent) then
  begin
    FSave.Parent:=nil;
    FSave.Md:=nil;
  end;
end;


function TAmComboDropLBLink.ObjectsGet(Index: integer): TObject;
begin
 if Assigned(FListBox) then
  Result:= FListBox.Items.Objects[Index]
  else Result:=nil;
end;

procedure TAmComboDropLBLink.ObjectsSet(Index: integer; const Value: TObject);
begin
 if Assigned(FListBox) then
   FListBox.Items.Objects[Index] := Value;
end;



procedure TAmComboDropLBLink.OpenUp;
begin
 if (Combo.Parent<>nil) and (FListBox<>nil)  then
 begin
  FListBox.Parent:= self.Lay;
  FListBox.Align:=alclient;
  FListBox.Visible:=true;
  if  FItemIndexSave<FListBox.Items.Count then
   FListBox.ItemIndex:= FItemIndexSave
   else
   begin
      FItemIndexSave:=-1;
      FListBox.ItemIndex:=-1;
   end;
  TLocCustomListBox(FListBox).OnMouseDown:=  LbChange;
 end;
  inherited;
end;
procedure TAmComboDropLBLink.CloseUp;
begin
  inherited CloseUp;
  if  (FListBox<>nil)  then
  TLocCustomListBox(FListBox).OnMouseDown:=nil;
end;

{ TAmComboAbstract }

constructor TAmComboAbstract.Create(AOwner: TComponent);
begin
  inherited;
  FComboCaption:=nil;
  FComboDrop:=nil;
  FDropAutoClose:=true;
  Height:=26;
  FDropedState:=false;
  FDropResetSession:=false;
  FDropStateSessionChanged:=false;
  FCloseLock:=0;
  FCloseLastTime:=0;
end;

destructor TAmComboAbstract.Destroy;
begin
  FComboCaption:=nil;
  FComboDrop:=nil;
  inherited;
end;



procedure TAmComboAbstract.ComboCaptionSet(const Value: TAmComboCaptionCustom);
begin
  if FComboCaption = Value  then   exit;
  if FComboCaption<>nil then
   FComboCaption.Free;
  FComboCaption:=nil;
  if (Value<>nil) and (Value.Combo <> self) then
  raise Exception.Create('Error TAmComboAbstract.ComboCaptionSet Value.Combo <> self');
  FComboCaption:=Value;
end;

procedure TAmComboAbstract.ComboDropSet(const Value: TAmComboDropCustom);
begin
  if FComboDrop = Value  then   exit;
  if FComboDrop<>nil then
   FComboDrop.Free;
  FComboDrop:=nil;
  if (Value<>nil) and (Value.Combo <> self) then
  raise Exception.Create('Error TAmComboAbstract.ComboDropSet Value.Combo <> self');
  FComboDrop:=Value;
end;

function TAmComboAbstract.DropAnimateGet: TAmWinAnimateEnum;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.PopupAnimate
   else Result:=waNone;
end;

procedure TAmComboAbstract.DropAnimateSet(const Value: TAmWinAnimateEnum);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.PopupAnimate := Value;
end;

function TAmComboAbstract.DropAnimateTimeGet: integer;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.PopupAnimateTime
   else Result:=0;
end;

procedure TAmComboAbstract.DropAnimateTimeSet(const Value: integer);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.PopupAnimateTime := Value;
end;

function TAmComboAbstract.DropCanMoveGet: boolean;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.CanMove
   else Result:=false;
end;

procedure TAmComboAbstract.DropCanMoveSet(const Value: boolean);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.CanMove := Value;
end;

function TAmComboAbstract.DropCanResizeGet: boolean;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.CanResize
   else Result:=false;
end;

procedure TAmComboAbstract.DropCanResizeSet(const Value: boolean);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.CanResize := Value;
end;



procedure TAmComboAbstract.DropDown(NeedShowList:boolean=true);
begin

  if Assigned(FComboDrop) then
  begin
    if FDropResetSession then
      self.ItemIndex:=-1;
    if Assigned(FOnDropDown) then
    FOnDropDown(self);
    if NeedShowList then
    begin
      FComboDrop.Open;
      FDropedState:=true;
      FDropStateSessionChanged:=false;
    end;
  end;
end;

procedure TAmComboAbstract.DropClose;
begin
  if Assigned(FComboDrop) then
  FComboDrop.Close;
end;

procedure TAmComboAbstract.ChangeIndex(Index: integer);
var   CanContinue:boolean;
begin
   FDropStateSessionChanged:=true;
   if Assigned(FComboCaption) and (FComboDrop<>nil)  then
   begin
     CanContinue:=true;
     if Assigned(FOnSetCaption) then
     FOnSetCaption(self,Index,CanContinue);
     if CanContinue then
     FComboCaption.ChangeDropIndex(FComboDrop,Index);
   end;
   if Assigned(FChangeIndex) then
   FChangeIndex(self,Index);
   if Assigned(FChange) then
   FChange(self);
   if  ( FCloseLock = 0 ) and FDropAutoClose then
   DropClose;
end;

procedure TAmComboAbstract.ChangeClose;
begin
  if FCloseLock >0 then
  exit;
  inc(FCloseLock);
  try
     if not FDropStateSessionChanged
     and FDropResetSession then
     begin
        self.ItemIndex:=-1;
        ChangeIndex(-1);
     end;
     if Assigned(FOnDropClose) then
      FOnDropClose(self);
     FDropedState:=false;
     FDropStateSessionChanged:=false;
     FCloseLastTime := GetTickCount; 
  finally
    dec(FCloseLock);
  end;
end;

function TAmComboAbstract.DropColorGet: TColor;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.PopupColor
   else Result:=0;
end;

procedure TAmComboAbstract.DropColorSet(const Value: TColor);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.PopupColor := Value;
   if (FComboDrop<>nil) and (FComboDrop.Lay<>nil) then
   FComboDrop.Lay.Color:=  Color;
end;


procedure TAmComboAbstract.DropedStateSet(const Value: boolean);
begin
  if FDropedState = Value  then exit;
  if Value then DropDown
  else        DropClose;
end;

function TAmComboAbstract.DropPaddingSizeGet: integer;
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    Result:= FComboDrop.Popup.PopupPaddingSize
   else Result:=0;
end;

procedure TAmComboAbstract.DropPaddingSizeSet(const Value: integer);
begin
   if (FComboDrop<>nil) and (FComboDrop.Popup<>nil) then
    FComboDrop.Popup.PopupPaddingSize := Value;
end;

procedure TAmComboAbstract.DropResetSessionSet(const Value: boolean);
begin
  FDropResetSession := Value;
end;

function TAmComboAbstract.ItemCaptionGet: TCaption;
begin
  if Assigned(FComboCaption) then
  Result:= FComboCaption.Caption
  else Result:='';
end;

procedure TAmComboAbstract.ItemCaptionSet(const Value: TCaption);
begin
  if Assigned(FComboCaption) then
   FComboCaption.Caption := Value;
end;

function TAmComboAbstract.ItemIndexGet: integer;
begin
  if Assigned(FComboDrop) then
  Result:= FComboDrop.ItemIndex
  else Result:=-1;
end;

procedure TAmComboAbstract.ItemIndexSet( Value: integer);
begin
  if Assigned(FComboDrop) then
  FComboDrop.ItemIndex:=Value;
end;

function TAmComboAbstract.ItemValueSelectedList(ValueSelected:string):boolean;
begin
  result:=false;
end;

procedure TAmComboAbstract.ItemValueSelected(ValueSelected:string;NeedDropDown:boolean);
begin
   if NeedDropDown then    
   DropDown(false);
   if ItemValueSelectedList(ValueSelected) then
     ItemCaption:=  ValueSelected
   else ItemCaption:='';
end;

procedure TAmComboAbstract.Resize;
begin
  inherited;
 if FComboDrop<>nil then
  FComboDrop.ChangeSizeCombo;
 if FComboCaption<>nil then
  FComboCaption.ChangeSizeCombo;
end;

procedure TAmComboAbstract.SetParent(W: TWinControl);
begin
  inherited;
 if FComboDrop<>nil then
  FComboDrop.ChangeParentCombo;
 if FComboCaption<>nil then
  FComboCaption.ChangeParentCombo;
end;

procedure TAmComboAbstract.SetName(const NewName: TComponentName);
begin
  inherited;
 if FComboDrop<>nil then
  FComboDrop.ChangeNameCombo;
 if FComboCaption<>nil then
  FComboCaption.ChangeNameCombo;
end;





{ TAmComboBox }

constructor TAmComboButListBoxAbstract.Create(AOwner: TComponent);
begin
  inherited;
  TAmComboCaptionButton.Create(self);
  TAmComboDropLBLink.Create(self);
  include(TLocComponent(ComboCaption).FComponentStyle, csSubComponent);
  include(TLocComponent(ComboDrop).FComponentStyle, csSubComponent);
  DropHeight:=120;
end;

destructor TAmComboButListBoxAbstract.Destroy;
begin
  inherited;
end;

procedure TAmComboButListBoxAbstract.ChangeIndex(Index: integer);
begin
  inherited ChangeIndex(Index);
end;

procedure TAmComboButListBoxAbstract.ChangeClose;
begin
  inherited;
  Button.SetFocus;
end;

procedure TAmComboButListBoxAbstract.CMColorChanged(var Message: TMessage);
begin
 inherited;
   if Button<>nil then
   Button.Color:=Color;
   if (ComboDrop<>nil) and (ComboDrop.Lay<>nil) then
   ComboDrop.Lay.Color:=  Color;
   if (ComboDrop<>nil) and (ComboDrop.Popup<>nil) then
   ComboDrop.Popup.PopupColor:=  Color;
end;

procedure TAmComboButListBoxAbstract.CMFontChanged(var Message: TMessage);
begin
   inherited;
   if Button<>nil then
   Button.Font.Assign(Font);
end;

function TAmComboButListBoxAbstract.ComboCaptionGet: TAmComboCaptionButton;
begin
  Result:=inherited  ComboCaption  as  TAmComboCaptionButton;
end;

function TAmComboButListBoxAbstract.ComboDropGet: TAmComboDropLBLink;
begin
 Result:=inherited  ComboDrop  as  TAmComboDropLBLink;
end;

function TAmComboButListBoxAbstract.ButtonGet: TAmButton;
begin
   if ComboCaption<>nil then Result:=ComboCaption.But
   else Result:=nil;
end;

function TAmComboButListBoxAbstract.ItemValueSelectedList(ValueSelected: string): boolean;
var i:integer;
begin
  try
     if DropListBox = nil then
     begin
       DropListBox.ItemIndex:=-1;
       exit();
     end;

     if (DropListBox is TamListBoxNoScroll) then
       TamListBoxNoScroll(DropListBox).ItemNewIndexCaption:=  ValueSelected
     else
     begin
       for I := 0 to DropListBox.Count-1 do
       if DropListBox.Items[i] = ValueSelected then
       begin
         DropListBox.ItemIndex:=i;
         exit;
       end;
       DropListBox.ItemIndex:=-1;
     end;
  finally
     Result:= DropListBox.ItemIndex >= 0;
  end;
end;

function TAmComboButListBoxAbstract.ItemsGet: TStrings;
begin
   if (ComboDrop<>nil) and (ComboDrop.ListBox <> nil)  then
      Result:=ComboDrop.ListBox.Items
   else Result:=nil;
end;

function TAmComboButListBoxAbstract.DropHeightGet: integer;
begin
   if (ComboDrop<>nil)  then Result:= ComboDrop.Lay.Height
   else Result:=0;
end;

procedure TAmComboButListBoxAbstract.DropHeightSet(const Value: integer);
begin
  if (ComboDrop<>nil)  then ComboDrop.Lay.Height:= Value;
end;

function TAmComboButListBoxAbstract.DropListBoxGet: TCustomListBox;
begin
    if (ComboDrop<>nil) then Result:= ComboDrop.ListBox
    else Result:=nil;
end;

procedure TAmComboButListBoxAbstract.DropListBoxSet(value: TCustomListBox);
begin
    if (ComboDrop<>nil)  then
    ComboDrop.ListBox:=  value;
end;

{ TAmComboBox }


constructor TAmComboBox.Create(AOwner: TComponent);
var L: TAmListBox;
begin
  inherited;
  L:=TAmListBox.Create(self);
  L.SetSubComponent(true);
  inherited  DropListBox:= L;
end;

destructor TAmComboBox.Destroy;
begin
  inherited;
end;


function TAmComboBox.DropListBoxGet: TAmListBox;
begin
  Result:= inherited DropListBox as TAmListBox;
end;
procedure TAmComboBox.SetName(const NewName: TComponentName);
begin
  inherited;
  DropListBox.Name:='DropListBox';
end;

end.
