unit AmGridEditorToolForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,DesignIntf, DesignWindows, ToolWnds, DesignEditors,
  Vcl.StdCtrls, Vcl.ExtCtrls,AmInterfaceBase,AmControlClasses,AmSystemListBase,AmSystemBase,AmSystemItems,
  System.Generics.Collections, Vcl.Samples.Spin;

type
  TGridSave = class

  end;

  TGridEditForm = class(TDesignWindow)
    Panel2: TPanel;
    Label2: TLabel;
    Cols: TListBox;
    ButitemAdd: TButton;
    ButitemDelete: TButton;
    ButItemDown: TButton;
    ButItemUp: TButton;
    Panel3: TPanel;
    Rows: TListBox;
    Label3: TLabel;
    ButLnAdd: TButton;
    ButLnDelete: TButton;
    ButLnDown: TButton;
    ButLnUp: TButton;
    lnW: TSpinEdit;
    lnH: TSpinEdit;
    Label4: TLabel;
    MemoText: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure RowsClick(Sender: TObject);
    procedure ColsClick(Sender: TObject);
    procedure ButLnAddClick(Sender: TObject);
    procedure ButLnDeleteClick(Sender: TObject);
    procedure ButLnDownClick(Sender: TObject);
    procedure ButLnUpClick(Sender: TObject);
    procedure ButitemAddClick(Sender: TObject);
    procedure ButitemDeleteClick(Sender: TObject);
    procedure ButItemDownClick(Sender: TObject);
    procedure ButItemUpClick(Sender: TObject);
    procedure lnWChange(Sender: TObject);
    procedure MemoTextChange(Sender: TObject);
  private
    { Private declarations }
     FPropertyName:string;
     FStateLock:integer;
     FClosing:boolean;
     FLine:IAmGridLine;
     FItem:IAmGridItem;
     procedure UpdatePanelPostBack(var Msg); message wm_user+1214;
     procedure CloseEditor;
     procedure UpdatePanel;
     procedure UpdatePanelPost;
     procedure LinesLoad;
     procedure LineLoad;
     procedure LineClear;
     procedure LinesClear;
     procedure ItemLoad;
     procedure ItemClear;
     procedure ClearPrm;
     procedure PropertyNameSet(const Value: string);
     procedure SelectPropertyComponent;
     procedure SetSelectObject(AItem: TPersistent);
  protected
    procedure Activated; override;
  public
    { Public declarations }
    Component: TComponent;
    Grid:IAmGrid;


    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent); override;
    procedure ItemInserted(const ADesigner: IDesigner; AItem: TPersistent); override;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean); override;
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean); override;
    procedure ItemsModified(const ADesigner: IDesigner); override;

   class function ShowEditGrid   (ADesigner: IDesigner;
                                  AGrid:IAmGrid;
                                  AComponent:TComponent;
                                  APropertyName: string):TGridEditForm;
   property PropertyName: string read FPropertyName write PropertyNameSet;
  end;


  TAmGridProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

var
  GridEditForm: TGridEditForm;

implementation
 uses System.Win.Registry, System.TypInfo, DesignConst, ComponentDesigner;
{$R *.dfm}
  type
     TSaveRect  = record
       v:boolean;
       l,t,w,h:integer;
     end;
  var SaveRect:TSaveRect;
procedure Log(msg:string);
begin
  AmSystemBase.AmDesing.Log(msg);
end;


{ TTGridEditForm }

class function TGridEditForm.ShowEditGrid(ADesigner: IDesigner; AGrid: IAmGrid;
  AComponent: TComponent; APropertyName: string): TGridEditForm;
begin
  Result := TGridEditForm.Create(Application);

  with Result do
  try
    Designer := ADesigner;
    Component := AComponent;
    Grid := AGrid;
    PropertyName := APropertyName;
    UpdatePanel;
    if SaveRect.v then
     SetBounds(SaveRect.l,SaveRect.t,SaveRect.w,SaveRect.h);
    Show;
     AmDesing.Log('show new');
    // Log(PropertyName);
  except
    Free;
  end;
end;
procedure TGridEditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   ClearPrm;
   SaveRect.v:=true;

   SaveRect.l:=left;
   SaveRect.t:=Top;
   SaveRect.w:=Width;
   SaveRect.h:=Height;
   SaveRect.v:=true;
   Action:=TCloseAction.caFree;
end;


procedure TGridEditForm.FormCreate(Sender: TObject);
begin
  FStateLock:=0;
  FClosing:=false;
  Component:=nil;
  Grid:=nil;
  FLine:=nil;
  FItem:=nil;
  FPropertyName:='';
end;

procedure TGridEditForm.Activated;
begin
  Designer.Activate;
  UpdatePanel;
end;



procedure TGridEditForm.ClearPrm;

begin
  SelectPropertyComponent;
  Component:=nil;
  Grid:=nil;
  FPropertyName:='';
  FLine:=nil;
  FItem:=nil;
end;

procedure TGridEditForm.CloseEditor;
begin
  if FClosing then exit;
  FClosing := True;
  ClearPrm;
  Close;
end;


procedure TGridEditForm.SelectPropertyComponent;
var
  List: IDesignerSelections;
begin
  if (Component<>nil) and not (csDestroying in Component.ComponentState) then
  begin
   List := CreateSelectionList;
   List.Add(Component);
   Designer.SetSelections(List);
   Designer.SelectItemName(PropertyName);
   List:=nil;
  end;
end;

procedure TGridEditForm.DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
begin
  if Designer = ADesigner then
    CloseEditor;
end;

procedure TGridEditForm.DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
begin
  inherited;
end;

procedure TGridEditForm.ItemDeleted(const ADesigner: IDesigner;
  AItem: TPersistent);
begin
  if (AItem = nil) or FClosing then Exit;
  if (Component = nil)
  or (Grid = nil)
  or (Grid.AsPersDesingNotify = nil)
  or (csDestroying in Component.ComponentState)  then
  begin
   CloseEditor;
   exit;
  end;
  if (Component = AItem) or ( AItem = Grid.AsPersDesingNotify )  then
  begin
     CloseEditor;
     exit;
  end;
  if Grid.IsMyChildObject(AItem) then
   UpdatePanelPost;
end;

procedure TGridEditForm.ItemInserted(const ADesigner: IDesigner;
  AItem: TPersistent);
begin
  if (AItem = nil) or FClosing then Exit;
  if (Component = nil)
  or (Grid = nil)
  or (Grid.AsPersDesingNotify = nil)
  or (csDestroying in Component.ComponentState)  then
  begin
   CloseEditor;
   exit;
  end;
  if (Component = AItem) or ( AItem = Grid.AsPersDesingNotify )  then
  begin
     CloseEditor;
     exit;
  end;
  if (FLine<>nil) and (FLine.AsPersDesingNotify =  AItem)  then
  begin
     FLine:=nil;
     UpdatePanelPost;
  end
  else if (FItem<>nil) and (FItem.AsPersDesingNotify =  AItem)  then
  begin
     FItem:=nil;
     UpdatePanelPost;
  end
  else if Grid.IsMyChildObject(AItem) then
   UpdatePanelPost;
end;

procedure TGridEditForm.ItemsModified(const ADesigner: IDesigner);
var Root:IRoot;
begin
  if FClosing then exit;
  if (Component = nil)
  or (Grid = nil)
  or (Grid.AsPersDesingNotify = nil)
  or (csDestroying in Component.ComponentState)  then
  begin
   CloseEditor;
   exit;
  end;
  Root := ActiveRoot;
  if (Root = nil) or (Root.GetDesigner <> Designer) then
    begin
      Exit;
    end;
  UpdatePanelPost;
end;

procedure TGridEditForm.PropertyNameSet(const Value: string);
begin
  if Value <> FPropertyName then
  begin
    FPropertyName := Value;
    Caption := 'Edit '+Component.Name +'.'+ Value;
  end;
end;



procedure TGridEditForm.SelectionChanged(const ADesigner: IDesigner;
  const ASelection: IDesignerSelections);
begin
  inherited;

end;

procedure  TGridEditForm.SetSelectObject(AItem: TPersistent);
var
  List: IDesignerSelections;
begin
   if AItem=nil then exit;
   List := CreateSelectionList;
   List.Add(AItem);
   Designer.SetSelections(List);
   List:=nil;
end;

procedure TGridEditForm.ButitemAddClick(Sender: TObject);
begin
     if FLine = nil  then exit;
     FLine.Add;
end;

procedure TGridEditForm.ButitemDeleteClick(Sender: TObject);
begin
  if FItem<>nil then
  FItem.Release;
end;

procedure TGridEditForm.ButItemDownClick(Sender: TObject);
begin
  if FItem = nil then exit;
  if FItem.IndexItem < FItem.ParentLine.Count-1 then
  FItem.IndexItem:= FItem.IndexItem+1;
end;

procedure TGridEditForm.ButItemUpClick(Sender: TObject);
begin
  if FItem = nil then exit;
  if (FItem.IndexItem >0)  then
  FItem.IndexItem:= FItem.IndexItem-1;
end;

procedure TGridEditForm.ButLnAddClick(Sender: TObject);
begin
    Grid.LineAdd;
end;


procedure TGridEditForm.ButLnDeleteClick(Sender: TObject);
begin
  if FLine<>nil then
  FLine.Release;
end;

procedure TGridEditForm.ButLnDownClick(Sender: TObject);
begin
  if FLine = nil then exit;
  if FLine.IndexLine < FLine.ParentGrid.CountLine-1 then
  FLine.IndexLine:= FLine.IndexLine+1;
end;

procedure TGridEditForm.ButLnUpClick(Sender: TObject);
begin
  if FLine = nil then exit;
  if (FLine.IndexLine >0)  then
  FLine.IndexLine:= FLine.IndexLine-1;
end;

procedure TGridEditForm.UpdatePanel;
begin
    if  FClosing then Exit;
    if (Component = nil)
    or (Grid = nil)
    or (Grid.AsPersDesingNotify = nil)
    or (csDestroying in Component.ComponentState)  then
    begin
     CloseEditor;
     exit;
    end;

    LinesLoad;
    LineLoad;
    ItemLoad;
end;
procedure TGridEditForm.LinesLoad;
var ItemLine:IAmGridLine;
    i:integer;
    s:string;
begin
   Rows.Clear;
   Cols.Clear;
   if Grid.CountLine<=0 then exit;
   Rows.Items.BeginUpdate;
   try
      for I := 0 to Grid.CountLine-1 do
      begin
          ItemLine:=  Grid.Line[I];
         s:='['+I.ToString+'][id:'+ ItemLine.Id.ToString+'] '+   TObject(ItemLine).ClassName;
         Rows.Items.AddObject(s,TObject(Pointer(ItemLine)));
      end;
   finally
     Rows.Items.EndUpdate;
   end;
end;
procedure TGridEditForm.lnWChange(Sender: TObject);
begin
   if FLine = nil then exit;
   if Sender = lnW  then
   FLine.Width:= lnW.Value
   else if Sender = lnH  then
   FLine.Height:= lnH.Value

end;

procedure TGridEditForm.MemoTextChange(Sender: TObject);
begin
   if FItem = nil then exit;
   FItem.Text:= MemoText.Text;
end;

procedure TGridEditForm.LinesClear;
begin
   FItem:=nil;
   ItemClear;
   Cols.Clear;
   Rows.ItemIndex:=-1;
end;
procedure TGridEditForm.LineLoad;
var Item:IAmGridItem;
    i:integer;
    s:string;
begin
    Cols.Clear;
    if (FLine=nil) or (FLine.ParentGrid <> Grid) then
    begin
     FLine:=nil;
     log('LineLoad exit 2');
     LinesClear;
     exit;
    end;
   Rows.ItemIndex:= FLine.IndexLine;
   lnW.Value:= FLine.Width;
   lnH.Value:= FLine.Height;
   //log('LineLoad 3');
   if FLine.Count<=0 then exit;
   Cols.Items.BeginUpdate;
   try
      for I := 0 to FLine.Count-1 do
      begin
          Item:=  FLine.Items[I];
         s:='['+I.ToString+'][id:'+ Item.Id.ToString+'] '+   TObject(Item).ClassName;
         Cols.Items.AddObject(s,TObject(Pointer(Item)));
      end;
   finally
     Cols.Items.EndUpdate;
   end;
   log('LineLoad 4');
end;

procedure TGridEditForm.LineClear;
begin
   FItem:=nil;
   Cols.ItemIndex:=-1;
   lnW.Value:=0;
   lnH.Value:=0;
end;
procedure TGridEditForm.ItemLoad;
begin
    if (FLine=nil) or (FLine.ParentGrid <> Grid) then
    begin
     FLine:=nil;
     LinesClear;
     exit;
    end;

    if (FItem=nil) or (FItem.ParentLine <> FLine) then
    begin
     ItemClear;
     exit;
    end;
    Cols.ItemIndex:= FItem.IndexItem;
    MemoText.Text:= FItem.Text;
end;
procedure TGridEditForm.ItemClear;
begin
   FItem:=nil;
   MemoText.Text:= '';
   Cols.ItemIndex:=-1;
end;

procedure TGridEditForm.RowsClick(Sender: TObject);
begin
    FLine:=nil;
    LineClear;
    ItemClear;
    Cols.Clear;
    if Rows.ItemIndex<0 then   exit;
    FLine:=IAmGridLine(Pointer(Rows.Items.Objects[Rows.ItemIndex]));
    LineLoad;
   SetSelectObject(FLine.AsPersDesingNotify);
end;

procedure TGridEditForm.ColsClick(Sender: TObject);
begin
   FItem:=nil;
   MemoText.Text:= '';
   if Cols.ItemIndex<0 then   exit;
    FItem:=IAmGridItem(Pointer(Cols.Items.Objects[Cols.ItemIndex]));
    ItemLoad;
    SetSelectObject(FItem.AsPersDesingNotify);
end;

procedure TGridEditForm.UpdatePanelPost;
begin
   Rows.Clear;
   Cols.Clear;
  postmessage(self.Handle,wm_user+1214,0,0);
end;

procedure TGridEditForm.UpdatePanelPostBack(var Msg);
begin
  if FStateLock = 0 then
  UpdatePanel
  else
    PostMessage(Handle, wm_user+1214, TMessage(Msg).WParam, TMessage(Msg).LParam);
end;

{ TAmGridProperty }

procedure TAmGridProperty.Edit;
var
  Obj: TPersistent;
  Grid:IAmGrid;
begin
  Obj := GetComponent(0);
  Grid:=IAmGrid(GetIntfValueAt(0));

  if (Obj=nil) or not (Obj is TComponent) and (Grid<>nil) then
  begin
      Obj:=  Grid.ParentControl;
  end;
  TGridEditForm.ShowEditGrid(Designer,Grid,Obj as TComponent,GetName);
end;

function TAmGridProperty.GetAttributes: TPropertyAttributes;
begin
     Result := [paDialog, paReadOnly, paVCL];
end;
initialization
begin
  SaveRect.v:=false;
  RegisterPropertyEditor(TypeInfo(IAmGrid), nil, '', TAmGridProperty);
end;
end.
