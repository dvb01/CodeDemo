# CodeDemo




## AmGridEditorToolForm.pas
Редактор  design-time списка, который находится в `AmSystemItems.pas`
##  AmSystemItems.pas
 Список с разными событиями.
 Универсальный лист для разных пронумерованных объектов
 1. имеет события на каждое действие
 2. может хранит все что угодно унаследованное от  `IAmItem`
` IAmItem` просто создается в любом классе можно посмотреть пример `TAmItemPersInf`
3. Каким листом пользоваться.
   `TAmListItemObj`  если нужно, что бы при удалении объекта не проверялось кол-во ссылок. Объект нужно явно удалить через `TObject.Free;`
`TAmListItemInf` если нужно что бы лист удалился сам, а главная ссылка на лист -- это интерфейс.  
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

 5. `TAmListItemObj` удаляется только через `TObject.Free;`
 6. `TAmListItemInf` удаляется  когда счетчик ссылок  равен 0
7. в листе не может быть дубликатов
8. лист напрямую не удаляет свои элементы, а вызывает `IAmItem.ListRelease`,  а там уже выполняется действие `TObject.Free` например или `TMyObject_IAmItem.List :=nil;`
9. Подходит для хранения интерфейсов о изменении индекса которых нужно знать на верхних уровнях абстракций (графические элементы, ноды, деревья, таблицы)


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
