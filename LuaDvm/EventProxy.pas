//--------------------------------------------------------------------------------------------
// This module contains class TLuaEventProxy
// which implements redirection of some control's event to specified LuaFunction.
// For example:
//  local MyBtn=NEW.TButton;
//  MyBtn.OnClick=MyOnClickLuaFunction;
//--------------------------------------------------------------------------------------------
unit EventProxy;

interface
 uses Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,LuaInter,TypInfo;

 //----------------------------------------------------------------------------------------
 // TLuaEventProxy Class.
 // Inherited from TComponent for add it to Control's Components list.
 // (Control which Onxxx property we gona set became an owner of this class)
 // When control will be deleted - attached LuaEventProxyes will be deleted automatically.
 //----------------------------------------------------------------------------------------
 type TLuaEventProxy=class(TComponent)
  public
    //---- Refference to lua function which must handle appropriate Event ----
    FLuaEventHandlerFunction:TByteCodeProto;
    EventPropName:String; //-- for example 'OnClick' - for ability to reset this property externally
    ExecutionInProgress:boolean; //-- $VS23AUG2004 flag for prevent multiple execution of code - discard event
                                 //-- execution when event happens during Lua code execution - it leads to errors
  published
      //--- Event Handlers Wrappers. Must be published (because we use MethodAddress(FuncName) function -------
      procedure TNotifyEventWrapper(Sender: TObject);
      function  THelpEventWrapper(Command: Word; Data: Longint;var CallHelp: Boolean): Boolean;
      procedure TMouseEventWrapper(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
      procedure TMouseMoveEventWrapper(Sender: TObject; Shift: TShiftState;X, Y: Integer);
      procedure TKeyEventWrapper(Sender: TObject; var Key: Word;Shift: TShiftState);
      procedure TKeyPressEventWrapper(Sender: TObject; var Key: Char);
      procedure TCloseEventWrapper(Sender: TObject; var Action:TCloseAction);
      procedure TCloseQueryEventWrapper(Sender: TObject; var CanClose:boolean);
 end;



implementation

//----------------------------------------------------------
// WRAPPERS FOR EVENT HANDLERS
//----------------------------------------------------------
procedure TLuaEventProxy.TNotifyEventWrapper(Sender: TObject);
var
 xLuaFunction:TByteCodeProto;
 Err:integer;
 pV1:TXVariant;
 ErrStr:String;
begin
   if(ExecutionInProgress)then begin
      Exit;
   end;

   xLuaFunction:=FLuaEventHandlerFunction;
   try
     if(Not (xLuaFunction is TByteCodeProto))then begin
       Exit;
     end;

     //--- Create New Set of Locals in callable function and save previous (if it was) in Stack
     xLuaFunction.CreateTmpVarsList;
     //---pass  Sender as function argument ----
     pV1:=xLuaFunction.GetPtrOfArgument(0);
     pV1.Ptr:=Sender;

     //--- DO Call --------
     ExecutionInProgress:=true;
     Err:=0;
     ErrStr:=xLuaFunction.Execute(Err);
     if(ErrStr <> '')then begin
        ExecutionInProgress:=false;
        raise Exception.Create('Error in Event Handler Function:'+ErrStr);
     end;
     //---- We have no Results to pass back --------
     //--- Delete New Set of Locals in callable function and restore previous (if it was) frpm Stack
     xLuaFunction.DeleteTmpVarsList;
     ExecutionInProgress:=false;
   except
      ExecutionInProgress:=false;
      Exit;
   end;
end;

//----------------------------------------------------------
// WRAPPER FOR THelpEvent
//----------------------------------------------------------
function TLuaEventProxy.THelpEventWrapper(Command: Word; Data: Longint;var CallHelp: Boolean): Boolean;
begin
   Result:=false;
end;

//----------------------------------------------------------
// WRAPPER FOR TMouseEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TMouseEventWrapper(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
var
 xLuaFunction:TByteCodeProto;
 Err:integer;
 pV1:TXVariant;
 S1:String;
 r:Lua_Number;
begin
   if(ExecutionInProgress)then begin
      Exit;
   end;

   xLuaFunction:=FLuaEventHandlerFunction;

   try
     if(Not (xLuaFunction is TByteCodeProto))then begin
       Exit;
     end;

     //--- Create New Set of Locals in callable function and save previous (if it was) in Stack
     xLuaFunction.CreateTmpVarsList;
     //---pass  Sender as function argument ----
     pV1:=xLuaFunction.GetPtrOfArgument(0);
     pV1.Ptr:=Sender;

     //--Pass Mouse Button -------
     pV1:=xLuaFunction.GetPtrOfArgument(1);
     S1:='';
     if(Button = mbLeft)then S1:=S1+'mbLeft';
     if(Button = mbRight)then S1:=S1+'mbRight';
     if(Button = mbMiddle)then S1:=S1+'mbMiddle';
     pV1.V:=S1;

     //---Pass Shift state as String -----
     pV1:=xLuaFunction.GetPtrOfArgument(2);
     if(ssShift in Shift)then S1:=S1+'ssShift,';
     if(ssAlt in Shift)then S1:=S1+'ssAlt,';
     if(ssCtrl in Shift)then S1:=S1+'ssCtrl,';
     if(ssLeft in Shift)then S1:=S1+'ssLeft,';
     if(ssRight in Shift)then S1:=S1+'ssRight,';
     if(ssMiddle in Shift)then S1:=S1+'ssMiddle,';
     if(ssDouble in Shift)then S1:=S1+'ssDouble,';
     pV1.V:=S1;

     //---Pass X coord -----
     pV1:=xLuaFunction.GetPtrOfArgument(3);
     r:=X; //-- get as Lua_Number
     pV1.V:=r;

     //---Pass Y coord -----
     pV1:=xLuaFunction.GetPtrOfArgument(4);
     r:=Y; //-- get as Lua_Number
     pV1.V:=r;

     //---At least DO Call --------
     ExecutionInProgress:=true;
     Err:=0;
     S1:=xLuaFunction.Execute(Err);
     if(S1 <> '')then begin
        ExecutionInProgress:=false;
        raise Exception.Create('Error in Event Handler Function:'+S1);
     end;
     //---- We have no Results to pass back --------

     //--- Delete New Set of Locals in callable function and restore previous (if it was) frpm Stack
     xLuaFunction.DeleteTmpVarsList;
     ExecutionInProgress:=false;
   except
      ExecutionInProgress:=false;
      Exit;
   end;

end;

//----------------------------------------------------------
// WRAPPER FOR TMouseMoveEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TMouseMoveEventWrapper(Sender: TObject; Shift: TShiftState;X, Y: Integer);
var
 xLuaFunction:TByteCodeProto;
 Err:integer;
 pV1:TXVariant;
 S1:String;
 r:Lua_Number;
begin
   if(ExecutionInProgress)then begin
      Exit;
   end;

   xLuaFunction:=FLuaEventHandlerFunction;
   try
     if(Not (xLuaFunction is TByteCodeProto))then begin
       Exit;
     end;

     //--- Create New Set of Locals in callable function and save previous (if it was) in Stack
     xLuaFunction.CreateTmpVarsList;
     //---pass  Sender as function argument ----
     pV1:=xLuaFunction.GetPtrOfArgument(0);
     pV1.Ptr:=Sender;

     //---Pass Shift state as String -----
     pV1:=xLuaFunction.GetPtrOfArgument(1);
     if(ssShift in Shift)then S1:=S1+'ssShift,';
     if(ssAlt in Shift)then S1:=S1+'ssAlt,';
     if(ssCtrl in Shift)then S1:=S1+'ssCtrl,';
     if(ssLeft in Shift)then S1:=S1+'ssLeft,';
     if(ssRight in Shift)then S1:=S1+'ssRight,';
     if(ssMiddle in Shift)then S1:=S1+'ssMiddle,';
     if(ssDouble in Shift)then S1:=S1+'ssDouble,';
     pV1.V:=S1;

     //---Pass X coord -----
     pV1:=xLuaFunction.GetPtrOfArgument(2);
     r:=X; //-- get as Lua_Number
     pV1.V:=r;

     //---Pass Y coord -----
     pV1:=xLuaFunction.GetPtrOfArgument(3);
     r:=Y; //-- get as Lua_Number
     pV1.V:=r;

     //---At least DO Call --------
     ExecutionInProgress:=true;
     Err:=0;
     S1:=xLuaFunction.Execute(Err);
     if(S1 <> '')then begin
        ExecutionInProgress:=false;
        raise Exception.Create('Error in Event Handler Function:'+S1);
     end;
     //---- We have no Results to pass back --------

     //--- Delete New Set of Locals in callable function and restore previous (if it was) frpm Stack
     xLuaFunction.DeleteTmpVarsList;
     ExecutionInProgress:=false;
   except
      ExecutionInProgress:=false;
      Exit;
   end;

end;

//----------------------------------------------------------
// WRAPPER FOR TKeyEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TKeyEventWrapper(Sender: TObject; var Key: Word;Shift: TShiftState);
begin
    TControl(Sender).Tag:=1;
end;

//----------------------------------------------------------
// WRAPPER FOR TKeyPressEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TKeyPressEventWrapper(Sender: TObject; var Key: Char);
begin
    TControl(Sender).Tag:=1;
end;

//----------------------------------------------------------
// WRAPPER FOR TCloseQueryEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TCloseQueryEventWrapper(Sender: TObject; var CanClose:boolean);
begin
     //--- Call below funct because of params are the same
     TCloseEventWrapper(Sender,TCloseAction(CanClose));
end;

//----------------------------------------------------------
// WRAPPER FOR TCloseEvent
//----------------------------------------------------------
procedure TLuaEventProxy.TCloseEventWrapper(Sender: TObject; var Action:TCloseAction);
var
  pV1,pV2:TXVariant;
  r:Lua_Number;
  Err:integer;
  S1:String;
  i:integer;
  xLuaFunction:TByteCodeProto;
begin
   if(ExecutionInProgress)then begin
      Exit;
   end;

   xLuaFunction:=FLuaEventHandlerFunction;
   try
     if(Not (xLuaFunction is TByteCodeProto))then begin
       Exit;
     end;

     //--- Create New Set of Locals in callable function and save previous (if it was) in Stack
     xLuaFunction.CreateTmpVarsList;
     //---pass  Sender as function argument ----
     pV1:=xLuaFunction.GetPtrOfArgument(0);
     pV1.Ptr:=Sender;

     pV2:=xLuaFunction.GetPtrOfArgument(1);
     r:=integer(Action);
     pV2.V:=r;
     //---At least DO Call --------
     ExecutionInProgress:=true;
     Err:=0;
     S1:=xLuaFunction.Execute(Err);
     if(S1 <> '')then begin
        ExecutionInProgress:=false;
        raise Exception.Create('Error in Event Handler Function:'+S1);
     end;

     //---- Pass Action back --------
     i:=pV2.V;
     Action:=TCloseAction(i);

     //--- Delete New Set of Locals in callable function and restore previous (if it was) frpm Stack
     xLuaFunction.DeleteTmpVarsList;
     ExecutionInProgress:=false;
   except
      ExecutionInProgress:=false;
      Exit;
   end;
end;


end.
