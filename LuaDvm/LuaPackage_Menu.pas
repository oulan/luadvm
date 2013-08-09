//---------------------------------------------------------
// Package for work with TPopupMenu
//--------------------------------------------------------
unit LuaPackage_Menu;

interface
 uses Windows, Messages, SysUtils,Classes,LuaInter,Menus;

 //--------------------------------------------------------------------
 // TPopupMenu class wrapper
 //--------------------------------------------------------------------
 type Package_TPopupMenu=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function AddItem(Params:TList): Integer;
    function GetItem(Params:TList): Integer;
    function GetItemCount(Params:TList): Integer;
    function DeleteItem(Params:TList):Integer;
  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // TMenuItem class wrapper
 //--------------------------------------------------------------------
 type Package_TMenuItem=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function AddItem(Params:TList): Integer;
    function GetItem(Params:TList): Integer;
    function GetItemCount(Params:TList): Integer;
    function DeleteItem(Params:TList):Integer;
  public
    procedure RegisterFunctions;override;
 end;

//---------------------------------------------------------
// Global Instances of above Packages-Classes
//---------------------------------------------------------
var
  //-- Package Instances (created in Initialization section)
  PACK_POPUPMENU:Package_TPopupMenu;
  PACK_MENUITEM:Package_TMenuItem;


implementation
//---------------------------------------------------------
// TPopupMenu
// Class package for support popup menus handling at runtime
// form LUA.
// Package let us: create popup menus,add,change menu items,
// set OnClick event handlers at runtime.
// Note:
// Popup menu contain a list of objects of TMenuItem.
// Because each menu item can have it's own submenu (also
// TMenuItem objects), then class TMenuItem
// has similar functionality as TPopupMenu.
//---------------------------------------------------------
procedure Package_TPopupMenu.RegisterFunctions;
begin
  Methods.AddObject('AddItem',TUserFuncObject.CreateWithName('AddItem',AddItem));
  Methods.AddObject('GetItemCount',TUserFuncObject.CreateWithName('GetItemCount',GetItemCount));
  Methods.AddObject('GetItem',TUserFuncObject.CreateWithName('GetItem',GetItem));
  Methods.AddObject('DeleteItem',TUserFuncObject.CreateWithName('DeleteItem',DeleteItem));

  HandledProps:=TStringList.Create; //--- only for show that it is Class package
end;

//---------------------------------------------------------
// MyPopup:AddItem("NewItem");       -- add new item to menu
// MyPopup:AddItem("NewItem",Index); -- Insert new item into menu
//
// Create new TMenuItem and Add or Insert it to menu
// Examples:
// local MyNewMnu=MyPupMnu:AddItem("Item1");       -- Add New item to menu
// local MyNewMnu=MyPupMnu:AddItem("Top Item1",0); -- Insert new item at top
//---------------------------------------------------------
function Package_TPopupMenu.AddItem(Params:TList): Integer;
var
 PMnu:TPopupMenu;
 xItem:TMenuItem;
 ItemCaption:String;
 Idx:Integer;
begin
  Result:=0;
  PMnu:=TPopupMenu(TXVariant(Params.Items[0]).Ptr);
  ItemCaption:=String(TXVariant(Params.Items[1]).V);
  xItem:=TMenuItem.Create(PMnu);
  xItem.Caption:=ItemCaption;

  if(Params.Count = 3)then begin
     Idx:=TXVariant(Params.Items[2]).V;
     PMnu.Items.Insert(Idx,xItem);
  end else begin
     PMnu.Items.Add(xItem);
  end;

  TXVariant(Params.Items[0]).Ptr:=xItem;
end;

//---------------------------------------------------------
// MyMenu:GetItemCount();
// Return number of menu itmes of Popup menu.
//
// Example:
// local MnuCount=MyPupMenu:GetItemCount();
//---------------------------------------------------------
function Package_TPopupMenu.GetItemCount(Params:TList): Integer;
var
 PMnu:TPopupMenu;
 xVal:LUA_NUMBER;
begin
  Result:=0;
  PMnu:=TPopupMenu(TXVariant(Params.Items[0]).Ptr);
  xVal:=PMnu.Items.Count;
  TXVariant(Params.Items[0]).V:=xVal;
end;


//-----------------------------------------------------------------
// MyMenu:DeleteItem(Index);
//
// Delete Item by specified index.
// Example:
//   local MyNewMenuItem=MyMenu:DeleteItem(0); -- Delete top item
//-----------------------------------------------------------------
function Package_TPopupMenu.DeleteItem(Params:TList): Integer;
var
 PMnu:TPopupMenu;
 ItemIdx:Integer;
begin
  Result:=0;
  PMnu:=TPopupMenu(TXVariant(Params.Items[0]).Ptr);
  ItemIdx:=TXVariant(Params.Items[1]).V;
  if(ItemIdx >= PMnu.Items.Count)then begin
     Exit;
  end;
  PMnu.Items.Delete(ItemIdx);
end;

//---------------------------------------------------------
// MyMenu:GetItem(Index);
//
// Get Item by index: Item indexes goes from "0"!
// Example:
// local MyMenuItem=MyMenu:GetItem(10);
//---------------------------------------------------------
function Package_TPopupMenu.GetItem(Params:TList): Integer;
var
 PMnu:TPopupMenu;
 ItemIdx:Integer;
 xItem:TMenuItem;
begin
  Result:=0;
  PMnu:=TPopupMenu(TXVariant(Params.Items[0]).Ptr);
  ItemIdx:=TXVariant(Params.Items[1]).V;
  if(ItemIdx >= PMnu.Items.Count)then begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;
  xItem:=PMnu.Items[ItemIdx];
  TXVariant(Params.Items[0]).Ptr:=xItem;
end;






//---------------------------------------------------------
// TMenuItem
// Class Package.
// Each Menu (Main form menu or Popup menu) always consists of elements
// (objects) of TMenuItem type.
// Popup menu contain a list of objects of TMenuItem.
// In it's turn,each menu item can have it's own submenu (also
// TMenuItem objects). So in general class TMenuItem
// has similar functionality as TPopupMenu class.
//---------------------------------------------------------
procedure Package_TMenuItem.RegisterFunctions;
begin
  Methods.AddObject('AddItem',TUserFuncObject.CreateWithName('AddItem',AddItem));
  Methods.AddObject('GetItemCount',TUserFuncObject.CreateWithName('GetItemCount',GetItemCount));
  Methods.AddObject('GetItem',TUserFuncObject.CreateWithName('GetItem',GetItem));
  Methods.AddObject('DeleteItem',TUserFuncObject.CreateWithName('DeleteItem',DeleteItem));

  HandledProps:=TStringList.Create; //--- only for show that it is Class package
end;

//---------------------------------------------------------
// muNewItem=MyMnuItem:AddItem("Item1");        -- Add or
// muNewItem=MyMnuItem:AddItem("Item1",Index);  -- Insert by index
//
// Returns: newly created menu item refference.
// Create new TMenuItem and Add or Insert it to submenu
// Examples:
// local MyNewMnu=MyMnuItem:AddItem("Item1");       -- Add New item to menu
// local MyNewMnu=MyMnuItem:AddItem("Top Item1",0); -- Insert new item at top
//---------------------------------------------------------
function Package_TMenuItem.AddItem(Params:TList): Integer;
var
 PMnu:TMenuItem;
 xItem:TMenuItem;
 ItemCaption:String;
 Idx:Integer;
begin
  Result:=0;
  PMnu:=TMenuItem(TXVariant(Params.Items[0]).Ptr);
  ItemCaption:=String(TXVariant(Params.Items[1]).V);
  xItem:=TMenuItem.Create(PMnu);
  xItem.Caption:=ItemCaption;

  if(Params.Count = 3)then begin
     Idx:=TXVariant(Params.Items[2]).V;
     PMnu.Insert(Idx,xItem);
  end else begin
     PMnu.Add(xItem);
  end;

  TXVariant(Params.Items[0]).Ptr:=xItem;
end;

//---------------------------------------------------------
// SubMenuItemsCount=MenuItem:GetItemCount();
// Return Count of submenu items, owned by MenuItem.
//---------------------------------------------------------
function Package_TMenuItem.GetItemCount(Params:TList): Integer;
var
 PMnu:TMenuItem;
 xVal:LUA_NUMBER;
begin
  Result:=0;
  PMnu:=TMenuItem(TXVariant(Params.Items[0]).Ptr);
  xVal:=PMnu.Count;
  TXVariant(Params.Items[0]).V:=xVal;
end;


//-----------------------------------------------------------------
// MyMenuItem:DeleteItem(Index); -- Delete top item
// Delete menu Item from submenu by specified index
// Example:
//  MyMenuItem:DeleteItem(0); -- Delete top item from submenu
//-----------------------------------------------------------------
function Package_TMenuItem.DeleteItem(Params:TList): Integer;
var
 PMnu:TMenuItem;
 ItemIdx:Integer;
begin
  Result:=0;
  PMnu:=TMenuItem(TXVariant(Params.Items[0]).Ptr);
  ItemIdx:=TXVariant(Params.Items[1]).V;
  if(ItemIdx >= PMnu.Count)then begin
     Exit;
  end;
  PMnu.Delete(ItemIdx);
end;

//---------------------------------------------------------
// local MyMenuItem=MyMenuItem:GetItem(Index);
//
// Return submenu Item by index.
// Note: Item indexes goes from "0"!
// Example:
// local MyMenuItem=MyMenu:GetItem(10);
//---------------------------------------------------------
function Package_TMenuItem.GetItem(Params:TList): Integer;
var
 PMnu:TMenuItem;
 ItemIdx:Integer;
 xItem:TMenuItem;
begin
  Result:=0;
  PMnu:=TMenuItem(TXVariant(Params.Items[0]).Ptr);
  ItemIdx:=TXVariant(Params.Items[1]).V;
  if(ItemIdx >= PMnu.Count)then begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;
  xItem:=PMnu.Items[ItemIdx];
  TXVariant(Params.Items[0]).Ptr:=xItem;
end;

//=======================================================================
initialization
RegisterClass(TPopupMenu);
RegisterClass(TMenuItem);

//--- Create string package -----
PACK_POPUPMENU:=Package_TPopupMenu.Create;
PACK_POPUPMENU.RegisterFunctions;
//--- Register this package -----
LuaInter.RegisterGlobalVar('TPopupMenu',PACK_POPUPMENU);

//--- Create string package -----
PACK_MENUITEM:=Package_TMenuItem.Create;
PACK_MENUITEM.RegisterFunctions;
//--- Register this package -----
LuaInter.RegisterGlobalVar('TMenuItem',PACK_MENUITEM);

end.
