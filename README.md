# CodeDemo




## Редактор  design-time PtControl

![Фото](/READMEFILES/3.gif "Фото Программы")
![Фото](/READMEFILES/4.gif "Фото Программы")

##  AmSystemItems.pas
 Список с разными событиями.
 Универсальный лист для разных пронумерованных объектов. Подходит для хранения интерфейсов о изменении индекса, которых нужно знать на верхних уровнях абстракций (графические элементы, ноды, деревья, таблицы)

1.	имеет события на каждое действие, которое можно получить или вызвать, создав новое на верхних уровнях, в процедурах
```pascal
   protected
     procedure Changed(Prm:PAmItemsPrm);virtual;
     procedure DoChanged(Prm:PAmItemsPrm); virtual;
     function ItemsChangedBroadcast(Operation,W,L:integer):integer; virtual;
```
 2. список может хранит все, что унаследованное от  `IAmItem`
` IAmItem` просто создается в любом классе можно посмотреть пример `TAmItemPersInf`,
т.к всю реализацию  `IAmItem` можно выполнить в Proxy  `AmItemHelp`  

3. Каким листом пользоваться.
   
-`TAmListItemObj`  если нужно, что бы при удалении объекта не проверялось кол-во ссылок. Объект нужно удалить через `TObject.Free;`

-`TAmListItemInf` удаляется  когда счетчик ссылок  равен 0
```pascal
procedure TForm3.FormCreate(Sender: TObject);
var ListI:IAmListItem;
    ListO:TAmListItemObj;
    ListPers:TAmListItemColection;
begin
   ListI:= TAmListItemInf.Create;
   try
      // список интерфейс
      ListI.Add(TAmItemObject.Create(nil));
   finally
     ListI:=nil;
   end;

   ListO:= TAmListItemObj.Create;
   try
      // список объект
      ListO.Add(TAmItemObject.Create(nil));
   finally
     FreeAndNil(ListO);
   end;

   ListPers:=TAmListItemColection.Create;
   try
        // список объект, который поддерживается в design-time
        ListPers.Add(TAmItemPersInf.Create(nil));
   finally
     ListPers.Free;
   end;


end;
```     

4. в листе не может быть дубликатов
5. лист напрямую не удаляет свои элементы, а вызывает `IAmItem.ListRelease`,  а там уже выполняется действие, например, `TObject.Free` или `TMyObject_IAmItem.List :=nil;`

##  AmThreadPoolTask.pas
 Выделение свободного потока для выполнения объекта или процедуры.
Основная идея: Заменить систему   Thread = Client на  Object = Client
 `TAmObjectTask`  является аналогом `TThread`, но он не создает поток,
 а ему выдают контекст выполнения в `procedure TAmObjectTask.Run;virtual;`
После выполнения `procedure TAmObjectTask.Run;virtual;` поток передается 
В лист хранения и ждет пока им кто-то воспользуется.
Если срок хранения вышел поток удаляется.
Можно регулировать задержку выдачи потоков
Можно регулировать срок хранения потоков
Можно ограничить кол-во создаваемых потоков
Есть дополнительные классы 
- Список мини задач ` TAmListObjectTaskMini `
     хранит и при удалении останавливает все задачи,
    если задача завершилась раньше удаления `TAmListObjectTaskMini`
- Список группы клиентов ` TAmClientTaskGroup `
   Абстрактная реализация управления клиентами.
   Клиентом является объект `TAmObjectTask`
- Список группы аккаунтов ` TAmClientTaskGroupAcc `
  Управление клиентами с запуском по конкретному времени
```pascal
TAmClientTaskAcc.ClientGetNextPlay:TDateTime;virtual; //нужно вернуть дату когда клиенту запустится
TAmClientTaskAcc.ClientRun;override; // процедура  выполняется в отдельном потоке
```  
##  AmUserScale.pas 
Модуль помощи определения текущего масштаба приложения.
Поможет рассчитать высоты размеры шрифтов и т.д.
Требует внешнего вызова при OnMainFormCreate и при  OnMainFormShow.
``` pascal
procedure TForm3.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  AmUserScale.AmScale.AfterMonitorDpiChanged(NewDPI,OldDPI);
end;

procedure TForm3.FormBeforeMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
   AmUserScale.AmScale.BeforeMonitorDpiChanged(NewDPI,OldDPI);
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  AmUserScale.AmScale.Init;
end;

procedure TForm3.FormShow(Sender: TObject);
begin
   AmUserScale.AmScale.Show;
end;
```
 
##  AmHookWinMsg.pas
Хук перехвата winapi сообщений для текущего приложения.
1. Создать  `TAmWinHookElement`
2. Настроить что именно отслеживать и куда пересылать (postmessage sendmessage или вызвать procedure)
3. Запустить	` TAmWinHookElement.Start`
4. При удалении объекта кто создавал,  удалить ` TAmWinHookElement ` 
```pascal
const
  Test_Message_Post = WM_USER+1;
  Test_Message_Send = WM_USER+2;
  Test_Message_SendErrorCreate = WM_USER+3;
  Test_Message_SendErrorCreate2 = WM_USER+4;
procedure TForm25.FormCreate(Sender: TObject);
begin

  AmUserType.AmSystemInfo.ReportMemory(true);
  El:= AmHookWinMsg.TAmWinHook.NewElement();
  El.ListenWindowHandle:=self.Handle;
  El.ListenMsgAdd([WM_ACTIVATE,
                   WM_PAINT,
                   Test_Message_Post,
                   Test_Message_Send,
                   Test_Message_SendErrorCreate,
                   Test_Message_SendErrorCreate2]);
  El.FromEnum:=  amwinhookFromProc;
  El.FromMsgProc:= ElEvent;
  El.Start;
end;

procedure TForm25.ElEvent(Prm:PAmWinHookMessage);
var FormError:TForm;
begin
  //raise Exception.Create('Error Message');
  // если произойдет ощибка то приложение может  завершится ничего не сообщив
  // лист хуков во время события нельзя изменять создавать или удалять хуки Prm.Element.Free  AmHookWinMsg.TAmWinHook.NewElement();
  // удалять или добавлять новые сообщения можно  Prm.Element.ListenMsgAdd([MY]);

 try
    Memo1.Lines.Add('====');
    case Prm.Message of
         WM_ACTIVATE:begin
             Memo1.Lines.Add(' WM_ACTIVATE '+Prm.WPrm.ToString);
         end;
         WM_PAINT:begin
          Memo1.Lines.Add(' WM_PAINT ');
         end;
         Test_Message_Post :begin

             Memo1.Lines.Add(' Перехвачено PostMessage Test_Message_Post '+
             ' WPrm:'+ Prm.WPrm.ToString +
             ' LPrm:'+Prm.LPrm.ToString );

         end;
         Test_Message_Send:begin

            Memo1.Lines.Add(' Перехвачено SendMessage Test_Message_Send  '+
            ' WPrm:'+Prm.WPrm.ToString +
            ' LPrm:'+Prm.LPrm.ToString );

         end;
         Test_Message_SendErrorCreate:begin

            // ощибка + утечка памяти
            AmHookWinMsg.TAmWinHook.NewElement();

         end;
         Test_Message_SendErrorCreate2:begin

             raise Exception.Create('Error Message');

         end;

    end;
    Memo1.Lines.Add('====');
 except
  on e:exception do
  begin
     // если не обрабатывать исключения то прога вылетит без показа сообщения
     case 1 of
          0:begin
            Memo1.Lines.Add('ErrorCode.TForm25.ElEvent '+e.Message);
          end;
          1:begin
             // показ модальной формы во время выполнения события
              FormError:=TForm.Create(self);
              FormError.Caption:= e.Message;
              FormError.Position:=TPosition.poDesktopCenter;
              FormError.Width:=700;
              FormError.Height:=50;
              FormError.Color:=clred;
              FormError.ShowModal;
          end;
          2:begin
             // показ модальной формы во время выполнения события
             AmLogTo.DefaultFormException.Show(e.Message,e.StackTrace);
          end;
          3:begin
             // показ формы после выполнения события
             AmLogTo.DefaultFormException.ShowPost(e.Message,e.StackTrace);
          end;

     end;

  end;
 end;



end;
```
	 

##  AmComboBox.pas 
Заново нарисованный `TComboBox` состоит из кнопки, выпадающего меню  и панели,
на которую можно поместить список, тогда будет обычный `TComboBox`.
Можно также повесить произвольный `TWinControl` и рисовать на нем.
TAmComboBox внутри себя содержит несколько компонентов. 
`TAmLayOut, TAmPopupMenu, TAmPopupForm, TAmListBox`
Используя класс `TAmComboAbstract` можно создать любой вид выпадающего списка
Используя класс `TAmComboListBox` можно изменить ссылку на `ListBox`, что бы в разных состояниях отображать разные списки или таблицы. 
![Фото](/READMEFILES/1.jpg "Фото Программы")


