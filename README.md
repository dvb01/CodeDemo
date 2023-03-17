# CodeDemo




## AmGridEditorToolForm.pas
Редактор  design-time списка, который находится в `AmSystemItems.pas`
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
var ListI:IAmListItem;
    ListO:TAmListItemObj;
begin
   ListI:= TAmListItemInf.Create;
    // список интерфейс
    ListI.Add(TAmItemObject.Create(nil));

   ListO:= TAmListItemObj.Create;
   try
      // список объект
      ListO.Add(TAmItemObject.Create(nil));
   finally
     FreeAndNil(ListO);
   end;

end;
```     

4. в листе не может быть дубликатов
5. лист напрямую не удаляет свои элементы, а вызывает `IAmItem.ListRelease`,  а там уже выполняется действие, например, `TObject.Free` или `TMyObject_IAmItem.List :=nil;`

##  AmThreadPoolTask.pas
 Выделение свободного потока для выполнения объекта или процедуры.
 `TAmObjectTask`  является аналогом `TThread`, но он не создает поток,
 а ему выдают контекст выполнения в `procedure TAmObjectTask.Run;virtual;`
 
 
##  AmUserScale.pas 
Модуль помощи определения текущего масштаба приложения.
Поможет рассчитать высоты размеры шрифтов и т.д.
Требует внешнего вызова при OnMainFormCreate и при  OnMainFormShow.
 
##  AmHookWin.pas
Хук перехвата winapi сообщений для текущего приложения.
1. Создать  TAmWinHookElem
2. Настроить что именно отслеживать и куда пересылать (postmessage sendmessage или вызвать procedure)
3. Запустить	TAmWinHookElem.Start
4. При удалении объекта кто создавал  удалить TAmWinHookElem 
	 

##  AmComboBox.pas 
Заново нарисованный TComboBox состоит из кнопки выподающего попап меню и кастомной панели,
на которую можно поместить список, тогда будет обычный TComboBox.
Можно также повесить произвольный TWinControl и нарисовать на нем  что угодно.
