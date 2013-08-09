//============================================================================================
// "LUA_DVM"  LUA DELPHI VIRTUAL MACHINE.
// Author: Sergei Vertiev. Moscow 2004
//============================================================================================
//
// This unit implements Loading and Execution of LUA Byte Code from Delphi Application.
// "TByteCodeProto" object is main object which implements Lua_DVM.
//
// The main goal of this project was implement LUA virtual machine on Delphi and for Delphi,
// for being able to execute bytecode direcly from Delphi applications.
// Still "Luac" - Native LUA compiler stays untouched and used for
// produce ByteCode from LUA sources. 
// (Version of LUAC is "5.0" I've not tested following LUAC versions and don't know if they produce incompatible bytecode.
// Probably this must be tested.)
// Another goal was maximal use of some Delphi things, such as:
// Forms,Controls,Lists,Strings,Event handlers (provided as object properties).
// All of this based on intensive usage of Delphi RTTI (run time type information).
// RTTI let us avoid registration of some Objects and their (published) properties.
// This let us work with controls on Forms and Event handlers relativelly easy.
// Also it let us reduce coding for work with internal Delphi controls and objects.
// Unfortunatelly, there is no inforamtion about Object's methods in Delphi RTTI,
// so we still have to wrap methods of Delphi as well as some objects and their
// properties manually.(See "function packages" and "class packages" below).
// It would be nice if Delphi have some options or pragmas for publish everything possible.
// (like it is in Java's reflection api).
// But,in genereal,Lua concept of weak tables let us works with Delphi objects and their properties
// on our own way.
//
// As result of new behaivor of this virtual machine, meaning of some things in Lua byte code
// execution had been chagned.
// From syntax point of view - it is pure Lua language, but from semantic point of view it is
// slightly different.
// I'm not sure that Lua developers appreciates such "violations" of "Lua Spirit".
// Some specific LUA features currently not supported by Lua_DVM. (may be in future?).
// Threads for example, some standard lua function packages and may be something else...
// But on the other hands, some new features concerning Delphi became available.
// For Example - creating objects from Lua (NEW.TxxxObject special function call),
// runtime definition of globals (externals), TList and TStringList support,
// handling Events of Controls (MyButton.OnClick=MyLuaFunction..)e.t.c.
// Otherwords, i would call Lua_DVM another (Delphi?) dialect of Lua.
// Sure, Lua_DVM is portable as well as Delphi is portable,while pure Lua virtual machine
// is really portable for any plathorm.
//
// Thanks to guys who invent Lua and implement Lua Compiler,if we can do something new
// based on their things!!!
//
// Now Technical stuff
// ===================
// About Data Types:
// -=-=-=-=-=-=-=-=-=
// LUA_DVM works internally with data of "TXVariant" type.
// It is a class (see below) which extends standard
// Delphi Variant type for handle both: Variants and Pointers.By the way,currently there is no way
// in Delphi for save Pointers in Variants without side effects.
// Standard data types are saved in variant part of TXVariant (TXVariant.V):e.g. MyTxVariant.V:="101"
// For save pointers (mostly TObjects) - "TXVariant.Ptr" part is used.
// TXVariant implemented so that when we assign "Ptr" - it's "V" - variant part is cleared and
// vise versa. So we always can check: if "Ptr" part <> NIL - TXVariant contains pointer to Object.
// Assumed that all Objects are inherited from (TOBject) for ability to check their type at runtime.
// Only 3 types of variants used: String,boolean and Double (for save numeric values).
//
// Working with globals:
// -=-=-=-=-=-=-=-=-=-=-=
//  When we use something like MyButton.Caption="NEWCAPTION"; in Lua source,
// "MyButton" treated by LUA as global (sure if it's not defined as "local").
//  When interpreting ByteCode - LUA_DVM firstly try to
//  find out "MyButton" in Variables list associated with bytecode's NameSpace
//  (if ByteCode has associated Namespace. See below.), then in GlobalVarsList.
//  If it can't be found there - OnHandleGlobals user handler is called (if assigned).
//  OnHandleGlobals must be provided by user application.
//  Really, "OnHandleGlobals" function can treat Globals on it's own way.
//  In our example: function TForm1.ResolveLuaGlobals(Operation:LUA_OPCODES;pV1,pV2,pV3:TXVariant):integer;
//  try to find control on form with provided name of global (MyButton in our example).
//
//  GlobalVarsList
// -=-=-=-=-=-=-=-=-=-=-=
//  GlobalVarsList - is TStringList which save all defined globals. GlobalVarsList.Objects[i] are
//  TXVariant objects. This list is global scope variable and so it is shared between all Lua functions.
//  This let us use variables with global scope.
//  New records in GlobalVarsList appears as:
//  1) Lua_DVM Internally - as result of "SETTABLE" LUA bytecode instruction (usually Local lua functions)
//  2) From user application by call to "RegisterGlobalFunction(FuncName:String;FuncImplementHandler:TLuaExternFunction):integer;"
//  3) From user application by call to "RegisterGlobalVar(Name:String;xObj:TObject):integer;"
//  4) When OP_SETGLOBAL opcode applayed to global which not found in GlobalVarList
//    (see Module Scope Globals below).
//
//  NOTE:
//  Assumed that all user written functions callable from Lua_DVM is of type:
//  "type TLuaExternFunction = function(Params:TList):integer of object;"
//  Params is TList of TXVariant objects.
//  Delphi function result currently not used and always "Result:=0;"
//  LUA Results can be returned via the same Params:TList objects.
//  Event if function is called whithout parameters - Params list contains one value for return result.
//  (see "LuaPackages" module for samples).
//
//
//  Functions Packages:
// -=-=-=-=-=-=-=-=-=-=-=
//   For organize functions to packages user can create some object inhertied from "TLuaPackage"
//   and add it's own functions as methods of this object. Then this object(TLuaPackage)
//   must be add to global vars with call to "RegisterGlobalVar(...)". (See LuaPackages unit as example).
//   After doing this we can call functions from Lua script as for example "i=str.Length(MyString);"
//
//  Class Methods Packages:
// -=-=-=-=-=-=-=-=-=-=-=
//  Because it is impossible to take information about methods of classes from Delphi RTTI -
//  we have to write wrappers for those methods which we going to call in our LUA scripts.
//  For tie some methods and Class which these methods must applay to we must create Class Packages.
//  It is almost the same as "Functions Packages". The only difference is that Class package must
//  be registered with package name where name is the same as Class name.
//  For example - we create some class (of type "TLuaPackage") and imlement method "Add" in it.
//  Then we register instance of this class (package) as global with name "TStringList".
//  Then,let's say we have the following Lua Source:
//   - - - - - - - - - - - - - -
//   local Lst1=NEW.TStringList;
//   Lst1:Add("String 1");
//   Lst1:Add("String 2");
//   .....
//   Assign(Lst1,Memo1.Lines);  -- functions "Assign" and "Delete" implemented in LuaPackages module.
//   Delete(Lst1);
//   - - - - - - - - - - - - - -
//   In above sample when Lst1:Add("String"); appears - function "Add(" from class package "TStringList"
//   will be called. Lua instruction with Opcode OP_SELF responsible for create stack for such style of calls.
//
//  Inheritance in Class Packages
//  -----------------------------
//  If for example we do not define some method in object's Class but
//  define it in some of object's ancestor class - this method will be called properly when we
//  try to call this method for our object.
//
//  Handling unpublished properties in Class Packages
//  --------------------------------------------------
//  Special method having name "HandleProperties" can be defined in Class Packages.
//  This method will be called each time when property of object of this Class
//  can not be handled by "OnHandleGlobals" provided by user.
//  Object inheritance also supported for "HandleProperties".
//  This means that if you ask for property of object of some class -
//  Sequence of calls to "HandleProperties" methods will be performed for Object's class
//  and for all it's ancestors classes,while some of "HandleProperties" methods not return "1",
//  which mean that property was handled sucessfully. Otherwice, property not defined error occured.
//
//
//  NOTES:
//  ------
//   All objects in GlobalVars list are TXVariants having "Ptr" part - pointer to some Object.
//   Internal LUA functions saved as objects of type = TByteCodeProto
//   User defined functions are saved as objects of type = TUserFuncObject
//   User defined Packages are saved as objects of type = TLuaPackage
//
//   -----------------------------------------------------------------------------------
//   WARNING:
//   All Global Names,Function Names,Package names,Class types names,Properties Names are
//   CASE SENSITIVE!
//   -----------------------------------------------------------------------------------
//
//  Tables
// -=-=-=-=-=-=-=-=-=-=-=
//  Lua Tables base functionality implemented in TLuaTable class.
//  "TableFuncPackage" of LuaPackages module contains set of functions for table manipulation.
//
//  Tables restrictions:
//  -------------------
//   1) Only numeric and/or string keys are accepted for tables.
//    MyTable[MyLocal] -- Is invalid if "MyLocal" contains refference to some object/function.
//    If "MyLocal" is Numeric or String - O.K.
//   2) Currently, some native lua "tables" package functions not supported e.g: "foreach" "foreachi"
//   3) After creation - tables stays in memory till respective TByteCodeProto destructor (Destroy).
//      So, intensive creation of tables (eg. in procedure which called many times) can lead to grow of memory usage.
//      For prevent this user can call "DeleteTables()" build-in function which delete all tables
//      created in context of current function.
//      As alternative to tables user can use NEW.TList or NEW.TStringList with following
//      "Delete(xxxx)".
//
//  Table Extensions:
//  ----------------
// 1) There is some build-in function named "CreateArray(...)" with variable number of parameters.
// This function let us create Multiple dimensioned tables.
// Example:
//  local MyXYZTable=CreateArray(10,20,30); -- Create 3-D table
//  MyXYZTable[1][5][20]="JJJJJJ";
//
// 2)Internally, TLuaTable has TList and TStringList parts which can be accessed with GetTList,GetTStringList functions.
//  Example:
//  local TblList1=table.GetTList(MyLocalTable);
//  local TblStList1=table.GetTStringList(MyLocalTable);
//
// 3) "TableFuncPackage" registered as Function Package and ClassPackage. It can be done,
//     because first parameter of all functions is TLuaTable.
//     So both of following types of calls are valid:
//    local i=table.GetTableLength(MyTbl1);
//    local i=MyTbl1:GetTableLength();
//
// 4) Special temporary table can be used for set properties of some object.
//  Example:
//      MyObject:Properties={Prop1=1;Prop2="xxx";Prop3="yyy"};
//
//  Here "Properties" is some predefined "syntax-type" keyword.
//
//  NOTE: Table of properties is always treated as TEMPORARY and being deleted after set properties operation.
//  So the following usage is valid, but can lead to unexpected results!
//   local X={Prop1=1;Prop2="xxx";Prop3="yyy"};
//   MyObject:Properties=X -- Table X will be destroyed after this assignment!
//
//
//  Special Globals (externals):
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//  SELF - can be set before execute bytecode for reffer to Object which this bytecode belongs.
//         Saving "SELF" into namespace (as static variable) is prefferable and let us always use
//         SELF as byte code owner (usually form object) without names clashes.
//  NEW  - special global object of "TRuntimeObjectCreator" type (see below) which used for create
//         new Delphi objects.
//         for example "local MyCombo=NEW.TComboBox" or "local SLst=NEW.TStringList;"
//         NOTES:
//           1) Delphi function "RegisterClass(...)" must be caled from user application for being able to
//              create class in runtime. Some sequence of "RegisterClass(..)" already exists
//              in "initialization" section of this module.
//
//  NULL - There are a lot of functions which return refference to this object to indicate
//         EMPTY object. Really, NULL is not a part of syntax (as Lua's "nil") but normal global object
//         having empty value.
//         For example:
//            MyNewObj=NEW.TStringList
//            if(MyNewObj == NULL)....      -- check for object was not created.
//
//         NOTE:
//            Standard "nil" never used by this virtual machine.
//
//  MODULE - refference to Currently executed TByteCodeProto object.Needs for implement some functions
//           wich works with TByteCodeProto. For example: MODULE:SaveGlobals(); or MODULE:SaveGlobal(Module.VarName,"VarName2"...);
//           Globals can be accessed which "MODULE.MyGlobalName" style.
//          For example for check if some global name is currently available - the following can be used:
//
//          if(MODULE.MyGlobalFunc ~= NULL)then
//              MyGlobalFunc();  -- Call Global function if available
//          end;
//
//  STATIC - special value for define globals with Static scope.
//          "MyVariable=STATIC" - form of declaration.
//          Such variables stored in module's namespace and are visible for all functions of compiled module (unit).
//
//  PI     - Global variable = 3.14159xxxxxx
//
// Any number of globals can be added in runtime by application (from Delpi code).
// For Example: In MainForm unit:
//      LuaInter.RegisterGlobalVar('Application',Application);
//      LuaInter.RegisterGlobalVar('CurrentForm',Self);
//      LuaInter.RegisterGlobalFunction('SomeFunc',Function1);
//
// Creating Forms and Controls with "NEW"
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
// When we create Controls,they must have being created with proper "Owner". Owner for newly
// created controls is taken from "NewControlsOwner" global variable,which normally must being
// set by application which run Lua bytecode.
// But when we create some Form from Lua and then create some controls for place to this form,
// we probably want that newly created form will be an "Owner" for new controls.
// For doing so there is "ControlsOwner" property of "NEW" global class. Let's see example:
//   ....
//   local MyFrm=NEW.TForm;
//   NEW.ControlsOwner=MyFrm;
//   local Btn1=NEW.TButton;  -- created with Owner=MyFrm
//   local Btn2=NEW.TButton; -- Also created with Owner=MyFrm
//   Btn1.Propeerties={Name="Btn1";Left=0;Top=0;Width=100;Caption="Btn1";Parent=MyFrm};
//   Btn2.Propeerties={Name="Btn2";Left=0;Top=100;Width=100;Caption="Btn1";Parent=MyFrm};
//   MyFrm:ShowModal();
//   NEW.ControlsOwner=NIL; -- Don't forget to reset this property,otherwice after you delete your
//                          -- form - "NEW.ControlsOwner" will contains invalid value!!!
//   ....
//
//
//  Globals and STATIC vs. Upvalues
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
// Upvalues not always works correctly in Lua_DVM!
// It's because of (unfortunatelly) Lua compiler don't treat upvalues as local vars
// of main function, but use some imaginary "upvalue index" in OP_SETUPVAL operation.
// I can't realize meaning of this indexes and connect them somehow to
// real local variables of main function!
//
// Let's see some example:
// --- Lua code sample ---------
// --- It does not works properly in Lua_DVM !!!----------
// local W,X,Y,Z;
// function F1
//    Y=1; --- generate OP_SETUPVAL with index = 1
// end;
// function F2
//    Z=1;  --- Again generate OP_SETUPVAL with index = 1
// end;
//--- Main Function start ---
//   Y=1;   //--- LOADK (load const 1) to local with index 2
//   Z=1;   //--- LOADK (load const 2) to local with index 3
// .......
//
//  If Lua compiler would generate indexes 2 and 3 in functions F1,F2 respectivelly -
//  things will be easier.In this case we will be able to treat X,Y,Z as locals of main function and
//  operate them by indexes in other functions.
//
//  But on the other hand, we can use Globals. I call them "Module scope Globals" because they are
//  automatically added to global vars list when appears and automatically deleted when module
//  being destroyed.
//
// -------- So, Globals work fine...------------
// X=0 Y=0 Z=0;   --- Treated as globals. If such global not exists - Lua_DVM create new ones..
//                --- If exists - just set their values
// function F1
//   Y=1; --- generate OP_SETGLOBLAL
// end;
// function F2
//   Z=1;  --- generate OP_SETGLOBLAL
// end;
//--- Main Function start ---
//   Y=1;   //--- generate OP_SETGLOBLAL
//   Z=1;   //--- generate OP_SETGLOBLAL
// .......
// -- Everything is fine...
//
// ------- If you want Module scope variables - you can use STATIC declaration ------------
// X=STATIC    --- Treated as globals but saved in module namespace
// Y=STATIC
// Z=STATIC
//
// function F1
//   Y=1;
// end;
// function F2
//   Z=1;
// end;
//--- Main Function start ---
//   Y=1;
//   Z=1;
// .......
//
//  Note:
//  1) If some globals are created during function execution -
//     they will be deleted on TByteCodeProto (function's bytecode) destructor.
//  2) For avoid global names overlapping - better use names something like this:"_X" for module scope
//     globals. There can be some starnge behaivor of your program in case of you want to set
//     some external global variable and make mistake in it's name.
//     In this case new var. with invalid name will be created,
//     while real global var. stays untouched and no error messages will appears during prog. execution.
//  3) If you want that Globals don't be deleted after TByteCodeProto destructor, there are
//     SaveGlobals() and SaveGlobal() methods of MODULE global var (see abow).
//     For Example:
//           MODULE:SaveGlobals();   -- save all globals created during module execution
//           MODULE:SaveGlobal(Module.VarName,"VarName2"...); -- save specified globals.
//     Such technique let you create and init some variables in some modules and then use these variables
//     from any other module. It can be convenient for example for store some constants or some program
//     settings creating them from Lua code without changing application code.
//  4) If some global vars contains object refferences (MyGlobal=NEW.TMyObj) -
//     After  execution of  MODULE:SaveGlobals() - some other function must call "Delete(MyGlobal)"
//     for free allocated object.
//  5) Lua tables are destroyed on function's TByteCodeProto destructor it can be
//     unsafe to store refference to table in Global variable which can be saved by "MODULE:SaveGlobals()".
//
//   NameSpaces:
//  =============
// From march of 2004 TByteCodeProto classes (lua functions chunk class) contains "NameSpace" member.
// NameSpace is object of type "TNameSpaceInfo"
//    public members:
//    CtrlForm:TForm;         -- contains refference to some form
//    DupGlobals:TStringList; -- List for hold module scope (static) variables.
//                               Such variables can be defined as Var=STATIC or
//                               by OP_SETGLOBAL with function as argument in case as such
//                               function already exists in GLobal variables list.
//
// CtrlForm - used for properly resolve (find) controls by names,assuming that they belongs to this form.
// DupGlobals - used for store static scope variables and duplicated functions
//              global names for avoid names overlapping (see OP_SETGLOBAL).
// Let's say, we load some form twice with attached lua code. If this code contains some functions,
// first time func. names became global during OP_SETGLOBAL execution. But when the same lua code
// executes in context of next form - OP_SETGLOBAL can simply redefine function globals with new addresses.
// For avoid this - this names will be placed not in GlobalVarsList, but in NameSpace.DupGlobals list.
// Obviously on OP_GETGLOBAL operation - globals are searched by names firstly in NameSpace.DupGlobals list,
// then in GlobalVarsList.
//
//======================================================================================================
//  Implementation specific:
//  About different types of CALLs.
//  When bytecode is "OP_CALL":
//   If Top of callstack is VarString - then it is special Call
//   of type "MyObj:MyFunc(xxx)" - do it with Find_function() and CallObjFunction
//   ELSE:
//     - we get value from variant as TObject and check it's type
//     If it is TByteCodeProto - it is LUA function (internal or Loaded from file)
//     If it is TUserFunction  - call user registered Global function
//====================================================================================================
// TODO:
//   Com objects...
//   time package
//   DLL calls (probably it is better to implement them only in packages).
//   Downloadable Function and Class packages.
//====================================================================================================
unit LuaInter;
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,extdlgs,
  Contnrs,ExtCtrls, StdCtrls,
  MappedFile;


const BPT_LINE_FLAG=$80000000; //--- high bit set in lineinfo means breakpoint for this line ---

//-----------------------------------
// Main Data type usded by Lua_DVM
//-----------------------------------
type TXVariant=class(TObject)
  private
    FPtr:Pointer;
    FV:Variant;
  private
    procedure SetPtr(Value:Pointer);
    procedure SetVariantPart(Value:Variant);
    function  GetXVarType:integer;
    procedure SetXVarType(Value:integer);

  public
    property Ptr:Pointer read FPtr write SetPtr;
    property V:Variant read FV write SetVariantPart;
    property VarType:integer read GetXVarType write SetXVarType;
  public
    constructor Create;
    destructor  Destroy;override;
    procedure   Clear;
    procedure   AssignObj(Obj:TObject);
    procedure   Assign(From:TXVariant);
    function    IsObject:boolean;
end;

type Lua_Number=real;

const LUA_SIGNATURE:String=#27'Lua';	// binary files start with "<esc>Lua"
const LUA_VERSION:Byte=$50;		// last format change was in 5.0
const VERSION0:Byte=$50;		// last major  change was in 5.0
const TEST_NUMBER:Lua_Number=3.14159265358979323846E7;
const MAX_INT=$FFFFFFFF;
const MAX_LUA_STACK=250;


//-- basic LUA types
const LUA_TNONE=         -1;
const LUA_TNIL=           0;
const LUA_TBOOLEAN=       1;
const LUA_TLIGHTUSERDATA= 2;
const LUA_TNUMBER=        3;
const LUA_TSTRING=        4;
const LUA_TTABLE=         5;
const LUA_TFUNCTION=      6;
const LUA_TUSERDATA=      7;
const LUA_TTHREAD=        8;

//--const LUA_MINSTACK:integer=20;

type LuaInstruction=Cardinal; //-- Lua instructions are unsigned ints


type IntArray=array [0..100000] of Cardinal; //-- unsigned 32 bit values
type pIntArray=^IntArray; //--- Pointer to array of int

//-------------------------------
type TLocVar = class(TObject)
  varname:String;
  startpc:integer;  //- first point where variable is active
  endpc:integer;    //- first point where variable is dead
end;

//--- Internal Debug event Notification handler ----------
type TLuaExternFunction = function(Params:TList):integer of object;

//--- Container object for save info about Registered User Global function
//--- Just for easey Create and Destroy
//--- TNotifyEvent has only one parameters Sender:TObject.
//--- User function must treat this as TStringList where objects are of TXVariant type.
type TUserFuncObject=class(TObject)
  public
    FunctionName:String;
    FunctionImplementation:TLuaExternFunction;
  public
   constructor CreateWithName(xFunctionName:String;xFunctionImplementation:TLuaExternFunction);

end;

//-------------------------------------------------------
// Internal class registered in globals with name "NEW"
// This let us create controls in LUA script: e.g.
//  "local MyButton:=NEW.TButton"
// Used for create New objects by class name
// AOwner must be used only if new Control is created
// Usually AOwner is taken from OwnerForNewControls member
// of TByteCodeProto
//-------------------------------------------------------
type TRuntimeObjectCreator=class(TPersistent)
  private
     FControlsOwner:TObject;
     procedure SetControlsOwner(Value:TObject);
  public
    function CreateNewObj(ClassName:String;AOwner:TComponent):TObject;
  published
    property ControlsOwner:TObject read FControlsOwner write SetControlsOwner;
    property Owner:TObject read FControlsOwner write SetControlsOwner;          //-- alias for ControlsOwner
end;

//----------------------------------------------------------
// Pseudo Object used for declare variables
// as Static global (in module namespace scope)
// this Object registered as global with name "STATIC"
//----------------------------------------------------------
type TStaticGlobal=class(TPersistent)
end;

//----------------------------------------------------
// Used as base of user written
// function Packages
// and Class Packages
//----------------------------------------------------
type TLuaPackage=class(TObject)
public
  PackageName:String;
  Methods:TStringList; //-- list of FunctionImplementation:TNotifyEvent; Strings contains Method Names
  HandledProps:TStringList;   //-- Optional list of props which possibli handled by HandleProperties method
public
  constructor Create;virtual;
  destructor  Destroy;override;
  function    Find(FunctionName:String):TUserFuncObject;
  procedure   RegisterFunctions;virtual;
end;

//-------------------------------
// Class for store Lua Tables
// appears in Lua language as
// xxx={a,b,c}
//-------------------------------
type TLuaTable=class(TObject)
  public
    IndexedList:TList;     //--- used for access via digital indexes
    DictList:TStringList;  //--- used for access via String indexes
    TableOwnerList:TList;      //--- saved copy of AOwnerList
    OwnerListIdx:integer;
  private
     function GetIndexListCount:integer;
     function GetDictListCount:integer;
  public
     constructor Create(AOwnerList:TList);
     destructor Destroy;override;
     procedure SetTableValue(Key:TXVariant;Value:TXVariant);
     procedure GetTableValue(Key:TXVariant;Value:TXVariant);
  published
     property iList:TList read IndexedList;
     property sList:TStringList read DictList;
     property iCount:integer read GetIndexListCount;
     property sCount:integer read GetDictListCount;
end;

//------------------------------------------------------------------------
// Class for resolve some globals
// Usually this class shared between few TByteCodeProto
// which belongs to something e.g. to different components of some Form.
// "CtrlForm" field contain this form for properly resolve controls by their Names.
// Also,if we try to OP_SETGLOBAL for some function (TByteCodeProto) and this
// function already exists in GlobalVarsList - we place it to DupGlobals list
// for exclude names overlapping.
// So on OP_GETGLOBAL - firstly we search in DupGlobals list.
//------------------------------------------------------------------------
type TNameSpaceInfo=class(TObject)
  public
    CtrlForm:TForm;
    DupGlobals:TStringList;
  public
    Constructor Create;
    Destructor  Destroy;override;
    function    RegisterGlobalVar(Name:String;xObj:TObject):integer;
end;


//-------------------------------------------------------
// LUA OPCODE FORMAT.
// size and position of opcode arguments.
// In Instruction Word.
// Format of instruction is:(each letter is one bit)
// for 32 bit word:
// AAAAAAAABBBBBBBBBCCCCCCCCCOOOOOO
// AAAAAAAAXXXXXXXXXXXXXXXXXXOOOOOO - for 32 bit word
// Here:
//  A-"A" operand bits
//  B-"B" operand bits
//  C-"C" operand bits
//  O-    opcode  bits
//  X- Bx operand bits for some instructions
//-------------------------------------------------------
const SIZE_C=9;
const SIZE_B=9;
const SIZE_Bx=(SIZE_C + SIZE_B);
const SIZE_A=8;

const SIZE_OP=6;

const POS_C=SIZE_OP;
const POS_B=(POS_C + SIZE_C);
const POS_Bx=POS_C;
const POS_A=(POS_B + SIZE_B);

const MAXARG_Bx=((1 SHL SIZE_Bx)-1);
const MAXARG_sBx=(MAXARG_Bx SHR 1); // `sBx' is signed


const INSTUCT_BITS=sizeof(LuaInstruction)*8; //-- 32 bits/per instruction

//----------------------------------------------------------------------
//  name            args     description
//------------------------------------------------------------------------
type LUA_OPCODES=(
    OP_MOVE,      // A B     R(A) := R(B)
    OP_LOADK,     // A Bx    R(A) := Kst(Bx)
    OP_LOADBOOL,  // A B C   R(A) := (Bool)B; if (C) PC++
    OP_LOADNIL,   // A B     R(A) := ... := R(B) := nil
    OP_GETUPVAL,  // A B     R(A) := UpValue[B]
    OP_GETGLOBAL, // A Bx    R(A) := Gbl[Kst(Bx)]
    OP_GETTABLE,  // A B C   R(A) := R(B)[RK(C)]
    OP_SETGLOBAL, // A Bx    Gbl[Kst(Bx)] := R(A)
    OP_SETUPVAL,  // A B     UpValue[B] := R(A)
    OP_SETTABLE,  // A B C   R(A)[RK(B)] := RK(C)
    OP_NEWTABLE,  // A B C   R(A) := {} (size = B,C)
    OP_SELF,      // A B C   R(A+1) := R(B); R(A) := R(B)[RK(C)]
    OP_ADD,       // A B C   R(A) := RK(B) + RK(C)
    OP_SUB,       // A B C   R(A) := RK(B) - RK(C)
    OP_MUL,       // A B C   R(A) := RK(B) * RK(C)
    OP_DIV,       // A B C   R(A) := RK(B) / RK(C)
    OP_POW,       // A B C   R(A) := RK(B) ^ RK(C)
    OP_UNM,       // A B     R(A) := -R(B)
    OP_NOT,       // A B     R(A) := not R(B)
    OP_CONCAT,    // A B C   R(A) := R(B).. ... ..R(C)
    OP_JMP,       // sBx     PC += sBx
    OP_EQ,        // A B C   if ((RK(B) == RK(C)) ~= A) then pc++
    OP_LT,        // A B C   if ((RK(B) <  RK(C)) ~= A) then pc++
    OP_LE,        // A B C   if ((RK(B) <= RK(C)) ~= A) then pc++
    OP_TEST,      // A B C   if (R(B) <=> C) then R(A) := R(B) else pc++
    OP_CALL,      // A B C   R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    OP_TAILCALL,  // A B C   return R(A)(R(A+1), ... ,R(A+B-1))
    OP_RETURN,    // A B     return R(A), ... ,R(A+B-2)	(see note)
    OP_FORLOOP,   // A sBx   R(A)+=R(A+2); if R(A) <?= R(A+1) then PC+= sBx
    OP_TFORLOOP,  // A C     R(A+2), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                  //         if R(A+2) ~= nil then pc++
    OP_TFORPREP,  // A sBx   if type(R(A)) == table then R(A+1):=R(A), R(A):=next;
                  //         PC += sBx

    OP_SETLIST,   // A Bx    R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= Bx%FPF+1
    OP_SETLISTO,  // A Bx

    OP_CLOSE,     // A       close all variables in the stack up to (>=) R(A)
    OP_CLOSURE    // A Bx    R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))	*/
);


//--------------------------------------------------------
// Notification Event for handle operations with Globals.
// Operation can be one of:
//   OP_GETGLOBAL
//   OP_GETTABLE
//  or
//   OP_GETGLOBAL
//   OP_SETTABLE
// Meaning of P1..3 parameters depends on operation
//--------------------------------------------------------
//--- predeclaration of main class for use it in below functions
//type TByteCodeProto=class; //--- get Error. Why?
type TLuaHadleGlobalEvent = function(xByteCode:TObject;Operation:LUA_OPCODES;P1,P2,P3:TXVariant):integer of object;

//--- Internal Debug event Notification handler ----------
type TLuaDebugHook = function(Sender:TObject;MSG:String):integer of object;

//-----------------------------------------------------------
// Possible Instruction Fields which can be used by commands
//-----------------------------------------------------------
type LUAOPMODE=(iABC, iABx, iAsBx);

//-------------------------------------------
// Define which fields from Instruction word
// used by commands.
//-------------------------------------------
const OpMode:array[LUA_OPCODES] of LUAOPMODE=(
     iABC,   // OP_MOVE
     iABx,   // OP_LOADK
     iABC,   // OP_LOADBOOL
     iABC,   // OP_LOADNIL
     iABC,   // OP_GETUPVAL
     iABx,   // OP_GETGLOBAL
     iABC,   // OP_GETTABLE
     iABx,   // OP_SETGLOBAL
     iABC,   // OP_SETUPVAL
     iABC,   // OP_SETTABLE
     iABC,   // OP_NEWTABLE
     iABC,   // OP_SELF
     iABC,   // OP_ADD
     iABC,   // OP_SUB
     iABC,   // OP_MUL
     iABC,   // OP_DIV
     iABC,   // OP_POW
     iABC,   // OP_UNM
     iABC,   // OP_NOT
     iABC,   // OP_CONCAT
     iAsBx,  // OP_JMP
     iABC,   // OP_EQ
     iABC,   // OP_LT
     iABC,   // OP_LE
     iABC,   // OP_TEST
     iABC,   // OP_CALL
     iABC,   // OP_TAILCALL
     iABC,   // OP_RETURN
     iAsBx,  // OP_FORLOOP
     iABC,   // OP_TFORLOOP
     iAsBx,  // OP_TFORPREP
     iABx,   // OP_SETLIST
     iABx,   // OP_SETLISTO
     iABC,   // OP_CLOSE
     iABx    // OP_CLOSURE
);

//-----------------------------------------------------------
// Instruction Names. Used only for Print Listing/Debugging
//-----------------------------------------------------------
const OpCodeNames:array[LUA_OPCODES] of String=(
    'MOVE',
    'LOADK',
    'LOADBOOL',
    'LOADNIL',
    'GETUPVAL',
    'GETGLOBAL',
    'GETTABLE',
    'SETGLOBAL',
    'SETUPVAL',
    'SETTABLE',
    'NEWTABLE',
    'SELF',
    'ADD',
    'SUB',
    'MUL',
    'DIV',
    'POW',
    'UNM',
    'NOT',
    'CONCAT',
    'JMP',
    'EQ',
    'LT',
    'LE',
    'TEST',
    'CALL',
    'TAILCALL',
    'RETURN',
    'FORLOOP',
    'TFORLOOP',
    'TFORPREP',
    'SETLIST',
    'SETLISTO',
    'CLOSE',
    'CLOSURE'
);

//type LocVarArray=array [0..1000] of LocVar;
//type pLocVarArray=^LocVarArray; //--- Pointer to array of LocVar records

//=======================================================================================
// CLASS "TByteCodeProto"
// It is the main class which implements Lua binary file loading and
// Virtual Machine for interpret ByteCode.
// Bytecode makes dial with set of local variables (something like registers)
// invoked by indexes in commands. All Local variables resides in
// TmpVarList. If index of register in command > 250 - then it is refference to
// constant from ConstList.
// Globals (or external variables) resides in GlobalVarsList...
//======================================================================================
type TByteCodeProto=class(TObject)
public
  //CommonHeader;
  lineinfo     :pIntArray;     //-- map from opcodes to source lines (when compiled with Debug option)
  locvars      :TList;         //-- List of Objects of local variables.
                               //-- Really this list holds only info about local variables.
                               //-- But values of local variables are in TmpVarsList
                               //-- So TmpVarsList - is something like memory on Stack
                               //-- and only first cells of this list are named (as local vars)
  upvalues     :TStringList;   //-- upvalue names (upvalues currently not be used)
  source       :String;
  sizeupvalues :integer;
  sizek        :integer;       //-- number of constants
  sizecode     :integer;
  sizelineinfo :integer;
  sizep        :integer;       //-- number of internal functions (saved as list of TByteCodeProto objects)
  sizelocvars  :integer;
  lineDefined  :integer;
  gclist       :TList;         //-- List of GCObject
  nups         :Byte;          //-- number of upvalues
  numparams    :Byte;          //-- number of function params
  is_vararg    :Byte;          //-- true if variable number of function params
  maxstacksize :Byte;          //-- max stack size of function (really number of locals+number of temp vars needs for function interpret)
  swap         :Byte;          //-- Flag used for Load. Swap bytes on load - Not implemented here.

  //--- Addons ------
  ParentProto  :TByteCodeProto;   //--- For internal functions - points to main (Outer) function. For main = NIL.
//  RegisteredFuncList:TStringList; //--- For distinguish functions and Global objects - Glob.Functions must be registerd
//                                  //--- String=FunctionName. Obj=Ptr of TNotifyEvent type. Func Params is always TList of Variants
  ConstList    :TList;            //-- Functions constants : List of Variants used by the function
  pCode        :pIntArray ;       //-- pointer to array of function instructions

  //-- Attached TByteCodeProto clases of functions defined inside this function (if any)
  InternalFunctionsList:TList; //-- list of TByteCodeProto objects

  MapInfo      :TMapFileInfo;  //--- If Mapped file used
  pBinStart    :Pointer;       //--- pointer to start of file
  pBin         :Pointer;       //--- current pointer
  Loaded       :boolean;       //--- true when file loaded

  //--- Events -------
//  OnHandleGlobals:TLuaHadleGlobalEvent; //--- must be set for resolve External GLobals if they exists in LUA program
//  OnDebugHook    :TLuaDebugHook;        //--- Debugger hook. If set - OnDebugHook called before each instruction execution


//  GlobalVarsList:TStringList;   //--- StringList holding Name of Global and TXVariant as Object.
                                //--- Only vars used as SETGOBAL resides here.
                                //--- Other Globals treat as weak-refferenced objects,refferenced by object Names
                                //--- GetGlobal "ObjectName" GetTable "PropName" - get Property of object
                                //--- GetGlobal "ObjectName" SetTable "PropName" - set Property of object

  AddedToGlobals:TStringList;  //--- list for store globals added internally by OP_SETGLOBAL
                               //--- needs for cleanup this values from list on Return

  InternalTablesList:TList;        //--- List of all TLuaTables created. needs for properly delete all create tables
  CreateArrayFunc:TUserFuncObject; //--- Build in user-like function for implement CreateArray internally
                                   //--- we need implement it internally for save created tables in list
                                   //--- for properly delete them

  DeleteTablesFunc:TUserFuncObject;    //--- Delete all tables
  NameSpace:TNameSpaceInfo;            //--- Additional obj. usually TNameSpaceInfo used for
                                       //--- Save STATIC vars, Duplicated globals, SELF pointer
                                       //--- (which usually is TForm where this code belongs)
  //-- RunTime stuff -------
  ExecutionFinished:boolean;

  TmpVarsListStack:TStack;      //--- Saved TmpVarsLists used for CALL/RETURN operations
  TmpVarsList   :TList;         //--- List of maxstacksize length needs for VM instructions execution
  PC            :integer;       //--- Current Program Counter (index in array of instructions)
//  RuntimeObjectCreator:TRuntimeObjectCreator;
//  NewControlsOwner:TComponent;    //--- Used when NEW.SomeControl is created
private
  function  LoadStr:String;    //-- Load lua-style string from LUA binary file
  function  LoadByte:Byte;
  function  LoadInt:integer;
  function  LoadNumber:Lua_Number;
  procedure LoadBlock(Adr:PChar;BlkSize:integer); //-- Copy BlkSize of bytes from Bin buffer to specified address
  procedure LoadSignature;

  procedure LoadHeader;        //-- Load header part of binary file
  procedure LoadSrcLinesInfo;  //-- Load Line numbers info part of binary file
  procedure LoadLocals;        //-- Load Local vars of function part of binary file
  procedure LoadUpvalues;      //-- Load UpValues part of binary file
  procedure LoadConstants;     //-- Load Constants and Internal functions part of binary file
  procedure LoadCode;          //-- Load Instructions part of binary file
  procedure LoadFunction;      //-- Agregate func. for load parts of function

  procedure ExecuteInstruction;
  function  CheckForPredefinedProperties(Operation:LUA_OPCODES;xObj:TObject;PropVar,pValue:TXVariant):boolean;

  function  CallLuaFunction(xLuaFunction:TByteCodeProto;A,B,C:integer):integer;
  function  CallUserGlobalFunction(xObj:TUserFuncObject;A,B,C:integer):integer;
  function  CallFunctionOfObject(xObj:TObject;A,B,C:integer):integer;
  function  FindMethodWithInheritance(ParentClass:TClass;GlobalIdx:integer;var S1:String;var FuncObj:TUserFuncObject):boolean;
  function  GetPropFromClassPackage(Operation:LUA_OPCODES;pV1,pV2,pV3:TXVariant):integer;
  function  GetListOfInheritedMethods(xObj:TObject;MethodName:String):TList;
  procedure SetPropertyEx(pV1,pV2,pV3:TXVariant);
  procedure SetPropsFromTable(pV2,pV3:TXVariant);

  function  CreateArray(Params:TList):integer;   //--- build in Lua func for create multidim array
  function  DeleteTables(Params:TList):integer;
  function  AddTableTo(Indexes:TList;RecursLevel:integer):TLuaTable; //--- internal for CreateArray

  procedure GetIDispatchProp(pvObject,pvPropName,pvResult:TxVariant;SetPropFlag:boolean);

public //
  constructor Create(AOwner:TComponent); //--- owner used only for creating NEW controls with script
  destructor  Destroy;override;

public
  //--- Load LUA OUT files (ByteCode) from file or from buffer ------
  procedure LoadBinary(FName:String);
  procedure LoadBinaryByPtr(pBuf:Pointer);

  //--- Create StringList with assembly listing for debugging or printing
  function  PrintBinary:TStringList;
  //--- Create list of Opcode and parameters for Debug purpoces --------
  function  GetOperationInfo(iPC:integer):TStringList;


  //--- register user function as LUA global.
  //--- Registered Functions must be implemented in some class and called as
  //--- FuncImplementHandler(ParamList:TObject); Were ParamList is TList of pointers to Variant types
  function  RegisterGlobalFunction(FuncName:String;FuncImplementHandler:TLuaExternFunction):integer;
  function  RegisterGlobalVar(Name:String;xObj:TObject):integer;

                               //-- Declared as Public because needs if call LuaFunc from user code.
  procedure CreateTmpVarsList; //-- create new set of TmpVars and push previous to stack if need
  procedure DeleteTmpVarsList; //-- free current TmpVarsList and pop previous from stack if need
  function  GetPtrOfArgument(I:integer):TXVariant;

  //--- Try to execute loaded bytecode. If OK - ErrLevel=0 returned.
  function Execute(var ErrLevel:integer):String;
  function GetSrcLineByPC(ProgCounter:integer):integer; //--- return SrcLine where runtime error occured
end;


//--- register function of some class as LUA global
function  RegisterGlobalFunction(FuncName:String;FuncImplementHandler:TLuaExternFunction):integer;
//--- register Global Variable/Function Package/Class Package
function  RegisterGlobalVar(Name:String;xObj:TObject):integer;
function  RegisterGlobalConst(Name:String;xVar:TXVariant):integer;
function  UnRegisterGlobalVar(Name:String;xObj:TObject):integer;
function  FindGlobalInList(Name:String;xObj:TObject):integer;
procedure ClearGlobalVarsList;

//------ Functions for set specified Global variable to some value -----------
function SetLuaGlobal(GlobalVarname:String;Value:String):integer;overload;
function SetLuaGlobal(GlobalVarname:String;Value:integer):integer;overload;
function SetLuaGlobal(GlobalVarname:String;Value:real):integer;overload;
function SetLuaGlobal(GlobalVarname:String;Value:boolean):integer;overload;
function SetLuaGlobal(GlobalVarname:String;Value:TObject):integer;overload;

//--------------------------------------------------------------------
// Overall Globals used for execute different TByteCodeProto objects
//--------------------------------------------------------------------
var
 //--- Store most internal runtime error information
 ErrorInByteCode:TByteCodeProto;
 ErrorInLine:integer; //--- if lines info exists in bytecode - store line where runtime error occured
 ErrorInPC:integer;   //--- store bytecode ProgramCounter (index of instruction) where runtime error occured.
 ErrString:String;

 //----- Global Lua objects -------
 NullPtrObject:TXVariant;
 PiValue:TXVariant;
 //--- Events -------
 OnHandleGlobals:TLuaHadleGlobalEvent; //--- must be set for resolve External GLobals if they exists in LUA program
 OnDebugHook    :TLuaDebugHook;        //--- Debugger hook. If set - OnDebugHook called before each instruction execution


 GlobalVarsList:TStringList;   //--- StringList holding Name of Global and TXVariant as Object.
                               //--- Only vars used as SETGOBAL resides here.
                               //--- Other Globals treat as weak-refferenced objects,refferenced by object Names
                               //--- GetGlobal "ObjectName" GetTable "PropName" - get Property of object
                               //--- GetGlobal "ObjectName" SetTable "PropName" - set Property of object


 RuntimeObjectCreator:TRuntimeObjectCreator;
 NewControlsOwner:TComponent;    //--- Used when NEW.SomeControl is created
 StaticPseudoObject:TStaticGlobal;

implementation

//-------------------------------------------------------------
// Register User Global function
//-------------------------------------------------------------
function  RegisterGlobalFunction(FuncName:String;FuncImplementHandler:TLuaExternFunction):integer; //--- register function of some class as LUA global
var
  pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
  end;

  //--- Create object for discribe User funcion ----
  pUserFuncObj:=TUserFuncObject.Create;
  pUserFuncObj.FunctionImplementation:=FuncImplementHandler;
  pUserFuncObj.FunctionName:=FuncName;

  //-- Create variant and save pointer to pUserFUncObj in it
  pV:=TXVariant.Create;
  pV.Ptr:=Pointer(pUserFUncObj);

  //--- Add variant to globals list -------
  try
    Result:=GlobalVarsList.AddObject(FuncName,TObject(pV));
  except
     on EStringListError do begin
         S:='Function "'+FuncName+'"'+CHR(13)+'already registered as Global.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalFunction',MB_APPLMODAL);
     end;
  end;
end;

//------------------------------------------------------
// Find Global in list.
// if xObj <> Nil - check if it is the same
//------------------------------------------------------
function  FindGlobalInList(Name:String;xObj:TObject):integer;
var
 Idx:Integer;
begin
   Result:=-1;
   //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
   if(GlobalVarsList = Nil)then begin
      Exit;
   end;

   if(GlobalVarsList.Find(Name,Idx))then begin
      if(xObj <> Nil)then begin
        if(GlobalVarsList.Objects[Idx] <> xObj)then begin
           Exit;
        end;
      end;
      Result:=Idx;
   end;

end;

//----------------------------------------------------------------
// Save Constant value in global list
//----------------------------------------------------------------
function  RegisterGlobalConst(Name:String;xVar:TXVariant):integer;
var
 // pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
  end;

  if(xVar = NIL)then Exit;
  pV:=xVar;

  //--- Add variant to globals list -------
  try
    //--- Change Global Var if already exists ---
    if(GlobalVarsList.Find(Name,Idx))then begin
      GlobalVarsList.Objects[Idx]:=TObject(pV);
      Result:=Idx;
    end else begin
      //-- Add New global var -------
      Result:=GlobalVarsList.AddObject(Name,TObject(pV));
    end;
  except
     //----- Really obsolete --------
     on EStringListError do begin
         S:='Global "'+Name+'"'+CHR(13)+'already registered.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalVar',MB_APPLMODAL);
     end;
  end;

end;

//-------------------------------------------------------------
// Register some object (inherited from TObject) as Global Var
//-------------------------------------------------------------
function  RegisterGlobalVar(Name:String;xObj:TObject):integer;
var
 // pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
  end;

  if(xObj = NIL)then Exit;

  //--- Add variant to globals list -------
  try
    //--- Change Global Var if already exists ---
    if(GlobalVarsList.Find(Name,Idx))then begin
      pV:=TXVariant(GlobalVarsList.Objects[Idx]);
      pV.Ptr:=Pointer(xObj);
      //GlobalVarsList.Objects[Idx]:=TObject(pV);
      Result:=Idx;
    end else begin
      //-- Add New global var -------
      //-- Create variant and save pointer to pUserFUncObj in it
      pV:=TXVariant.Create;
      //-- show it is pointer to object. And then we can recognize
      //-- special objects by checking their types
      pV.Ptr:=Pointer(xObj);
      Result:=GlobalVarsList.AddObject(Name,TObject(pV));
    end;
  except
     //----- Really obsolete --------
     on EStringListError do begin
         S:='Global "'+Name+'"'+CHR(13)+'already registered.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalVar',MB_APPLMODAL);
     end;
  end;

end;


//-------------------------------------------------------------
// UnRegister global from GlobalVarsList.
// if "xObj = Nil" - assumed simple global variant object
//-------------------------------------------------------------
function  UnRegisterGlobalVar(Name:String;xObj:TObject):integer;
var
 // pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
     Exit;
  end;

  //--- Change Global Var if already exists ---
  if(GlobalVarsList.Find(Name,Idx))then begin
      pV:=TXVariant(GlobalVarsList.Objects[Idx]);
      //--- Check specified object (can be Nil for simple Variant globals) ---
      if(pV.Ptr <> xObj)then begin
         Exit;
      end;
      pV.Destroy;
      GlobalVarsList.Delete(Idx);
      Result:=1;
  end;
end;

//---------------------------------------------
// Delete all globals
//---------------------------------------------
procedure ClearGlobalVarsList;
var
 i:integer;
 pV:TXVariant;
begin
  //--- Delete List of Functions if was created ----
  if(GlobalVarsList <> Nil)then begin
    for i:=0 to GlobalVarsList.Count-1 do begin
       pV:=TXVariant(GlobalVarsList.Objects[i]);
       pV.Destroy;
    end;
    GlobalVarsList.Free;
  end;
  GlobalVarsList:=Nil;

end;


//---------------------------------------------
// TXVariant implementation.
// VIrtual Machine works only with these.
//---------------------------------------------
constructor TXVariant.Create;
begin
    inherited Create;
    FPtr:=Nil;
end;

//-----------------------------------
destructor TXVariant.Destroy;
begin
   VarClear(FV);
   Inherited Destroy;
end;

//-----------------------------------
procedure TXVariant.Clear;
begin
   FPtr:=Nil;
   VarClear(FV);
end;

//-----------------------------------
procedure TXVariant.Assign(From:TXVariant);
begin
   if(From.Ptr <> Nil)then begin
     FPtr:=From.Ptr;
     VarClear(FV);
   end else begin
     //if(From.VarType = varString)then begin
     //  //-- For avoid string pointer assignments only - do real Copy of string
     //  FV:=Copy(String(From.V),1,Length(String(From.V)));
     //end else begin
       FV:=From.V;
       FPtr:=Nil;
     //end;
   end;
end;

//-----------------------------------
procedure TXVariant.AssignObj(Obj:TObject);
begin
   FPtr:=Pointer(Obj);
end;

//-----------------------------------
function  TXVariant.IsObject:boolean;
begin
   Result:=FPtr <> Nil;
end;

//-----------------------------------
// VarType property Getter
//-----------------------------------
function TXVariant.GetXVarType:integer;
begin
   Result:=TVarData(FV).VType;
end;

//-----------------------------------
// VarType property Setter
//-----------------------------------
procedure TXVariant.SetXVarType(Value:integer);
begin
   TVarData(FV).VType:=Value;
end;

//-----------------------------------
// Ptr property Setter
//-----------------------------------
procedure TXVariant.SetPtr(Value:Pointer);
begin
     FPtr:=Value;
     VarClear(FV);
end;

//-----------------------------------
// V property Setter
//-----------------------------------
procedure TXVariant.SetVariantPart(Value:Variant);
begin
  FV:=Value;
  FPtr:=Nil;
end;


//---------------------------------------------------------
// TUserFuncObject constructor
//---------------------------------------------------------
constructor TUserFuncObject.CreateWithName(xFunctionName:String;xFunctionImplementation:TLuaExternFunction);
begin
   inherited Create;
   FunctionName:=xFunctionName;
   FunctionImplementation:=xFunctionImplementation;
end;


//---------------------------------------------------------
// Object for Create Delphi objects at Runtime by ClassName
//---------------------------------------------------------
function  TRuntimeObjectCreator.CreateNewObj(ClassName:String;AOwner:TComponent):TObject;
var
  xClass:TPersistentClass;
  //xComponentClass:TClass;
begin

  //--- TList is not TPersistent, so create it hardcoded ----
  if(ClassName = 'TList')then begin
      Result:=TList.Create;
      Exit;
  end;

  //--- TList is not TPersistent, so create it hardcoded ----
  if(ClassName = 'TForm')then begin
      Result:=TForm.CreateNew(AOwner);
      TForm(Result).Parent:=Nil;
      Exit;
  end;

  //--- Create Class inherited from TPersistent ----
  //-- Assumed that it was previously registered by "RegisterClass(xxClass)"
  xClass:=GetClass(ClassName);
  if(xClass <> Nil)then begin
     //--- If it is TComponent - create it with valid owner ---
     if(xClass.InheritsFrom(TComponent))then begin
       //Result.Free;
       if(FControlsOwner <> Nil)then begin
         Result:=TComponentClass(xClass).Create(TComponent(FControlsOwner));
       end else begin
         Result:=TComponentClass(xClass).Create(AOwner);
       end;
     end else begin
       //--- Else create class without owner ---
       Result:=xClass.Create;
     end;

  end else begin
     raise Exception.Create('NEW.'+ClassName+' -not TPersistent or RegisterClass('+ClassName+') ommited.');
  end;
end;

//--------------------------------------------------------------
// used when "NEW.ControlsOwner=xxxx" executed
//--------------------------------------------------------------
procedure TRuntimeObjectCreator.SetControlsOwner(Value:TObject);
var
 S:String;
begin
   S:=Value.ClassName;
   if(Value = NullPtrObject)then begin
      FControlsOwner:=Nil; //--- reset
   end else begin
      FControlsOwner:=Value;
   end;
end;



//---------------------------------------
// TLuaPackage implementation
// Add on for handle bunch of functions
//---------------------------------------
constructor TLuaPackage.Create;
begin
   inherited Create;
   HandledProps:=Nil;           //-- Used for reflection only can be filled on RegisterFunctions
   Methods:=TStringList.Create; //-- list of FunctionImplementation:TNotifyEvent; Strings contains Method Names
   Methods.Sorted:=true;
   Methods.Duplicates:=dupIgnore;
   PackageName:=Self.ClassName;
end;

//---------------------------------------
destructor TLuaPackage.Destroy;
begin
   Methods.Free;
   if(HandledProps <> Nil)then begin
     HandledProps.Free;
   end;
   inherited Destroy;
end;

//---------------------------------------
function TLuaPackage.Find(FunctionName:String):TUserFuncObject;
var
  i:integer;
  xObj:TObject;
begin
    Result:=NIL;
    if(Methods.Find(FunctionName,i))then begin
       xObj:=Methods.Objects[i];
       if(xObj is TUserFuncObject)then begin
         Result:=TUserFuncObject(xObj);
       end;
    end;
end;

//---------------------------------------
procedure  TLuaPackage.RegisterFunctions;
begin
  ;;;
end;

//-------------------------------
// TLuaTable implementation
//-------------------------------
constructor TLuaTable.Create(AOwnerList:TList);
begin
   inherited Create;
   IndexedList:=Nil;
   DictList:=Nil;

   //---- Add newly created table to specified list -------
   //---- For creator will be able to delete this table by this list --
   if(AOwnerList = Nil)then begin
      AOwnerList:=TList.Create;
   end;
   OwnerListIdx:=AOwnerList.Add(Self);  //-- This index must not changed!!! $VS31MAY2005
   Self.TableOwnerList:=AOwnerList; //-- save owner list
end;

//------------------------------------
// Lua Table Destructor
//------------------------------------
destructor TLuaTable.Destroy;
var
 i:integer;
 pV:TXVariant;
begin
  //--- Delete List of Indexed vars ----
  if(IndexedList <> Nil)then begin
    for i:=0 to IndexedList.Count-1 do begin
       pV:=TXVariant(IndexedList.Items[i]);
       //---- If element of table is TLuaTable - also destroy it---
       //if(pV.isObject)then begin
       //  if(TObject(pV.Ptr) is TLuaTable)then begin
       //     TLuaTable(pV.Ptr).Destroy;
       //  end;
       //end;

       pV.Destroy;
    end;
    IndexedList.Free;
  end;

  //--- Delete List of Indexed vars ----
  if(DictList <> Nil)then begin
    for i:=0 to DictList.Count-1 do begin
       pV:=TXVariant(DictList.Objects[i]);

       //---- If element of table is TLuaTable - also destroy it---
       //if(pV.isObject)then begin
       //  if(TObject(pV.Ptr) is TLuaTable)then begin
       //     TLuaTable(pV.Ptr).Destroy;
       //  end;
       //end;

       pV.Destroy;
    end;
    DictList.Free;
  end;

  inherited Destroy;
end;

//-------------------------------------------------------
// Set value into table
// Support only numeric and String indexes
// Indexes goes from 1 (as defined in native Lua )
//-------------------------------------------------------
procedure TLuaTable.SetTableValue(Key:TXVariant;Value:TXVariant);
var
 i,idx:Integer;
 pV:TXVariant;
begin
   //--- Object indexes not supported for awile --
   if(Key.isObject)then begin
       raise Exception.Create('Table Objects indexes currently not supported in Lua_DVM!');
   end;

   //--- If Key is String -------
   if(Key.VarType = varString)then begin
         if(DictList = Nil)then begin
           DictList:=TStringList.Create;
           DictList.Duplicates:=dupIgnore;
           //-- default is unsorted can be set by table.Sort() method
           //DictList.Sorted:=true; //-- for quick access by keys
         end;

         //--- if List is Sorted then IndexOf use Find - quick method
         idx:=DictList.IndexOf(String(Key.V));
         //--- If found --------
         if(idx >=0 )then begin
            pV:=TXVariant(DictList.Objects[idx]);
            pV.Assign(Value);
         end else begin
            pV:=TXVariant.Create;
            pV.Assign(Value);
            DictList.AddObject(String(Key.V),pV);
         end;
         Exit;
   end;

   //--- If Key is Numeric -------
   if(Key.VarType = varDouble)then begin
         if(IndexedList = Nil)then begin
           IndexedList:=TList.Create;
         end;

         idx:=Key.V;

         if(idx <= 0)then begin
            raise Exception.Create('Invalid Table Index (<= 0) !');
            Exit;
         end;

         //--- Add elements to list if needs so -----
         if(idx > IndexedList.Count)then begin
             for i:=1 to (idx-IndexedList.Count) do begin //-- fix: was i:=0
               pV:=TXVariant.Create;
               IndexedList.Add(pV);
             end;
         end;

         //-- From Lua table index to TList index ---
         //-- NOTE: Table indexes in Lua goes from 1!!!
         Dec(idx);

         pV:=TXVariant(IndexedList.Items[idx]);
         pV.Assign(Value);
         Exit;
   end;
end;

//-------------------------------------------------------
// Get value from table
// Support only numeric and String indexes
// Note:
//  Indexes goes from 1 (as defined in native Lua )
//-------------------------------------------------------
procedure TLuaTable.GetTableValue(Key:TXVariant;Value:TXVariant);
var
 idx:Integer;
 pV:TXVariant;
begin
   //--- Object indexes not supported for awile --
   if(Key.isObject)then begin
       raise Exception.Create('Table Objects indexes currently not supported in Lua_DVM!');
   end;

   //--- If Key is String -------
   if(Key.VarType = varString)then begin
         if(DictList = Nil)then begin
            Value.Ptr:=NullPtrObject;
            Exit;
         end;

         idx:=DictList.IndexOf(String(Key.V));
         if(idx >=0 )then begin
            pV:=TXVariant(DictList.Objects[idx]);
            Value.Assign(pV);
         end else begin
            Value.Ptr:=NullPtrObject;
         end;
         Exit;
   end;

   //--- If Key is Numeric -------
   if(Key.VarType = varDouble)then begin

         idx:=Key.V;

         if((IndexedList = Nil) or (idx <= 0))then begin
            Value.Ptr:=NullPtrObject;
            Exit;
         end;

         //--- Add elements to list if needs so -----
         if(idx > IndexedList.Count)then begin
            Value.Ptr:=NullPtrObject;
         end;

         //-- From Lua table index to TList index ---
         //-- NOTE: Table indexes in Lua goes from 1!!!
         Dec(idx);

         pV:=TXVariant(IndexedList.Items[idx]);
         Value.Assign(pV);
         Exit;
   end;
end;

//------------------------------------
function TLuaTable.GetIndexListCount:integer;
begin
   Result:=0;
   if(IndexedList = Nil)then Exit;
   Result:=IndexedList.Count;
end;

//------------------------------------
function TLuaTable.GetDictListCount:integer;
begin
   Result:=0;
   if(DictList = Nil)then Exit;
   Result:=DictList.Count;
end;


//------------------------------------
constructor TNameSpaceInfo.Create;
begin
    inherited Create;
    CtrlForm:=NIL;
    DupGlobals:=TStringList.Create;
    DupGlobals.Sorted:=true;
    DupGlobals.Duplicates:=dupError;
end;

//------------------------------------
destructor TNameSpaceInfo.Destroy;
var
 i:integer;
 pV:TXVariant;
begin
  //--- Delete List of Functions if was created ----
  if(DupGlobals <> Nil)then begin
    for i:=0 to DupGlobals.Count-1 do begin
       pV:=TXVariant(DupGlobals.Objects[i]);
       pV.Destroy;
    end;
    DupGlobals.Free;
  end;
  DupGlobals:=Nil;
  inherited Destroy;
end;

//-------------------------------------------------------------
// Register some object (inherited from TObject) as Global Var
//-------------------------------------------------------------
function  TNameSpaceInfo.RegisterGlobalVar(Name:String;xObj:TObject):integer;
var
 // pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;

  if(xObj = NIL)then Exit;

  //--- Add variant to globals list -------
  try
    //--- Change Global Var if already exists ---
    if(DupGlobals.Find(Name,Idx))then begin
      pV:=TXVariant(DupGlobals.Objects[Idx]);
      pV.Ptr:=Pointer(xObj);
      Result:=Idx;
    end else begin
      //-- Add New global var -------

      //-- Create variant and save pointer to pUserFUncObj in it
      pV:=TXVariant.Create;
      //-- show it is pointer to object. And then we can recognize
      //-- special objects by checking their types
      pV.Ptr:=Pointer(xObj);
      Result:=DupGlobals.AddObject(Name,TObject(pV));
    end;
  except
     //----- Really obsolete --------
     on EStringListError do begin
         S:='Global "'+Name+'"'+CHR(13)+'already registered in NameSpace.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalVar',MB_APPLMODAL);
     end;
  end;

end;



//--------------------------------------------------
// Additional internal functions
//--------------------------------------------------
function GetOpCode(Instruct:LuaInstruction):integer;
begin
   Result:=Instruct AND (NOT $FFFFFFC0);
end;

//--------------------------------------------------
function Get_C_Operand(Instruct:LuaInstruction):integer;
var
  x:Cardinal;
begin
   x:=INSTUCT_BITS-(POS_C+SIZE_C);
   x:=Instruct SHL (x);
   x:=x SHR (INSTUCT_BITS-SIZE_C);
   Result:=x;
end;

//--------------------------------------------------
function Get_B_Operand(Instruct:LuaInstruction):integer;
begin
   Result:=Instruct SHL (INSTUCT_BITS-(POS_B+SIZE_B));
   Result:=Result SHR (INSTUCT_BITS-SIZE_B);
end;

//--------------------------------------------------
function Get_A_Operand(Instruct:LuaInstruction):integer;
begin
   Result:=Instruct SHL (INSTUCT_BITS-(POS_A+SIZE_A));
   Result:=Result SHR (INSTUCT_BITS-SIZE_A);
end;

//--------------------------------------------------
function Get_Bx_Operand(Instruct:LuaInstruction):integer;
begin
   Result:=Instruct SHL (INSTUCT_BITS-(POS_Bx+SIZE_Bx));
   Result:=Result SHR (INSTUCT_BITS-SIZE_Bx);
end;

//--------------------------------------------------
function Get_sBx_Operand(Instruct:LuaInstruction):integer;
begin
   Result:=Get_Bx_Operand(Instruct)-MAXARG_sBx;
end;

//-----------------------------------------------------
// Helper function for assign Variant parts.
//-----------------------------------------------------
procedure AssignFirstVariantToSecond(pV1,pV2:TXVariant);
begin
    pV2.Assign(pV1);
end;

//-----------------------------------------------------
// Small helper for save object reff. in variant
//-----------------------------------------------------
procedure SaveObjInVariant(xObj:TOBject;pV:TXVariant);
begin
   pV.Ptr:=Pointer(xObj);
end;

//_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
//
// ByteCodeProto IMPLEMENTATION
//_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_

//-------------------------------
// ByteCodeProto constructor
//-------------------------------
constructor TByteCodeProto.Create(AOwner:TComponent);
var
 i:integer;
begin
  inherited Create;
  NameSpace:=Nil;             //--- Additional obj. usually TForm used for Resolve globals
  ParentProto:=Nil;

//  RegisteredFuncList:=Nil;  //--- For distinguish functions and Global objects - Glob.Functions must be registerd
  //OnHandleGlobals:=Nil;
  //OnDebugHook:=Nil;

  TmpVarsListStack:=TStack.Create;      //--- Saved TmpVarsLists used for CALL/RETURN operations
  TmpVarsList:=Nil;
  //GlobalVarsList:=Nil;   //--- StringList holding Name of Global and TxVariant as Object.
  AddedToGlobals:=Nil;     //--- list for store globals added internally by OP_SETGLOBAL
                           //--- needs for cleanup this values from list on Return

  ConstList:=TList.Create;         //-- Functions constants : List of Variants used by the function
  pCode:=Nil;    //-- pointer to array of function instructions
  //-- Attached TByteCodeProto clases of functions defined inside this function (if any)
  InternalFunctionsList:=TList.Create;
  lineinfo:=Nil;    //-- map from opcodes to source lines (when compiled with Debug option)
  locvars:=Nil;
  upvalues:=Nil;
  sizeupvalues:=0;
  sizek:=0;      //-- size of constants
  sizecode:=0;
  sizelineinfo:=0;
  sizep:=0;
  sizelocvars:=0;
  lineDefined:=0;
  gclist:=NIL;
  nups:=0;
  numparams:=0;
  is_vararg:=0;
  maxstacksize:=0;

  MapInfo:=Nil;
  pBinStart:=Nil;    //--- pointer to start of file
  pBin:=Nil;         //--- current pointer
  Loaded:=false;

//  RuntimeObjectCreator:=TRuntimeObjectCreator.Create;

  //--- Register NEW and NULL Globals if not registered yet ------
//  if(NOT GlobalVarsList.Find('NEW',i))then begin
//    RegisterGlobalVar('NEW',RuntimeObjectCreator);
//    RegisterGlobalVar('NIL',NullPtrObject);
//    RegisterGlobalVar('NULL',NullPtrObject);
//  end;

  NewControlsOwner:=AOwner; //--- Must be set by user if "NEW.SomeControl" appears in program


  InternalTablesList:=TList.Create;         //--- List of all TLuaTables created. needs for properly delete all create tables
  //--- Build in user-like function for implement CreateArray internally
  CreateArrayFunc:=TUserFuncObject.CreateWithName('CreateArray',Self.CreateArray);
  DeleteTablesFunc:=TUserFuncObject.CreateWithName('DeleteTables',Self.DeleteTables);
end;

//-------------------------------
// ByteCodeProto destructor
//-------------------------------
destructor TByteCodeProto.Destroy;
var
  i:integer;
  pV:TXVariant;
  S1:String;
  A:integer;
begin

  //---- Delete function Constants by List ---------
  if(ConstList <> Nil)then begin
    for i:=0 to ConstList.Count-1 do begin
       pV:=TXVariant(ConstList.Items[i]);
       pV.Destroy;
    end;
    ConstList.Free;
  end;

  //---- Delete Array of LUA binary Instructions ----------
  if(pCode <> Nil)then begin
     FreeMem(pCode,sizecode*sizeof(integer));
  end;


   //--- Cleanup all globals added on OP_SETGLOBAL operations during function execution ---
   //--- Some global(s) can be saved by call to MODULE.SaveGlobal(...); or MODULE.SaveGlobals();
   if(AddedToGlobals <> Nil)then begin
              for i:=0 to AddedToGlobals.Count-1 do begin
                 S1:=AddedToGlobals.Strings[i];
                 if(GlobalVarsList.Find(S1,A))then begin
                    pV:=TXVariant(GlobalVarsList.Objects[A]);
                    pV.Destroy;
                    GlobalVarsList.Delete(A);
                 end;
              end;
              AddedToGlobals.Free;
              AddedToGlobals:=Nil;
    end;


  //---- Delete Attached Internal functions by List -----------
  if(InternalFunctionsList <> Nil)then begin
    for i:=0 to InternalFunctionsList.Count-1 do begin
      (TByteCodeProto(InternalFunctionsList.Items[i])).Destroy;
    end;
    InternalFunctionsList.Free;
  end;

  if(lineinfo <> Nil)then begin
    FreeMem(lineinfo,sizelineinfo*sizeof(Cardinal));
  end;

  //---- Delete Local Variables -----------
  if(locvars <> Nil)then begin
    for i:=0 to locvars.Count-1 do begin
       (TLocVar(locvars.Items[i])).Destroy;
    end;
    locvars.Free;
  end;

  //--- Del Upvalues stringlist -------
  if(upvalues <> Nil)then begin
     upvalues.Free; //---simply TStringList
  end;

  //--- Close Mapped File if need -------
  if(MapInfo <> Nil)then begin
     CloseMappedFile(MapInfo);
     MapInfo.Free;
     MapInfo:=Nil;
  end;

  //--- Delete List of Temporary variables ----
  if(TmpVarsList <> Nil)then begin
    for i:=0 to TmpVarsList.Count-1 do begin
       pV:=TXVariant(TmpVarsList.Items[i]);
       pV.Destroy;
    end;
    TmpVarsList.Free;
    TmpVarsList:=Nil;
  end;

   //-- Normally - stack must be an empty,but when we stop process during
   //-- execution - we have to cleanup stack of TempLists------
   if(TmpVarsListStack <> Nil)then begin
      //---- Free Lists of Temp vars which are in stack -------
      while(TmpVarsListStack.Count > 0)do begin
            TmpVarsList:=TList(TmpVarsListStack.Pop);
            if(TmpVarsList <> Nil)then begin
              for i:=0 to TmpVarsList.Count-1 do begin
                 pV:=TXVariant(TmpVarsList.Items[i]);
                 pV.Destroy;
              end;
              TmpVarsList.Free;
            end;
      end;
      TmpVarsListStack.Free;
   end;

   //--- Delete all TLuaTables created during code execution -----
   if(InternalTablesList <> Nil)then begin
      for i:=0 to InternalTablesList.Count-1 do begin
         if(InternalTablesList.Items[i] <> Nil)then begin
            TLuaTable(InternalTablesList.Items[i]).Destroy;
         end;
      end;
      InternalTablesList.Destroy;
   end;

  //--- Del class of user-like CreateArray function definition ---
  CreateArrayFunc.Free;
  DeleteTablesFunc.Free;

  inherited Destroy;
end;

//----------------------------------------------------
// ByteCodeProto: Open and load LUA Binary file
// Open File,load it into buffer
//----------------------------------------------------
procedure TByteCodeProto.LoadBinary(FName:String);
begin
  Loaded:=false;
  MapInfo:=TMapFileInfo.Create; //--- alloc record
  MapInfo.FileName:=PChar(FName);
  pBinStart:=OpenAndMapFile(MapInfo);
  if(pBinStart = Nil)then begin
     Exit; //--- probably Invalid file
  end;

  //--- Init Lua Binary file loading (parsing) ---
  pBin:=pBinStart; //-- set pointer to start of file

  LoadHeader;
  LoadFunction;
end;

//-----------------------------------------------
// Load file from bufer with specified pointer
//-----------------------------------------------
procedure TByteCodeProto.LoadBinaryByPtr(pBuf:Pointer);
begin
  Loaded:=false;
  pBinStart:=pBuf;
  pBin:=pBinStart;

  LoadHeader;
  LoadFunction;
end;



//----------------------------------------------------
//ByteCodeProto: Agregate proc for load LUA Binary file
// using buffer content.
//----------------------------------------------------
procedure TByteCodeProto.LoadFunction;
begin
 Loaded:=false;           //--- Not loaded yet.
 Self.source:=LoadStr;
 if(Self.source ='')then begin
   if(ParentProto <> NIL)then begin
      Self.source:='(function of) '+ParentProto.source;
   end;
 end;

 lineDefined:=LoadInt;
 nups:=LoadByte;
 numparams:=LoadByte;
 is_vararg:=LoadByte;
 maxstacksize:=LoadByte;

 //CreateTmpVarsList; //--- list of Variants needs for runtime execution

 LoadSrcLinesInfo;
 LoadLocals;
 LoadUpvalues;
 LoadConstants;
 LoadCode;
 Loaded:=true;     //--- Now - loaded sucessfully
end;

//----------------------------------------------------
// Load one Byte from LUA bin
//----------------------------------------------------
function TByteCodeProto.LoadByte:Byte;
var
  x:Byte;
begin
  LoadBlock(PChar(@x),1);
  Result:=x;
end;

//----------------------------------------------------
// Load Integer from bin
//----------------------------------------------------
function TByteCodeProto.LoadInt:integer;
var
  x:integer;
begin
  LoadBlock(PChar(@x),sizeof(integer));
  Result:=x;
end;

//----------------------------------------------------
// Load Number (number in LUA are 8-byte Reals)
//----------------------------------------------------
function TByteCodeProto.LoadNumber:Lua_Number;
var
  x:Lua_Number;
begin
  LoadBlock(PChar(@x),sizeof(Lua_Number));
  Result:=x;
end;

//----------------------------------------------------
// Copy Block of bytes from Input buffer to specified
//----------------------------------------------------
procedure TByteCodeProto.LoadBlock(Adr:PChar;BlkSize:integer);
var
  i:integer;
begin
   for i:=BlkSize downto 1 do begin
     Adr^:=PChar(pBin)^;
     inc(Adr);
     inc(PChar(pBin));
   end;
end;

//----------------------------------------------------
// ByteCodeProto: Load String from LUA binary
//----------------------------------------------------
function TByteCodeProto.LoadStr:String;
var
 sSize:integer;
begin
  Result:='';
  sSize:=LoadInt;
  //-- If empty string ---
  if(sSize = 0)then begin
    Exit;
  end;
  SetLength(Result,sSize);
  LoadBlock(PChar(Result),sSize);
  SetLength(Result,sSize-1); //-- delete last "\0" at the end
end;

//----------------------------------------------------
// ByteCodeProto: Load info about src lines (if exists)
//----------------------------------------------------
procedure TByteCodeProto.LoadSrcLinesInfo;     //-- Load part of binary file
var
  size:integer;
begin
 size:=LoadInt;
 sizelineinfo:=size;
 if(size <> 0)then begin
   GetMem(lineinfo,sizelineinfo*sizeof(Cardinal));
   sizelineinfo:=size;
   LoadBlock(PChar(lineinfo),size*sizeof(Cardinal));
 end;
end;

//----------------------------------------------------------
// ByteCodeProto: Load local variables from LUA binary
//----------------------------------------------------------
procedure TByteCodeProto.LoadLocals;    //-- Load part of binary file
var
  i,n:integer;
  LocVar:TLocVar;
begin
 n:=LoadInt;
 sizelocvars:=n;
 if(n = 0)then begin
   Exit;
 end;
 locvars:=TList.Create;
 for i:=0 to n-1 do begin
   LocVar:=TLocVar.Create;
   LocVar.varname:=LoadStr;
   LocVar.startpc:=LoadInt;
   LocVar.endpc:=LoadInt;
   locvars.Add(LocVar);
 end;
end;

//----------------------------------------------------------
// ByteCodeProto: Load UpValues variables from LUA binary
// NOTE: Currently not used.
//----------------------------------------------------------
procedure TByteCodeProto.LoadUpvalues;  //-- Load part of binary file
var
  i,n:integer;
  S:String;
begin
 n:=LoadInt;
 if((n <> 0) AND (n <> nups))then begin
    raise Exception.Create('Load LUA bytecode:Invalid number of Upvalues');
 end;
 upvalues:=TStringList.Create;
 sizeupvalues:=n;
 for i:=0 to n-1 do begin
   S:=LoadStr;
   upvalues.Add(S);
 end;
end;

//----------------------------------------------------------
// ByteCodeProto: Load Constants from LUA binary
//----------------------------------------------------------
procedure TByteCodeProto.LoadConstants; //-- Load part of binary file
var
 i,n:integer;
 constType:Byte;
 pV:TXVariant;
 InternFuncProto:TByteCodeProto;
 xStr:String;
begin
 n:=LoadInt;
 ConstList:=TList.Create;         //-- Functions constants : List of Variants used by the function
 sizek:=n;
 for i:=0 to n-1 do begin
  //-- create new Variant Object and add to list ---
  pV:=TXVariant.Create;
  ConstList.Add(pV);

  //-- Get type of const ---
  ConstType:=LoadByte;

  case ConstType of
   LUA_TNUMBER:
     begin
	pV.V:=LoadNumber;
     end;
   LUA_TSTRING:
     begin
        xStr:=LoadStr;
	pV.V:=xStr;
     end;
   LUA_TNIL:
     begin
   	pV.V:=0;
     end;
   else
     begin
       raise Exception.Create('Load LUA bytecode:unknown type of constant');
     end
   end; //-- case
 end;

 //--- Load other functions if specified ---
 n:=LoadInt; //-- get number of internal functions
 sizep:=n;   //-- save number of internal functions

 if(n = 0)then begin
   Exit;
 end;

 //---- Read all internal functions --------
 InternalFunctionsList:=TList.Create;
 for i:=0 to n-1 do begin
    //--- create new TByteCodeProto object -----
    InternFuncProto:=TByteCodeProto.Create(NewControlsOwner);
    InternFuncProto.ParentProto:=Self; //--- save pointer to This main function
    InternFuncProto.NameSpace:=Self.NameSpace; //--- save pointer to This main function
    InternalFunctionsList.Add(InternFuncProto);
    InternFuncProto.pBinStart:=pBin;
    InternFuncProto.pBin:=pBin;
    InternFuncProto.LoadFunction;
    //--- Update binary code pointer after function loaded -----
    pBin:=InternFuncProto.pBin;
 end;

end;

//----------------------------------------------------------
// ByteCodeProto: Load ByteCode from LUA binary
// instructions are array of unsingnded integers (Cardinal)
//----------------------------------------------------------
procedure TByteCodeProto.LoadCode;      //-- Load part of binary file
var
 Size:integer;
begin
 Size:=LoadInt;
 sizecode:=Size;
 GetMem(pCode,sizecode*sizeof(integer));
 LoadBlock(PChar(pCode),Size*sizeof(integer));
end;


//----------------------------------------------------------
// Check signature in bin file
//----------------------------------------------------------
procedure TByteCodeProto.LoadSignature;
var
 i,SzSignature:integer;
begin
  SzSignature:=Length(LUA_SIGNATURE);
  for i:=1 to SzSignature do begin
    if(PChar(pBin)^ <> LUA_SIGNATURE[i])then begin
       raise Exception.Create('Invalid LUA bytecode signature.');
    end;
    Inc(PChar(pBin)); //-- move pointer
  end;
end;

//----------------------------------------------------------
// ByteCodeProto: Load LUA Bin file header
//----------------------------------------------------------
procedure TByteCodeProto.LoadHeader;
var
  LuaVersion:integer;
  x,tx:Lua_Number;
  xTypeSize:Byte;
begin
 LoadSignature;

 LuaVersion:=LoadByte;

 if(LuaVersion <> LUA_VERSION)then begin
    raise Exception.Create('Invalid LUA bytecode version.');
 end;

 swap:=LoadByte; //- need to swap bytes?
 xTypeSize:=LoadByte;
 if(xTypeSize <> sizeof(integer))then begin
    raise Exception.Create('Invalid integer size.');
 end;

 xTypeSize:=LoadByte;
 if(xTypeSize <> sizeof(integer))then begin
    raise Exception.Create('Invalid size_t.');
 end;

 xTypeSize:=LoadByte;
 if(xTypeSize <> sizeof(LuaInstruction))then begin
    raise Exception.Create('Invalid instruction size.');
 end;

 (*
 xTypeSize:=LoadByte;
 //TESTSIZE(SIZE_OP, "OP");

 xTypeSize:=LoadByte;
 //TESTSIZE(SIZE_A, "A");

 xTypeSize:=LoadByte;
 //TESTSIZE(SIZE_B, "B");

 xTypeSize:=LoadByte;
 //TESTSIZE(SIZE_C, "C");

 xTypeSize:=LoadByte;
 //TESTSIZE(sizeof(lua_Number), "number");
 *)

 LoadByte;
 LoadByte;
 LoadByte;
 LoadByte;
 LoadByte;

 //-- Test Double (Real) number saved in binary for check ---
 tx:=TEST_NUMBER;
 x:=LoadNumber;

 if (x <> tx)then begin	      //-- disregard errors in last bits of fraction
    raise Exception.Create('Invalid number type.');
 end;
end;

//------------------------------------------------------------
// Create list of Temporary(local) variables
// handled as Variants.
// This list is base for all operations in runtime execution.
//------------------------------------------------------------
procedure TByteCodeProto.CreateTmpVarsList;
var
 i:integer;
 pV:TXVariant;
begin

 //--- Save current list in stack ---
 if(TmpVarsList <> Nil)then begin
   TmpVarsListStack.Push(TmpVarsList);
 end;

 TmpVarsList:=TList.Create;
 for i:=0 to maxstacksize-1 do begin
   //-- create new Variant Object and add to list ---
   pV:=TXVariant.Create;
   TmpVarsList.Add(pV);
 end;
end;

//-----------------------------------------
// Delete current TmpVarsList and restore
// previous from stack if it is.
//-----------------------------------------
procedure TByteCodeProto.DeleteTmpVarsList;
var
 i:integer;
 pV:TXVariant;
 //xLst:TList;
begin
  //--- Delete List of Temporary variables ----
  if(TmpVarsList <> Nil)then begin
    for i:=0 to TmpVarsList.Count-1 do begin
       pV:=TXVariant(TmpVarsList.Items[i]);
       pV.Destroy;
    end;
    TmpVarsList.Free;
    TmpVarsList:=Nil;

//    xLSt:=TmpVarsList; //-- trick for debugger for not show list while it's free
//    TmpVarsList:=Nil;
//    xLst.Free;
  end;

  //--- Restore previous TMpVarsList from Stack if it is here -------
  if(TmpVarsListStack.Count > 0)then begin
     TmpVarsList:=TList(TmpVarsListStack.Pop);
  end;

end;

//----------------------------------------------------
// ByteCodeProto: Debug/Test function for print loaded
// file listing
//----------------------------------------------------
function  TByteCodeProto.PrintBinary:TStringList; //--- test listing print
var
 Lst:TStringList;
 Instr:LuaInstruction;
 iOp:integer;
 i:integer;
 S:String;
 A,B,C,Bx,sBx:integer; //--- different possible attributes
begin
 Lst:=TStringList.Create;
 Result:=Lst;

 if((pCode = Nil) or (sizecode = 0))then begin
    Exit;
 end;

 for i:=0 to sizecode-1 do begin
   Instr:=pCode^[i];
   iOp:=GetOpCode(Instr);
   S:=OpCodeNames[LUA_OPCODES(iOp)]+' ';

   case OpMode[LUA_OPCODES(iOp)] of
       iABC:
         begin
          A  :=Get_A_Operand(Instr);
          B  :=Get_B_Operand(Instr);
          C  :=Get_C_Operand(Instr);

          S:=S+IntToStr(A)+' ';
          S:=S+IntToStr(B)+' ';
          S:=S+IntToStr(C)+' ';
         end;

       iABx:
         begin
          A  :=Get_A_Operand(Instr);
          Bx :=Get_Bx_Operand(Instr);

          S:=S+IntToStr(A)+' ';
          S:=S+IntToStr(Bx)+' ';
         end;

       iAsBx:
         begin
           A  :=Get_A_Operand(Instr);
           sBx:=Get_sBx_Operand(Instr);
           S:=S+IntToStr(A)+' ';
           S:=S+IntToStr(sBx)+' ';
         end;
   end;
   
   Lst.Add(S);
 end;

end;

//---------------------------------------------------------------------------------------
// Used for Debugger - return symbolic info about specified instruction
// Resulting StringList has symbolic params. First strig - Opcode.
// Other strings - Param Names/Values string and Integer Value as attached TObject
//---------------------------------------------------------------------------------------
function  TByteCodeProto.GetOperationInfo(iPC:integer):TStringList;
var
 Lst:TStringList;
 Instr:LuaInstruction;
 iOp:integer;
 i:integer;
 S:String;
 A,B,C,Bx,sBx:integer; //--- different possible attributes
 pV:TXVariant;
begin
 B:=0;
 C:=0;
 Bx:=0;
 sBx:=0;

 Lst:=TStringList.Create;
 Result:=Lst;

 if((pCode = Nil) or (sizecode = 0))then begin
    Exit;
 end;

   Instr:=pCode^[iPC];
   iOp:=GetOpCode(Instr);
   S:=OpCodeNames[LUA_OPCODES(iOp)];
   Lst.AddObject(S,TObject(iOp)); //-- Add Opcode to output list

   //--- Fill Parameters for this Opcode ------
   case OpMode[LUA_OPCODES(iOp)] of
       iABC:
         begin
          A  :=Get_A_Operand(Instr);
          B  :=Get_B_Operand(Instr);
          C  :=Get_C_Operand(Instr);

          S:='A='+IntToStr(A);
          Lst.AddObject(S,TObject(A)); //-- Add param and value to output list

          S:='B='+IntToStr(B);
          Lst.AddObject(S,TObject(B)); //-- Add param and value to output list

          S:='C='+IntToStr(C);
          Lst.AddObject(S,TObject(C)); //-- Add param and value to output list
         end;

       iABx:
         begin
          A  :=Get_A_Operand(Instr);
          Bx :=Get_Bx_Operand(Instr);

          S:='A='+IntToStr(A);
          Lst.AddObject(S,TObject(A)); //-- Add param and value to output list

          S:='Bx='+IntToStr(Bx);
          Lst.AddObject(S,TObject(Bx)); //-- Add param and value to output list
         end;

       iAsBx:
         begin
           A  :=Get_A_Operand(Instr);
           sBx:=Get_sBx_Operand(Instr);

          S:='A='+IntToStr(A);
          Lst.AddObject(S,TObject(A)); //-- Add param and value to output list

          S:='sBx='+IntToStr(sBx);
          Lst.AddObject(S,TObject(sBx)); //-- Add param and value to output list
         end;
   end;

   //--- Show constants were need so ---------
   case LUA_OPCODES(iOp) of
      OP_LOADK:
        begin
          //--- Get constant ----------
          pV:=TXVariant(ConstList.Items[Bx]);
          Lst.Strings[2]:=Lst.Strings[2]+' "'+String(pV.V)+'"';
        end;
      OP_GETGLOBAL,
      OP_SETGLOBAL:
        begin
          //--- Get constant ----------
          pV:=TXVariant(ConstList.Items[Bx]);
          Lst.Strings[2]:=Lst.Strings[2]+' "'+String(pV.V)+'"';
        end;

      OP_GETTABLE,
      OP_SELF:
        begin
          //--- Get constant ----------
          if(C >= MAX_LUA_STACK)then begin
             pV:=TXVariant(ConstList.Items[C-MAX_LUA_STACK]);
             Lst.Strings[3]:=Lst.Strings[3]+' "'+String(pV.V)+'"';
          end;
        end;

      OP_SETTABLE,
      OP_ADD,
      OP_SUB,
      OP_MUL,
      OP_DIV,
      OP_POW,
      OP_EQ,
      OP_LT,
      OP_LE:
        begin
          //--- Get constant ----------
          if(B >= MAX_LUA_STACK)then begin
             pV:=TXVariant(ConstList.Items[B-MAX_LUA_STACK]);
             Lst.Strings[2]:=Lst.Strings[2]+' "'+String(pV.V)+'"';
          end;
          //--- Get constant ----------
          if(C >= MAX_LUA_STACK)then begin
             pV:=TXVariant(ConstList.Items[C-MAX_LUA_STACK]);
             Lst.Strings[3]:=Lst.Strings[3]+' "'+String(pV.V)+'"';
          end;
        end;

      OP_JMP,
      OP_FORLOOP,
      OP_TFORLOOP:
        begin
            //-- Show New PC address ---
            i:=iPC+sBx+2;
            Lst.Strings[2]:=Lst.Strings[2]+' NewPC='+IntToStr(i);
        end;

      OP_CLOSURE:
        begin
        end;

   end;



end;


//-------------------------------------------------------------
// Register User Global function
//-------------------------------------------------------------
function  TByteCodeProto.RegisterGlobalFunction(FuncName:String;FuncImplementHandler:TLuaExternFunction):integer; //--- register function of some class as LUA global
begin
   Result:=LuaInter.RegisterGlobalFunction(FuncName,FuncImplementHandler); //--- register function of some class as LUA global
end;

(*
var
  pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
  end;

  //--- Create object for discribe User funcion ----
  pUserFuncObj:=TUserFuncObject.Create;
  pUserFuncObj.FunctionImplementation:=FuncImplementHandler;
  pUserFuncObj.FunctionName:=FuncName;

  //-- Create variant and save pointer to pUserFUncObj in it
  pV:=TXVariant.Create;
  pV.Ptr:=Pointer(pUserFUncObj);

  //--- Add variant to globals list -------
  try
    Result:=GlobalVarsList.AddObject(FuncName,TObject(pV));
  except
     on EStringListError do begin
         S:='Function "'+FuncName+'"'+CHR(13)+'already registered as Global.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalFunction',MB_APPLMODAL);
     end;
  end;
end;
*)

//-------------------------------------------------------------
// Register some object (inherited from TObject) as Global Var
//-------------------------------------------------------------
function  TByteCodeProto.RegisterGlobalVar(Name:String;xObj:TObject):integer;
begin
   Result:=LuaInter.RegisterGlobalVar(Name,xObj); //--- register function of some class as LUA global
end;
(*
var
 // pUserFuncObj:TUserFuncObject;
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;
  //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
  if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
  end;

  //-- Create variant and save pointer to pUserFUncObj in it
  pV:=TXVariant.Create;
  //-- show it is pointer to object. And then we can recognize
  //-- special objects by checking their types
  pV.Ptr:=Pointer(xObj);

  //--- Add variant to globals list -------
  try
    //--- Change Global Var if already exists ---
    if(GlobalVarsList.Find(Name,Idx))then begin
      GlobalVarsList.Objects[Idx]:=TObject(pV);
      Result:=Idx;
    end else begin
      //-- Add New global var -------
      Result:=GlobalVarsList.AddObject(Name,TObject(pV));
    end;
  except
     //----- Really obsolete --------
     on EStringListError do begin
         S:='Global "'+Name+'"'+CHR(13)+'already registered.';
         MessageBox(HWND(NIL),PChar(S),'RegisterGlobalVar',MB_APPLMODAL);
     end;
  end;

end;
*)

//----------------------------------------------------------------
// Start to execute bytecode. If OK - ErrLevel=0 returned.
// This method also used as internal function CALL.
// In this case TmpVarsList created externally by Caller and must
// contains function parameters.
//----------------------------------------------------------------
function TByteCodeProto.Execute(var ErrLevel:integer):String;
var
 //ErrTxt:String;
 i:integer;
 //pV:TXVariant;
 AppProcMsgCounter:integer;
 InternFunc:TByteCodeProto;
begin
    Result:='';
    AppProcMsgCounter:=0;

    if(Not Loaded)then begin
       ErrLevel:=-1;
       Result:='CAN''T EXECUTE:NO BINARY LOADED';
       EXIT;
    end;

    //-- Create list of TempVars. if not created yet ---
    //-- Normally when we call this function from another - TmpVarsList will be created before CALL
    //-- and it already contains function parameters
    if(TmpVarsList = Nil)then begin
       CreateTmpVarsList;
    end;

    //--- Local variables list must be already created on LoadBinary ---
    // for i:=0 to TmpVarsList.Count-1 do begin
    //   pV:=PVariant(TmpVarsList.Items[i]);
    //   VarClear(pV^);
    //end;

    //--- Create List for Internal Global Vars. (which initialized by SETGLOBAL operation)
    if(GlobalVarsList = Nil)then begin
      GlobalVarsList:=TStringList.Create;
      GlobalVarsList.Sorted:=true;
      GlobalVarsList.Duplicates:=dupError;
    end;

   //---- Propogate Handlers for Attached Internal functions if any. -----------
   if(InternalFunctionsList <> Nil)then begin
    for i:=0 to InternalFunctionsList.Count-1 do begin
         InternFunc:=TByteCodeProto(InternalFunctionsList.Items[i]);
         InternFunc.NameSpace:=Self.NameSpace;
         InternFunc.ExecutionFinished:=false;
      //with (TByteCodeProto(InternalFunctionsList.Items[i])) do begin
      //   //OnDebugHook:=Self.OnDebugHook;
      //   //OnHandleGlobals:=Self.OnHandleGlobals;
      //end;
    end;
   end;

    PC:=0; //--- Let's start from begin ---
    ExecutionFinished:=false;

    if(Assigned(OnDebugHook))then begin
        //---- DEBUG EXECUTION --------
        //---- Here we check if(Assigned(OnDebugHook)) each time because
        //---- it can be reset during execution from some another form
        while(NOT ExecutionFinished)do begin
          try
            //--- Check OnDebugHook each time because it can be unassigned dynamically --
            if(Assigned(OnDebugHook))then begin
               //---- Call Debug Hook function on each instruction ----
               if(OnDebugHook(Self,'') = 1)then begin
                  Break; //--- If it returns 1 - STOP execution
               end;

               if(AppProcMsgCounter > 1000)then begin
                   AppProcMsgCounter:=0;
                   Application.ProcessMessages;
               end;
            end;
            ExecuteInstruction;

            inc(AppProcMsgCounter);
          except

            on E: Exception do begin
              ErrLevel:=-1;
              Result:=E.Message+CHR(13)+'AT PC='+IntToStr(PC+1);

              //-- Save current TByteCodeProto where error occured ---
              if(ErrorInByteCode = NIL)then begin
                 ErrorInByteCode:=Self;
                 ErrorInPC:=PC+1;
                 ErrorInLine:=GetSrcLineByPC(PC+1);
                 ErrString:=Result;
              end;
              //--- Call On debug Hook with Exception string
              //--- If it Return 1 - Stop, else continue execution
              if((Assigned(OnDebugHook)) and (OnDebugHook(Self,Result) = 1))then begin
                  Exit;
              end;
            end;

          end;//try/except
        end;//while

        //--- Reset Debugger After Finish execution ---
        if(Assigned(OnDebugHook))then begin
           OnDebugHook(NIL,'');
        end;

    end else begin
        //---- NORMAL (NON DEBUG) EXECUTION --------
        while(NOT ExecutionFinished)do begin
          try
            //--- For not call ProcessMessages to many times - do it only each 5000 lua instructs ---
            if(AppProcMsgCounter > 1000)then begin
                AppProcMsgCounter:=0;
                Application.ProcessMessages;
            end;

            ExecuteInstruction;

            inc(AppProcMsgCounter);

          except

            on E: Exception do begin
              ErrLevel:=-1;
              Result:=E.Message+CHR(13)+'AT PC='+IntToStr(PC+1);

              if(Self.source <> '')then begin
                Result:=Result+CHR(13)+'Compiled from:'+CHR(13)+Self.source;
              end;

              //-- Save current TByteCodeProto where error occured ---
              if(ErrorInByteCode = NIL)then begin
                 ErrorInByteCode:=Self;
                 ErrorInPC:=PC+1;
                 ErrString:=Result;
                 ErrorInLine:=GetSrcLineByPC(PC+1);
              end;

              Exit;
            end;

          end;//try/except
        end;//while
    end;
end;

//-----------------------------------------------------------------------------------------------------
// Execute One Instruction fetched by current PC
// Notes:
// 1) about Globals:
//  Here I treat all Globals as "Internal" and "Extenal"
//  Internal - used by LUA e.g. for store Address of functions.
//  CLOSURE
//  SETGLOBAL
//  Extenal - must be handled by User OnHandleGlobals function
//  Normal sequences for extenal globals are:
//  When Get Property:
//    GETGLOBAL - User handler find object by Name (sting const)
//    GETTABLE  - User handler find Property of object by Property Name (sting const)
//  When Set Property:
//   GETGLOBAL - User handler find object by Name (sting const)
//   SETTABLE  - User handler find Property of object by Property Name (sting const)
//
// So here we can't write MyObject=XXX (It is the same as assign pointer to Object to some
// constant XXX value). IF we still write "MyObject=XXX" - NEW internal Global with name "MyObject"
// will be created and since that point External "MyObject" became unacessable.
// But we can write "MyObject.MyProperty=XXX" or "YYY=MyObject.MyProperty"
//-----------------------------------------------------------------------------------------------------
procedure TByteCodeProto.ExecuteInstruction;
label
 lblNextPC;
var
 Instr:LuaInstruction;
 iOpcode:integer;
 i:integer;
 RealNumber:Lua_Number;
 S1:String;
 A,B,C,Bx,sBx:integer; //--- different possible attributes of command
 pV1,pV2,pV3:TXVariant;
 xObj:TObject;
 bFlag:boolean;
begin
   //---- Fetch Instruction ------
   Instr:=pCode^[PC];
   iOpcode:=GetOpCode(Instr);

   //-- Just for safe --
   B:=-1;
   C:=-1;
   Bx:=-1;
   sBx:=-1;

   //--- Fetch Operands needs for this opcode ----
   case OpMode[LUA_OPCODES(iOpcode)] of
       iABC:
         begin
          A  :=Get_A_Operand(Instr);
          B  :=Get_B_Operand(Instr);
          C  :=Get_C_Operand(Instr);
         end;

       iABx:
         begin
          A  :=Get_A_Operand(Instr);
          Bx :=Get_Bx_Operand(Instr);
         end;

       iAsBx:
         begin
           A  :=Get_A_Operand(Instr);
           sBx:=Get_sBx_Operand(Instr);
         end;
   end;

   //---------------------------
   // Interpret Opcode
   //---------------------------
   case LUA_OPCODES(iOpcode) of

    //---------------------------------------
    OP_MOVE:      // A B     R(A) := R(B)
      begin
        //--- Assign one local Value to Another---
        pV1:=TmpVarsList.Items[A];
        pV2:=TmpVarsList.Items[B];
        AssignFirstVariantToSecond(pV2,pV1); //pV1^:=pV2^;
      end;
    //---------------------------------------

    OP_LOADK:     // A Bx    R(A) := Kst(Bx)
      begin
        //--- Get Const ----------
        pV1:=TXVariant(ConstList.Items[Bx]);
        //-- Get Value from Stack --------
        pV2:=TmpVarsList.Items[A];
        //--- Assign const to local Value---
        pV2.V:=pV1.V;
      end;

    //---------------------------------------
    OP_LOADBOOL:  // A B C   R(A) := (Bool)B; if (C) PC++
      begin
         pV1:=GetPtrOfArgument(A);
         pV1.V:=boolean(B);
         if(boolean(C))then begin
            INC(PC);
         end;
      end;

    //---------------------------------------
    OP_LOADNIL:   // A B     R(A) := ... := R(B) := nil
      begin
         for i:=B downto A do begin
            pV1:=TmpVarsList.Items[A];
            //pV1.Clear;
            pV1.V:=0;
         end;
      end;

    //-----------------------------------------------
    // UpValues really used only in local functions
    // and mean Parent local var
    //-----------------------------------------------
    OP_GETUPVAL:  // A B     R(A) := UpValue[B]
      begin
         //--- If it is local function -----
         if(ParentProto <> NIL)then begin
             pV1:=GetPtrOfArgument(A);
             pV2:=ParentProto.GetPtrOfArgument(B);
             AssignFirstVariantToSecond(pV2,pV1); //pV1^:=pV2^;
         end;
      end;

    //---------------------------------------
    OP_GETGLOBAL: // A Bx    R(A) := Gbl[Kst(Bx)]
      begin
        //--- Get Global Name from Consts ----------
        pV1:=TXVariant(ConstList.Items[Bx]);

        //---- Check for internal defined globals ------
        //---- CreateArray(...) implemented internally ---
        if(String(pV1.V) = 'CreateArray')then begin
           pV1:=TmpVarsList.Items[A];
           //-- return pointer to our internal func definintion object ---
           pV1.Ptr:=CreateArrayFunc;
           goto lblNextPC;

        end else if(String(pV1.V) = 'DeleteTables')then begin
           pV1:=TmpVarsList.Items[A];
           //-- return pointer to our internal func definintion object ---
           pV1.Ptr:=DeleteTablesFunc;
           goto lblNextPC;

        end else if(String(pV1.V) = 'MODULE')then begin
           pV1:=TmpVarsList.Items[A];
           //-- return pointer to our current TByteCodeProto ---
           pV1.Ptr:=Self;
           goto lblNextPC;
        end;

        //---- First - try to find in internal NameSpace Duplicate Globals list ---------
        if(NameSpace.DupGlobals.Find(String(pV1.V),i))then begin
            //----------- DEBUG DEBUG --------------
           // if((String(pV1.V) = 'OnAnyLFOParamChanged'))then begin
           //    pV2:=pV1;
           // end;

           //--- If found - take object by index from GlobalVarsList----
           pV2:=TXVariant(NameSpace.DupGlobals.Objects[i]);
           //-- Get Value from Stack --------
           pV1:=TmpVarsList.Items[A];
           //--- Assign value from Global list to Stack Value---
           AssignFirstVariantToSecond(pV2,pV1);
        end else if(NOT GlobalVarsList.Find(String(pV1.V),i))then begin
        //---- First - try to find in internal Globals list ---------
            //--- If not found: Try to call User Handler for resolve external global by it's name ---
            if(Assigned(OnHandleGlobals))then begin
                pV2:=TmpVarsList.Items[A];
                //-- User Handler Must find object by name (in pV1) and
                //-- return it's address into pV2
                OnHandleGlobals(Self,OP_GETGLOBAL,pV1,pV2,Nil);
            end else begin
               S1:='GETBLOBAL:'+String(pV1.V)+CHR(13)+'OnHandleGlobals not assigned';
               raise Exception.Create(S1);
            end;

        end else begin
           //--- If found - take object by index from GlobalVarsList----
           pV2:=TXVariant(GlobalVarsList.Objects[i]);
           //-- Get Value from Stack --------
           pV1:=TmpVarsList.Items[A];
           //--- Assign value from Global list to Stack Value---
           AssignFirstVariantToSecond(pV2,pV1);
           //pV1^:=pV2^;
        end;

      end;

    //---------------------------------------
    //OP_GETTABLE:  // A B C   R(A) := R(B)[RK(C)]
    //  begin
    //    //--- Get Const ----------
    //    pV1:=PVariant(ConstList.Items[Bx]);
    //
    //  end;

    //------------------------------------------------------
    // Assume that SetGlobal always work with
    // Internal Globals resides in GlobalVarsList.
    // All objects set as Globals must be TOBjects
    // for we can check them as if(xxx is TByteCodeProto)
    //------------------------------------------------------
    OP_SETGLOBAL: // A Bx    Gbl[Kst(Bx)] := R(A)
      begin
        //--- Get Global name Const ----------
        pV1:=TXVariant(ConstList.Items[Bx]);

        //--- $VS8SEP2004 handle special globals which declared in Lua as:
        //--- VARNAME=STATIC
        //--- In this case we add variable "VARNAME" not to Globals list but to Namespace globals
        pV3:=TmpVarsList.Items[A];
        if(pV3.Ptr = StaticPseudoObject)then begin
           pV2:=TXVariant.Create;
           i:=NameSpace.DupGlobals.AddObject(String(pV1.V),TObject(pV2));
           goto lblNextPC;
        end else

        //----First Try to find in Namespace Globals list (for STATIC vars) -----
        if(NameSpace.DupGlobals.Find(String(pV1.V),i))then begin
           //--- If found - take object by index ----
           pV2:=TXVariant(NameSpace.DupGlobals.Objects[i]);

        end else

        //---- Try to find in Globals list ---------
        if(NOT GlobalVarsList.Find(String(pV1.V),i))then begin
           //--- Add New Global var to list if not found ----
           pV2:=TXVariant.Create;
           i:=GlobalVarsList.AddObject(String(pV1.V),TObject(pV2));

           //-- save in internal list for clenup this var from Globals on OP_RETURN ---
           if(AddedToGlobals = Nil)then begin
              AddedToGlobals:=TStringList.Create;
           end;
           AddedToGlobals.AddObject(String(pV1.V),TObject(pV2));
        end else begin

           //--- If found - take object by index ----
           pV2:=TXVariant(GlobalVarsList.Objects[i]);

           //-- $VS31MAR2004 if we try to Set func more then once - try to prevent of overloading functions ----
           //-- So duplicate this function in Local list attached to NameSpace object.
           //-- $VS29JUN2004: So is it impossible to have a ref to function saved in global var? Need use global tables with ref to func.
           //-- Also this code can cause an exception because of pV2 can have a refference to dead object.
           try
             if(pV2.IsObject)then begin
               if(TObject(pV2.Ptr) is TByteCodeProto)then begin
                   pV3:=TmpVarsList.Items[A];
                   //-- $VS8sep2004 bug: was "if(pV3.IsObject and (TObject(pV2.Ptr) is TByteCodeProto))then begin"
                   if(pV3.IsObject and (TObject(pV3.Ptr) is TByteCodeProto))then begin
                     //--- Check if this is really the same ByteCode ---
                     if( (TByteCodeProto(pV2.Ptr).sizecode =  TByteCodeProto(pV3.Ptr).sizecode) and
                         (TByteCodeProto(pV2.Ptr).sizek  =  TByteCodeProto(pV3.Ptr).sizek))then begin

                          pV2:=TXVariant.Create;
                          i:=NameSpace.DupGlobals.AddObject(String(pV1.V),TObject(pV2));
                         // raise Exception.Create('Multiple Decalaration of Function:'+String(pV1.V));
                     end;
                  end;
               end;
             end;
           except
             ;;; //--- pV2 can have refference to dead object
           end;

        end;
        //-- Get Value from Stack --------
        pV1:=TmpVarsList.Items[A];
        //--- Assign Stack value to Global list value ---
        AssignFirstVariantToSecond(pV1,pV2);
        //TVarData(pV2^):=TVarData(pV1^);
        //TVarData(pV2^).VType:=TVarData(pV1^).VType;
      end;

    //-----------------------------------------------
    // UpValues really used only in local functions
    // and mean Parent local var
    //-----------------------------------------------
    OP_SETUPVAL:  // A B     UpValue[B] := R(A)
      begin
         //--- If it is local function -----
         if(ParentProto <> NIL)then begin
             pV1:=GetPtrOfArgument(A);
             pV2:=ParentProto.GetPtrOfArgument(B);
             AssignFirstVariantToSecond(pV1,pV2); //pV2:=pV1;
         end;
      end;

    //--------------------------------------- Really this is GetProperty
    OP_GETTABLE:  // A B C   R(A) := R(B)[R(C)]
      begin
        //--- Get Property Name as constant or Local Var ----------
        if(C >= MAX_LUA_STACK)then begin
           pV1:=TXVariant(ConstList.Items[C-MAX_LUA_STACK]);
        end else begin
           pV1:=TmpVarsList.Items[C];
        end;

        //---- Get pointer to Object (must be assigned) --
        pV2:=TmpVarsList.Items[B];
        //--- Local for save Property value
        pV3:=TmpVarsList.Items[A];


        //--- Check for GetProperty operation for OLE (IDispatch) object ----
        if(pV2.VarType = varDispatch)then begin
             //---- GetIDispatchProp(pvObject,pvPropName,pvResult:TxVariant);
             GetIDispatchProp(pV2,pV1,pV3,false);
             goto lblNextPC;
        end;


        //--- Check for LuaTable operation ----
        if((pV2.IsObject) and (TObject(pV2.Ptr) is TLuaTable))then begin
             TLuaTable(pV2.Ptr).GetTableValue(pV1,pV3);
             goto lblNextPC;
        end;

        //----- Check for "B" type is - ptr to object -------------
        if(NOT pV2.IsObject)then begin
           //--- Special:  -----
           //--- Check for Str[xxx] for fetch string element -----
           if( (pV2.VarType = varString) and
               (pV1.VarType = varDouble) )then begin
               pV3.V:=Copy(String(pV2.V),integer(pV1.V),1);
               goto lblNextPC;
           end;

           S1:='GETTABLE. Property:'+String(pV1.V)+CHR(13)+'Invalid Global Object Refference';
           raise Exception.Create(S1);
        end;


        //------ Check for special objects ---------------
        if(TObject(pV2.Ptr) is TRuntimeObjectCreator)then begin //---e.g. NEW.ObjectClassName
            //--- If object Creator - try to create it by ClassName and retur result ---
            xObj:=TRuntimeObjectCreator(pV2.Ptr).CreateNewObj(String(pV1.V),NewControlsOwner);
            SaveObjInVariant(xObj,pV3);
        end else if(TObject(pV2.Ptr) is TLuaPackage)then begin //--- e.g.  sys.MessageBox()
            //--- If Functions Package - find method in package and return it back -------
            xObj:=TLuaPackage(pV2.Ptr).Find(String(pV1.V)); //String(pV1^) is Function Name
            SaveObjInVariant(xObj,pV3);
        end else begin
             //--- Try to handle "Owner" and "Parent" properties
             //--- of component because they not appears as Published properties
             xObj:=TObject(pV2.Ptr);

             //---- For make things easier - we try to handle some specific properties internally ---
             //---- FOr example - Owner and Parent properties for Controls,
             //---- Strings[xxx] for TStrings
             if(CheckForPredefinedProperties(OP_GETTABLE,xObj,pV1,pV3))then begin
                 ;;;
             end else if(xObj is TByteCodeProto)then begin
                 //--------- Get Globals as properties of buildin object "MODULE" --------
                 GetPropFromClassPackage(LUA_OPCODES(iOpcode),pV2,pV1,pV3);
             end else if((xObj is TComponent) and (String(pV1.V) = 'Owner'))then begin
                  SaveObjInVariant(TComponent(xObj).Owner,pV3);
             end else if((xObj is TControl) and (String(pV1.V) = 'Parent'))then begin
                  SaveObjInVariant(TControl(xObj).Parent,pV3);
             end else begin
                //--------- Get property of External Global ----------------
                //--------- Try to call User Handler for resolve weak global ---
                if(Assigned(OnHandleGlobals))then begin
                        //-- For OP_GETTABLE assign property of object to pV3 value
                        //-- pV2:Pointer to object,pV1- property name or index,pV3-Local for save result
                        i:=OnHandleGlobals(Self,LUA_OPCODES(iOpcode),pV2,pV1,pV3);

                        //--- Internal error occured while set property ----
                        if(i = -1)then begin
                            S1:='Internal Error on Property "'+String(pV1.V)+'"';
                            //----- Get Control Name if available ----
                            if(TObject(pV2.Ptr) is TComponent)then begin
                               S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                            end;
                            raise  Exception.Create(S1);
                        end;
                        //--- Property not found because it may be not Published ----
                        if(i = 0)then begin
                            //--- Try to call HandleProperties function from Class Package ----
                            i:=GetPropFromClassPackage(LUA_OPCODES(iOpcode),pV2,pV1,pV3);
                            if(i = 0)then begin
                               S1:='Property:"'+String(pV1.V)+'"'+' Not Found';
                               //----- Get Control Name if available ----
                               if(TObject(pV2.Ptr) is TComponent)then begin
                                 S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                               end;
                               raise  Exception.Create(S1);
                            end else if(i < 0)then begin
                                  S1:='Internal Error on Property "'+String(pV1.V)+'"';
                                  //----- Get Control Name if available ----
                                  if(TObject(pV2.Ptr) is TComponent)then begin
                                     S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                                  end;
                                  raise  Exception.Create(S1);
                            end;
                        end;

                end else begin
                       S1:='SETTABLE:'+String(pV1.V)+CHR(13)+'OnHandleGlobals not assigned';
                       raise Exception.Create(S1);
                end;
             end;
        end;
      end;

    //-----------------------------------------------
    OP_SETTABLE:  // A B C   R(A)[RK(B)] := R(C)
      begin
         //--- Get Property Name as constant or Local Var ----------
         pV1:=GetPtrOfArgument(B);
         //--- Get Obect for set Property in -----
         pV2:=GetPtrOfArgument(A);
         //--- Value for set Property -----
         pV3:=GetPtrOfArgument(C);

        //--- Special:  -----
        //--- Check for Str[xxx]=bbb for assign string element -----
        if((pV2.VarType = varString) and
           (pV1.VarType = varDouble) and
           (pV3.VarType = varString)     )then begin
               S1:=String(pV2.V);
               S1[integer(pV1.V)]:=String(pV3.V)[1];
               pV2.V:=S1;
               goto lblNextPC;
        end;

        //--- Check for GetProperty operation for OLE (IDispatch) object ----
        if(pV2.VarType = varDispatch)then begin
             //---- GetIDispatchProp(pvObject,pvPropName,pvResult:TxVariant);
             GetIDispatchProp(pV2,pV1,pV3,true);
             goto lblNextPC;
        end;

        //--- Check for internal LuaTable operation ----
        if((pV2.IsObject) and (TObject(pV2.Ptr) is TLuaTable))then begin
                 TLuaTable(pV2.Ptr).SetTableValue(pV1,pV3);
                 goto lblNextPC;
        end;

        //--- Check for special case:
        //--- Set properties from table for example
        //---- Xobj:Properties={Left=1;Top=2..}
        if((pV1.VarType = varString) and
           ((String(pV1.V) = 'Properties') or (String(pV1.V) = 'Props')) and
           (pV3.IsObject) and (TObject(pV3.Ptr) is TLuaTable))then begin
               //--- Set multiple properties of object (pV2) from TLuaTable (pV3) ---
               SetPropsFromTable(pV2,pV3);
               goto lblNextPC;
        end;

        //--- Try to set property using User handler or Class Packages -------
        SetPropertyEx(pV1,pV2,pV3);

      end;

    //---------------------------------------------------
    // Appears when {x=1,y=2...} occured in source code
    // create TLuaTable object
    //---------------------------------------
    OP_NEWTABLE:  // A B C   R(A) := {} (size = B,C)
      begin
         pV1:=GetPtrOfArgument(A);
         pV1.Ptr:=TLuaTable.Create(InternalTablesList); //--- size does not matter, it will be grows dynamically ---
      end;

    //---------------------------------------
    // Used before call method of some object e,g
    // MyObj1:MyFunc(1,2,3)
    //---------------------------------------
    OP_SELF:      // A B C   R(A+1) := R(B); R(A) := R(B)[RK(C)] // R(B) is pointer to object
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B); //--- Object which method we going to call
         pV3:=GetPtrOfArgument(C); //--- Method name string
           //--- If first operand not string - Error ---
           if(pV3.VarType <> varString)then begin
                 raise Exception.Create('"Obj:Method()" Method name not string.');
           end;

           //---- COM object stuff -------------
           if(pV2.VarType = varDispatch)then begin
             pV1.V:=pV3.V;                 //--At top of stack - save Method name (constant)
             pV1:=GetPtrOfArgument(A+1); //-- get ptr to next stack element
             //AssignFirstVariantToSecond(pV2,pV1);      //-- save Object Refference at second stack element
             pV1.V:=pV2.V;                //--- set saved pointer to object
             goto lblNextPC;

           end else
           //--- If B operand not object refference -- error -----------
           if(NOT pV2.IsObject)then begin
                 raise Exception.Create('"Obj:Method()" Invalid object refference.');
           end;
           //-- Because "A" can be equeal to "B" - save pointer to Object --
           xObj:=pV2.Ptr;

           pV1.V:=pV3.V;                 //--At top of stack - save Method name (constant)
           pV1:=GetPtrOfArgument(A+1); //-- get ptr to next stack element
           //AssignFirstVariantToSecond(pV2,pV1);      //-- save Object Refference at second stack element
           pV1.Ptr:=xObj;              //--- set saved pointer to object
      end;

    //---------------------------------------
    OP_ADD:       // A B C   R(A) := RK(B) + RK(C)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         try
           //--- If first operand is string - do string concatination ---
           if(pV2.VarType = varString)then begin
              pV1.V:=String(pV2.V)+String(pV3.V);
           end else begin
              //--- Else - arithm addition -----
              pV1.V:=pV2.V+pV3.V;
           end;
         except
           raise Exception.Create('"+" Operation is Invalid for argument.');
         end;

      end;

    //---------------------------------------
    OP_SUB:       // A B C   R(A) := RK(B) - RK(C)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         try
           pV1.V:=pV2.V-pV3.V; //-- Arithmetical substraction (can't applay for Strings)
         except
           raise Exception.Create('Substraction (-) Operation is Invalid for argument.');
         end;
      end;

    //---------------------------------------
    OP_MUL:       // A B C   R(A) := RK(B) * RK(C)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         try
           pV1.V:=pV2.V*pV3.V;
         except
           raise Exception.Create('"*" Operation is Invalid for argument.');
         end;
       end;

    //---------------------------------------
    OP_DIV:       // A B C   R(A) := RK(B) / RK(C)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         try
           pV1.V:=pV2.V/pV3.V;
         except
           raise Exception.Create('"/" Operation is Invalid for argument.');
         end;
      end;

    //---------------------------------------
    OP_POW:       // A B C   R(A) := RK(B) ^ RK(C)
      begin
        raise Exception.Create('OP_POW not implemented.');
      end;

    //---------------------------------------
    OP_UNM:       // A B     R(A) := -R(B)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         try
           pV1.V:=-1*pV2.V;
         except
           raise Exception.Create('Unary minus (-) Operation is Invalid for argument.');
         end;
      end;

    //---------------------------------------
    OP_NOT:       // A B     R(A) := not R(B)
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);
         try
           pV1.V:=NOT integer(pV2.V);
         except
           raise Exception.Create('"NOT" Operation is Invalid for argument.');
         end;
      end;

    //---------------------------------------
    OP_CONCAT:    // A B C   R(A) := R(B).. ... ..R(C)
      begin
        raise Exception.Create('OP_CONCAT not implemented.');
         // ????
      end;

    //---------------------------------------
    OP_JMP:       // sBx     PC += sBx
      begin
         INC(PC,sBx);
      end;

    //---------------------------------------
    OP_EQ:        // A B C   if ((RK(B) == RK(C)) ~= A) then pc++
      begin
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         i:=0;
         if(pV2.IsObject or pV3.IsObject)then begin
           if(pV2.Ptr = pV3.Ptr)then begin
             i:=1;
           end;
         end else if((pV2.VarType = pV3.VarType) and (pV2.V = pV3.V))then begin
           i:=1;
         end;

         if(i <> A)then begin
            INC(PC); //-- skip next instruction
         end;

      end;

    //---------------------------------------
    OP_LT:        // A B C   if ((RK(B) <  RK(C)) ~= A) then pc++
      begin
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         i:=0;
         if(pV2.V < pV3.V)then begin
           i:=1;
         end;

         if(i <> A)then begin
            INC(PC); //-- skip next instruction
         end;

      end;

    //---------------------------------------
    OP_LE:        // A B C   if ((RK(B) <= RK(C)) ~= A) then pc++
      begin
         pV2:=GetPtrOfArgument(B);
         pV3:=GetPtrOfArgument(C);
         i:=0;
         if(pV2.V <= pV3.V)then begin
           i:=1;
         end;

         if(i <> A)then begin
            INC(PC); //-- skip next instruction
         end;

      end;

    //---------------------------------------
    OP_TEST:      // A B C   if (R(B) <=> C) then R(A) := R(B) else pc++
      begin
         pV1:=GetPtrOfArgument(A);
         pV2:=GetPtrOfArgument(B);

         i:=1;
         if(boolean(pV2.V))then begin
           i:=0;
         end;
         if(i = C)then begin
           INC(PC);
         end else begin
           pV1.V:=pV2.V;
         end;

      end;

    //---------------------------------------
    OP_CALL:      // A B C   R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
      begin
         //--- Stack frame starts from index="A". "B-1"-Count of params in stack.
         //--- Stack contains: "A"-Address of function,Elements:"A"+1... - function params.
         //--- Function results must be returned into elements from A to "A+C-2" element.

         //---(A) Can be a String for Self-calls Obj:Method(...)
         //--- Or Object of one of known types -------
         pV1:=GetPtrOfArgument(A); //-- get function Object

         if(pV1.VarType = varString)then begin
            pV2:=GetPtrOfArgument(A+1); //-- get Object which method we going to call

            //-- Standard object call ----
            if(pV2.IsObject)then begin
                //---- Try to Call to Function of object e.g.  MyObj:MyFunction(1,2,3) -----
                xObj:=TObject(pV2.Ptr);
               CallFunctionOfObject(xObj,A,B,C);
            end else if(pV2.VarType = varDispatch)then begin
               //-- OLE object call ----
               CallFunctionOfObject(pV2,A,B,C);
            end else begin
               S1:='Invalid Object ref. in Obj:'+String(pV1.V)+'(...) Call';
               S1:=S1+CHR(13)+'This type of Call can be applayed only for locals!';
               raise Exception.Create(S1);
            end;
         end else begin
             //---- Other type of calls -----------------------
             //---- (A) must be an Object refference.
             if(NOT pV1.IsObject)then begin
               raise Exception.Create('Call to unknown Function.');
             end;

             xObj:=TObject(pV1.Ptr);

             //---- Call to Lua internal function -----
             if(xObj is TByteCodeProto)then begin
                  CallLuaFunction(TByteCodeProto(xObj),A,B,C);
             //---- Call to User registered Global function -----
             end else if(xObj is TUserFuncObject)then begin
                  CallUserGlobalFunction(TUserFuncObject(xObj),A,B,C);
             end;

             //pV2:=GetPtrOfArgument(B);
         end;

      end;

    //---------------------------------------
    OP_TAILCALL:  // A B C   return R(A)(R(A+1), ... ,R(A+B-1))
      begin
        raise Exception.Create('OP_TAILCALL not implemented.');
      end;

    //---------------------------------------
    OP_RETURN:    // A B     return R(A), ... ,R(A+B-2)	(see note)
      begin
         //DeleteTmpVarsList; //--- list must be deleted by caller!!!
         //--- Return from main function - Stop execution ----
         //if((ParentProto = NIL) and (TmpVarsListStack.Count = 0))then begin
         //    ExecutionFinished:=true;
         //    Exit;
         //end;
         if(A > 0)then begin //--- if our return params not at top of stack
           B:=B-2; //--- Move B parameters from A to Top of locals
           for i:=0 to B do begin
             pV1:=TmpVarsList.Items[i];
             pV2:=TmpVarsList.Items[A+i];
             AssignFirstVariantToSecond(pV2,pV1); //pV1^:=pV2^;
           end;
         end;

         (*
         //--- Cleanup all globals added on OP_SETGLOBAL operations during function execution ---
         //--- Now - move this cleanup to ByteCodeProto Destructor
         if(AddedToGlobals <> Nil)then begin
              for i:=0 to AddedToGlobals.Count-1 do begin
                 S1:=AddedToGlobals.Strings[i];
                 if(GlobalVarsList.Find(S1,A))then begin
                    pV1:=TXVariant(GlobalVarsList.Objects[A]);
                    pV1.Destroy;
                    GlobalVarsList.Delete(A);
                 end;
              end;
              AddedToGlobals.Free;
              AddedToGlobals:=Nil;
         end;
         *)

         //--- Check if all tables references in table list are NIL - then clear list itself ---
         bFlag:=true;
         if((InternalTablesList <> NIL) and (InternalTablesList.Count > 0))then begin
            for i:=0 to InternalTablesList.Count-1 do begin
               if(InternalTablesList.Items[i] <> Nil)then begin
                   bFlag:=false; //-- If there are not NILL table references - nothing to do
                   Break;
               end;
            end;
            if(bFlag)then begin
               InternalTablesList.Clear;
            end;
         end;


         ExecutionFinished:=true;
         Exit;
      end;

    //---------------------------------------
    OP_FORLOOP:   // A sBx   R(A)+=R(A+2); if R(A) <?= R(A+1) then PC+= sBx
      begin
         pV1:=GetPtrOfArgument(A);   //--- cycle counter
         pV2:=GetPtrOfArgument(A+1); //--- cycle limit
         pV3:=GetPtrOfArgument(A+2); //--- cycle step
         RealNumber:=Lua_Number(pV1.V)+Lua_Number(pV3.V); //--- calc new value after step
         //--- Test if new counter value exceed limit -----------
         if(  ( (Lua_Number(pV3.V) > 0) and (RealNumber <= Lua_Number(pV2.V)) ) or
              ( (Lua_Number(pV3.V) < 0) and (RealNumber >= Lua_Number(pV2.V)) ))then begin

              //-- set new counter value ---
              pV1.V:=RealNumber;
              //---- and jump back ---
              INC(PC,sBx);
         end;

      end;

    //---------------------------------------
    OP_TFORLOOP:  // A C     R(A+2), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                  //         if R(A+2) ~= nil then pc++
      begin
        raise Exception.Create('OP_TFORLOOP not implemented.');
      end;

    //---------------------------------------
    OP_TFORPREP:  // A sBx   if type(R(A)) == table then R(A+1):=R(A), R(A):=next;
                  //         PC += sBx
      begin

      end;

    //---------------------------------------
    // set values to LuaTable
    //---------------------------------------
    OP_SETLIST:   // A Bx    R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= Bx%FPF+1
      begin
         pV1:=GetPtrOfArgument(A);   //--- Must be a table
         if( (NOT pV1.IsObject) or NOT (TObject(pV1.Ptr) is TLuaTable))then begin
            raise Exception.Create('Set List operation applayed not to Table.');
         end;

         pV3:=TXVariant.Create;

         //-- $VS6JUL2004 bug fix for number of elements.
         //-- When long table inited - LOADK..SETLIST appears few times for the same table.
         //-- In this case "Bx" is number of max table index for load.
         C:=Bx mod 32; //--- number of consts goes as 32 consts max 

         for i:=1 to (C+1) do begin
            pV2:=GetPtrOfArgument(A+i);   //--- Get Value from stack
            //--- Set index as Lua_Number variant (real) ----
            RealNumber:=Bx-C+i;
            pV3.V:=RealNumber;
            TLuaTable(pV1.Ptr).SetTableValue(pV3,pV2); //-- Set it on table
         end;
         pV3.Destroy;
      end;

    //---------------------------------------
    OP_SETLISTO:  // A Bx
      begin
        raise Exception.Create('OP_SETLISTTO not implemented.');
      end;

    //---------------------------------------
    OP_CLOSE:     // A       close all variables in the stack up to (>=) R(A)
      begin
        raise Exception.Create('OP_CLOSE not implemented.');
      end;

    //---------------------------------------
    OP_CLOSURE:    // A Bx    R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))	*/
      begin
         pV1:=TmpVarsList.Items[A];
         //pV1^:=integer(InternalFunctionsList.Items[Bx]); //-- Use IUnknown because Delphi Variant can't assign Pointers
         pV1.Ptr:=Pointer(InternalFunctionsList.Items[Bx]); //-- Use IUnknown because Delphi Variant can't assign Pointers
                                                           //--- Later we can check if this pointer is TByteCodeProto - then it is internal function
      end;

    //---------------------------------------
   end;

lblNextPC:

   //-- Increment Program Counter ------
   INC(PC);

end;


//----------------------------------------------------------
// Return pointer to argument depending on
// it's value. If value > MAX_LUA_STACK - ptr to constant
// will returned, else Ptr to Local (temp) var.
//----------------------------------------------------------
function TByteCodeProto.GetPtrOfArgument(I:integer):TXVariant;
begin
        //--- Get Property Name as constant or Local Var ----------
        if(I >= MAX_LUA_STACK)then begin
           Result:=TXVariant(ConstList.Items[I-MAX_LUA_STACK]);
        end else begin
           Result:=TXVariant(TmpVarsList.Items[I]);
        end;
end;

//----------------------------------------------------------------
// Perform Lua internal function call
// remember,that functions can be called recursivelly!
//----------------------------------------------------------------
function TByteCodeProto.CallLuaFunction(xLuaFunction:TByteCodeProto;A,B,C:integer):integer;
var
 Err:integer;
 pV1,pV2:TXVariant;
 ErrStr:String;
 i:integer;
begin
  //--- Create New Set of Locals in callable function and save previous (if it was) in Stack
  xLuaFunction.CreateTmpVarsList;

  //--- Transmit parameters --------
  B:=B-1; //--- params counter
  for i:=0 to B-1 do begin
     pV1:=GetPtrOfArgument(A+i+1); //-- get function Object
     pV2:=xLuaFunction.GetPtrOfArgument(i);
     AssignFirstVariantToSecond(pV1,pV2);
  end;

  //--- DO Call --------
  Err:=0;
  ErrStr:=xLuaFunction.Execute(Err);

  if(ErrStr <> '')then begin
     raise Exception.Create('Error in Function:'+ErrStr);
  end;

  //--- Return parameters --------
  C:=C-2; //---return params counter
  for i:=0 to C do begin
     pV1:=GetPtrOfArgument(A+i); //-- get function Object
     pV2:=xLuaFunction.GetPtrOfArgument(i);
     AssignFirstVariantToSecond(pV2,pV1);
  end;

  //--- Delete New Set of Locals in callable function and restore previous (if it was) frpm Stack
  xLuaFunction.DeleteTmpVarsList;
  Result:=0;
end;

//----------------------------------------------------------------------------------
// Perform Call to User registered Global function
//--- Stack frame starts from index="A". "B-1"-Count of params in stack.
//--- Stack contains: "A"-Address of function,Elements:"A"+1... - function params.
// Function results must be returned into elements from A to "A+C-2" element.
// Callable function must direcly set result value(s) by pointers in param list.
//----------------------------------------------------------------------------------
function TByteCodeProto.CallUserGlobalFunction(xObj:TUserFuncObject;A,B,C:integer):integer;
var
 ParametrsList:TList;
 pV1,pV2:TXVariant;
 i:integer;
begin
  Result:=0;
  //-- Create list of parmaters from stack -------
  ParametrsList:=TList.Create;
  B:=B-1; //--- params counter
  for i:=1 to B do begin
     //--- Get parameter and move it up one position (A+1->A etc.) for user function
     //--- can return result at valid positions
     pV1:=GetPtrOfArgument(A+i);
     pV2:=GetPtrOfArgument(A+i-1);
     AssignFirstVariantToSecond(pV1,pV2);
     ParametrsList.Add(pV2); //--- valid
  end;

  if(B = 0)then begin
     pV1:=GetPtrOfArgument(A);
     ParametrsList.Add(pV1); //--- valid
  end;
 // ParametrsList.Clear;
 // ParametrsList.Free;
 // Exit;

  //--- Call user function
  try
     xObj.FunctionImplementation(ParametrsList); //-- on exit ParmList can contain result(s)
  except
     ParametrsList.Free;
     raise Exception.Create('Error in Global User Function:'+xObj.FunctionName);
  end;
  ParametrsList.Clear;
  ParametrsList.Free;

end;

//----------------------------------------------------------------------------
// Try to Call to Function of object e.g.  MyObj:MyFunction(1,2,3)
// (A) - Method name
// (A+1) and xObje - Object ref. which method we gona Call
// (A+2)...(A+N) - function params.
// (B) - count of params +2
// (C) - count of return values
// Function Result(s):
// If function must return something
// it must directly set result value(s) by pointers in param list.
//----------------------------------------------------------------------------
function TByteCodeProto.CallFunctionOfObject(xObj:TObject;A,B,C:integer):integer;
label
 lblPackageFound;
var
 ParamList:TList;
 pV1,pV2:TXVariant;
 i:integer;
 FuncObj:TUserFuncObject;
 //ObjClassName:String;
 S1,PackageName:String;
 //xPackageObj:TObject;
 ParentClass:TClass;
 xTbl:TLuaTable;
 xTblFunc:TByteCodeProto;

 OleCallActive:boolean;
 varOleMethodName:TXVariant;
begin
  Result:=0;
  pV1:=GetPtrOfArgument(A); //-- get Method name
  S1:=String(pV1.V);        //-- save Method name as String

  varOleMethodName:=Nil;

  //---- Another stuff call method from lua table:
  //---- for example:
  //   MyTbl={a=1,b=2,Method1=MyFunc1}
  //   MyTbl:Method1(); Must call function and set first param as Table itself MyFunc1(MyTbl)
  if(xObj is TLuaTable)then begin
     xTbl:=TLuaTable(xObj);
     if(xTbl.DictList <> Nil)then begin
        i:=xTbl.DictList.IndexOf(S1);
        if(i >=0)then begin
           pV1:=TXVariant(xTbl.DictList.Objects[i]);
           //---- If found element is Function - then OK---
           if(pV1.isObject and (TObject(pV1.Ptr) is TByteCodeProto))then begin
              xTblFunc:=TByteCodeProto(pV1.Ptr);
              pV1:=GetPtrOfArgument(A); //-- get stack element with function name
              pV1.Ptr:=xTblFunc;        //-- and place pointer to Lua function here
              Result:=CallLuaFunction(xTblFunc,A,B,C);
              Exit;
           end;
        end;
     end;
  end;

  //----- If OLE Object's Method call ----------
  if((xObj is TXVariant) and (TXVariant(xObj).VarType = varDispatch))then begin
     PackageName:='_COM';
     ParentClass:=NIL;
     varOleMethodName:=TXVariant.Create;
     varOleMethodName.V:=S1; //--- save Ole Method name as parameter
     S1:='OleCall';         //--- Substitute Method name for "OleCall" method from package "_COM"
     OleCallActive:=true;
  end else begin
     OleCallActive:=false;
     ParentClass:=xObj.ClassType; //-- get our TClass
     PackageName:=xObj.ClassName; //-- get our Class name
  end;

  //-- Try to find class name in globals list ----------
  if(NOT GlobalVarsList.Find(PackageName,i))then begin
      //-- If not found Try to find parent class name in globals list --
      ParentClass:=xObj.ClassParent;
      while(ParentClass <> NIL)do begin
          PackageName:=ParentClass.ClassName;
          if(GlobalVarsList.Find(PackageName,i))then begin
             goto lblPackageFound;
          end;
          ParentClass:=ParentClass.ClassParent;
      end;
      S1:='Class Package :'+xObj.ClassName+' Not registered in Globals';
      raise Exception.Create(S1);
  end;

lblPackageFound:

   //-_-_-
   if(NOT FindMethodWithInheritance(ParentClass,i,S1,FuncObj))then begin
      raise Exception.Create(S1);
   end;
   //-_-_-

  //--- PREPARE TO CALL CLASS PACKAGE FUNCTION -------
  //-- Create list of parmaters from stack -------
  ParamList:=TList.Create;

  //--- Add Parameters ---------
  //--- First parameter is Object (self),other - method parameters ---
  B:=B-1;
  for i:=1 to B do begin
     //--- Get parameter and move it up one position (A+1->A etc.) for user function
     //--- can return result at valid positions
     pV1:=GetPtrOfArgument(A+i);
     pV2:=GetPtrOfArgument(A+i-1);
     AssignFirstVariantToSecond(pV1,pV2);
     ParamList.Add(pV2);
  end;

  //--- Add method name as first parameter ----
  if(OleCallActive)then begin
     FuncObj.FunctionName:='OLE:'+varOleMethodName.V; //-- for valid report in case of errors
     ParamList.Insert(0,varOleMethodName); //-- add name as first parameter
  end;

  //--- Call user function
  try
     FuncObj.FunctionImplementation(ParamList); //-- on exit ParmList can contain result(s)
  except
     on E: Exception do begin
       S1:=E.Message; //--- get possible internal error message (especially usefull in case of OLE)
       ParamList.Free;
       if(varOleMethodName <> NIL)then begin
          varOleMethodName.Free;
       end;
     raise Exception.Create('Error in Function:'+xObj.ClassName+':'+FuncObj.FunctionName+' '+S1);
     end;
  end;
  ParamList.Free;

  if(varOleMethodName <> NIL)then begin
     varOleMethodName.Free;
  end;

end;

//---------------------------------------------------------------------------------------
// Function for find specified method in class package or in class ancestor packages.
// Starting from object in GlobalList with GlobalIdx
// On output:
//   S1 contains error message
//---------------------------------------------------------------------------------------
function TByteCodeProto.FindMethodWithInheritance(ParentClass:TClass;GlobalIdx:integer;var S1:String;var FuncObj:TUserFuncObject):boolean;
var
  pV1:TXVariant;
  xPackageObj:TObject;
  ParentPackageFound:boolean;
  PackageName:String;
begin
   Result:=false;

   //-- Fetch pointer to function object ----
   pV1:=TXVariant(GlobalVarsList.Objects[GlobalIdx]);
   xPackageObj:=TObject(pV1.Ptr);

   //--- Must be of TLuaPackage type --------
   if(Not (xPackageObj is TLuaPackage))then begin
      S1:='Class Package :'+ParentClass.ClassName+' registered in Globals inproperly.';
      Exit;
   end;

   //--- If Functions Package - find method in package and return it back -------
   FuncObj:=TLuaPackage(xPackageObj).Find(S1); //String(pV1^) is Function Name
   if(FuncObj <> Nil)then begin
      Result:=true;
      Exit;
   end;

   ParentPackageFound:=false;
   ParentClass:=ParentClass.ClassParent;
   while(ParentClass <> NIL)do begin
          PackageName:=ParentClass.ClassName;
          if(GlobalVarsList.Find(PackageName,GlobalIdx))then begin
             ParentPackageFound:=true;
             Break;
          end;
          ParentClass:=ParentClass.ClassParent;
   end;

   if(Not ParentPackageFound)then begin
     S1:='Method:'+S1+' not found in Class Package and in class ancestor''s packages.';
     Exit;
   end;

   //-- Call recursive ---------
   Result:=FindMethodWithInheritance(ParentClass,GlobalIdx,S1,FuncObj);

end;

//---------------------------------------------------------------------------------------
// For make things easier - we try to handle some specific properties internally, because
// in some cases such properties can't be get/set generic way.
// For example - Owner and Parent properties for Controls,
// Strings[xxx] for TStrings
// Items[xxx]   for TList e.t.c
// So it is a place for handle all of this specific properties.
//
// For define non published properties of other classes it' woulb be better to
// write "HandleProperties" methods for Class Packages.
//
// Input:
//  PropVar.V is string = Property Name
//  pValue - variable where Property Value must be set/get
//  Operation - OP_GETTABLE - Get property value
//            - OP_SETTABLE - Set property value
//
// Return:true if property was handled by this function
//---------------------------------------------------------------------------------------
function  TByteCodeProto.CheckForPredefinedProperties(Operation:LUA_OPCODES;xObj:TObject;PropVar,pValue:TXVariant):boolean;
var
  i,j:integer;
  v:Lua_Number;
  //S:String;
  b:boolean;
begin
     Result:=false;
     //--------- Do TCommon Dialog Execute Support --------------
     if((xObj is TCommonDialog) and (String(PropVar.V) = 'Execute'))then begin
         b:=false;
         if(xObj is TOpenDialog)then begin
              b:=TOpenDialog(xObj).Execute;
         end else if(xObj is TSaveDialog)then begin
              b:=TSaveDialog(xObj).Execute;
         end else if(xObj is TOpenPictureDialog)then begin
              b:=TOpenPictureDialog(xObj).Execute;
         end else if(xObj is TFontDialog)then begin
              b:=TFontDialog(xObj).Execute;
              //if(b)then begin
              //  pValue.Ptr:=Pointer(TFontDialog(xObj).Font);
              //end else begin
              //  pValue.Ptr:=Pointer(NullPtrObject);
              //end;
         end;

         pValue.V:=b;
         Result:=true;
      //--------- Do TStrings Support --------------
     end else if(xObj is TStrings)then begin
         if(String(PropVar.V) = 'Strings')then begin
            SaveObjInVariant(xObj,pValue);
            Result:=true;
         end else if(String(PropVar.V) = 'Count')then begin
            //----- Get List.Count ----------
            if(Operation = OP_GETTABLE)then begin
              v:=TStrings(xObj).Count;
              pValue.V:=v;
              Result:=true;
            end else begin
              //----- Set List.Count (instead of Delphi)----------
              //------- When Set Count use it for Add,Delete strings ---
              i:=TStrings(xObj).Count;
              j:=integer(pValue.V); //-- new Count specified
              //--- Add new strings ------
              if(j > i)then begin
                 while(j > i)do begin
                    TStrings(xObj).Add('');
                    Inc(i);
                 end;
              end else if(j < i)then begin
                //--- Delete first strings or clear list at all ------
                 if(j = 0)then begin
                   TStrings(xObj).Clear;
                 end else begin
                   while(j < i)do begin
                      TStrings(xObj).Delete(0); //--- delete first lines
                      Inc(j);
                   end;

                 end;
              end;
              Result:=true;
            end;

           //---- Handle List.Strings[nnn] where nnn is numeric ----------
           //---- Here we check for varDouble because all numbers in LUA treated as Double
         end else if(PropVar.VarType = varDouble)then begin
           if(Operation = OP_GETTABLE)then begin
              pValue.V:=String(TStrings(xObj).Strings[integer(PropVar.V)]);
              Result:=true;
           end else begin
              TStrings(xObj).Strings[integer(PropVar.V)]:=String(pValue.V);
              Result:=true;
           end;
         end;


     end else if(xObj is TList)then begin
         //==========Do TList Support ==============
         if(String(PropVar.V) = 'Items')then begin
            SaveObjInVariant(xObj,pValue);
            Result:=true;
         end else if(String(PropVar.V) = 'Count')then begin
            //----- Get List.Count ----------
            if(Operation = OP_GETTABLE)then begin
              v:=TList(xObj).Count;
              pValue.V:=v;
              Result:=true;
            end else begin
              //----- Set List.Count (instead of Delphi)----------
              //------- When Set Count use it for Add,Delete strings ---
              i:=TList(xObj).Count;
              j:=integer(pValue.V); //-- new Count specified
              //--- Add new strings ------
              if(j > i)then begin
                 while(j > i)do begin
                    TList(xObj).Add(Nil);
                    Inc(i);
                 end;
              end else if(j < i)then begin
                //--- Delete first strings or clear list at all ------
                 if(j = 0)then begin
                   TList(xObj).Clear;
                 end else begin
                   while(j < i)do begin
                      TList(xObj).Delete(0); //--- delete first lines
                      Inc(j);
                   end;

                 end;
              end;
              Result:=true;
            end;

           //---- Handle List.Strings[nnn] where nnn is numeric ----------
           //---- Here we check for varDouble because all numbers in LUA treated as Double
         end else if(PropVar.VarType = varDouble)then begin
           if(Operation = OP_GETTABLE)then begin
              pValue.Ptr:=TList(xObj).Items[integer(PropVar.V)];
              Result:=true;
           end else begin
              TList(xObj).Items[integer(PropVar.V)]:=pValue.Ptr;
              Result:=true;
           end;
         end;
     end;


end;

//----------------------------------------------------------------------------------
// Try to use function "HandleProperties" from Class Package if defined
// for Get/Set specified Property
// Input: Operation
// OP_GETTABLE:
// OP_SETTABLE:
// PV1-PV3
//   pV1.Ptr - pointer to object
//   pV2.V   - string containing Property Name to fetch
//   If Operation = OP_SETTABLE:
//   pV3.V    - Property Value for non object properties
//or pV3.Ptr  - If Property is Object - pointer to object
//   As Result If Operation = OP_GETTABLE:
//   pV3.V    - Property Value for non object properties
//or pV3.Ptr  - If Property is Object - pointer to object
// Return Value:
//  1 - OK property handled
//  0 - property not handled
// -1 - Internal error occured.
//----------------------------------------------------------------------------------
function TByteCodeProto.GetPropFromClassPackage(Operation:LUA_OPCODES;pV1,pV2,pV3:TXVariant):integer;
var
 xObj:TObject;
 ParamList:TList;
 FunctionsList:TList;
 i:integer;
 FuncObj:TUserFuncObject;
 xCmd:TXVariant;
begin
  Result:=0;

  xObj:=TObject(pV1.Ptr);
  //---- Get list of all 'HandleProperties' methods for Class Package and
  //---- all its ancestor packages
  FunctionsList:=GetListOfInheritedMethods(xObj,'HandleProperties');
  if(FunctionsList = Nil)then begin
    Exit; //-- no object class package nor it's ancestors packages have HanldeProperties method
  end;

  //--- PREPARE TO CALL CLASS PACKAGE FUNCTION -------
  //-- Create list of parmaters from stack -------
  ParamList:=TList.Create;
  xCmd:=TxVariant.Create;

  if(Operation = OP_GETTABLE)then begin
    xCmd.V:='G';
  end else begin
    xCmd.V:='S';
  end;
  //--- Add Parameters ---------
  ParamList.Add(xCmd); //-- 'G' or 'S' command
  ParamList.Add(pV1);  //-- Pointer to Object
  ParamList.Add(pV2);  //-- Property name
  ParamList.Add(pV3);  //-- I/O Property Value
  try
    for i:=0 to FunctionsList.Count-1 do begin
       FuncObj:=TUserFuncObject(FunctionsList.Items[i]);
       Result:=FuncObj.FunctionImplementation(ParamList); //-- on exit ParmList can contain result(s)
       if(Result = 1)then begin
          break;
       end;
    end;
  except
     Result:=-1;
  end;
  FunctionsList.Free;
  xCmd.Destroy;
  ParamList.Free;

end;



//----------------------------------------------------------------------------------
// Scan all inherited Classes Packages and return list of all finded methods
// with specified MehtodName
// If no methods found - return NIL.
// Otherwice - TList of TUserFuncObject (finded methods)
//----------------------------------------------------------------------------------
function TByteCodeProto.GetListOfInheritedMethods(xObj:TObject;MethodName:String):TList;
var
 xPackageObj:TObject;
 i:integer;
 FuncObj:TUserFuncObject;
 ParentClass:TClass;
 pV1:TXVariant;
 PackageName:String;
begin
  Result:=Nil;

  ParentClass:=xObj.ClassType; //-- get our TClass
  PackageName:=xObj.ClassName; //-- get our Class name

  while(true) do begin
    //-- Try to find class name or it's ancestor calss name in globals list ----------
    if(GlobalVarsList.Find(PackageName,i))then begin
          //-- Fetch pointer to package object ----
          pV1:=TXVariant(GlobalVarsList.Objects[i]);
          xPackageObj:=TObject(pV1.Ptr);
          //--- Must be of TLuaPackage type --------
          if(Not (xPackageObj is TLuaPackage))then begin
                //S1:='Class Package :'+ParentClass.ClassName+' registered in Globals inproperly.';
                Exit;
          end;

          //--- Try to find Function in this Package -------
          FuncObj:=TLuaPackage(xPackageObj).Find(MethodName); //String(pV1^) is Function Name
          if(FuncObj <> Nil)then begin
              //--- If Function Found in this Package add it to Result list -------
              if(Result = Nil)then begin
                   Result:=TList.Create;
              end;
              Result.Add(FuncObj);
          end;
    end;

    //-- Try another parent class name in globals list --
    ParentClass:=ParentClass.ClassParent;
    if(ParentClass = Nil)then begin
         Break;
    end;
    PackageName:=ParentClass.ClassName;

  end;//--- While

end;

//--------------------------------------------------------------------
// Set multiple properties of object (pV2)
// from TLuaTable (pV3)
// Example:
//  MyObject:Properties={Prop1=1;Prop2="xxx"...};
//
// pV2 - Object for set properties to
// pV3 - TLuaTable containing list of PropNames/Values
// NOTE:
//  Table treats as temporary and being deleted after set properties
//---------------------------------------------------------------------
procedure  TByteCodeProto.SetPropsFromTable(pV2,pV3:TXVariant);
var
 Tbl:TLuaTable;
 PropLst:TStringList;
 i:integer;
 PropName:TXVariant;
 PropValue:TXVariant;
begin
  Tbl:=TLuaTable(pV3.Ptr);
  PropLst:=Tbl.sList;
  PropName:=TXVariant.Create;

  for i:=0 to PropLst.Count-1 do begin
    PropName.V:=PropLst.Strings[i]; //--- get property name
    PropValue:=TXVariant(PropLst.Objects[i]);
    SetPropertyEx(PropName,pV2,PropValue);
  end;
  PropName.Free;
  //--- Treat table as temporary and delete it ...
  //--- Delete it from list of created tables ----
  //i:=InternalTablesList.IndexOf(Tbl);

  //--- Because now we know place of table in OwnersList - $VS31MAY2005
  if(InternalTablesList.Items[Tbl.OwnerListIdx] = Tbl)then begin
     InternalTablesList.Items[Tbl.OwnerListIdx]:=NIL; //---- delete list reference to table
  end;
  ///InternalTablesList.Delete(i); //---- it must be in list
  Tbl.Free;
  pV3.Clear;
end;


//--------------------------------------------------------
// Function for analyse data and set property of object
// called from OP_SETTABLE opcode handler
// pV1 - property Name
// pV2 - Object
// pV3 - Value for set Property
//--------------------------------------------------------
procedure TByteCodeProto.SetPropertyEx(pV1,pV2,pV3:TXVariant);
var
  xObj:TObject;
  i:integer;
  S1:String;
begin
        //--------- Try to call User Handler for resolve weak global ---
        if(Assigned(OnHandleGlobals))then begin
                if(NOT pV2.IsObject)then begin
                   S1:='SETTABLE. Property:'+String(pV1.V)+CHR(13)+'Invalid Global Object Refference';
                   raise Exception.Create(S1);
                end;

                //--- Try to handle "Owner" and "Parent" properties
                //--- of component because they not appears as Published properties
                xObj:=TObject(pV2.Ptr);

                if(CheckForPredefinedProperties(OP_SETTABLE,xObj,pV1,pV3))then begin
                    ;;;
                end else if((xObj is TComponent) and (String(pV1.V) = 'Owner'))then begin
                       //TComponent(xObj).Owner:=TObject(TVarData(pV3^).VPointer); // Readonly!
                end else if((xObj is TControl) and (String(pV1.V) = 'Parent'))then begin
                       TControl(xObj).Parent:=TWinControl(pV3.Ptr);
                end else begin
                  //-- Call User Handler:For OP_SETTABLE assign pV3 value to property of object.
                  //--              For OP_GETTABLE assign property of object to pV3 value
                  //-- pV2:Pointer to object,pV1- property name or index,pV3-Local or constant (string or numeric)
                  i:=OnHandleGlobals(Self,OP_SETTABLE,pV2,pV1,pV3);
                  //--- Internal error occured while set property ----
                  if(i = -1)then begin
                      S1:='Internal Error on Property "'+String(pV1.V)+'"';

                      if(TObject(pV2.Ptr) is TComponent)then begin
                         S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                      end;
                      raise  Exception.Create(S1);
                  end;
                  //--- Property not found: it may be not Published ----
                  if(i = 0)then begin
                      //--- Try to call HandleProperties function from Class Package or class ancestors packages ----
                      i:=GetPropFromClassPackage(OP_SETTABLE,pV2,pV1,pV3);
                      if(i = 0)then begin
                          S1:='Property:"'+String(pV1.V)+'"'+' Not Found';

                          if(TObject(pV2.Ptr) is TComponent)then begin
                             S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                          end;
                          raise  Exception.Create(S1);
                      end else if(i < 0)then begin
                            S1:='Internal Error on Property "'+String(pV1.V)+'"';
                            //----- Get Control Name if available ----
                            if(TObject(pV2.Ptr) is TComponent)then begin
                               S1:=S1+' for Component:'+TComponent(PV2.Ptr).Name;
                            end;
                            raise  Exception.Create(S1);
                      end;

                  end;
                end;
        end else begin
               S1:='SETTABLE:'+String(pV1.V)+CHR(13)+'OnHandleGlobals not assigned';
               raise Exception.Create(S1);
        end;
end;

//----------------------------------------------------------------------------------
// Delete all tables currently registered in InternalTablesList
// Normally All tables are deleted on TByteCodeProto destructor.
// But if some function create some temp. tables while it's execution
// used memory will grow each time when function is called.
// For prevent this user can call DeleteTables(); for clear all created tables.
//----------------------------------------------------------------------------------
function TByteCodeProto.DeleteTables(Params:TList):integer;
var
 i:integer;
begin
   if((InternalTablesList <> NIL) and (InternalTablesList.Count > 0))then begin
      for i:=0 to InternalTablesList.Count-1 do begin
         if(InternalTablesList.Items[i] <> Nil)then begin
             TLuaTable(InternalTablesList.Items[i]).Destroy;
         end;
      end;
      InternalTablesList.Clear;
   end;
end;


//-----------------------------------------------------------
// Create multi-dimension table.
// input - numeric dimensions
// Return TLuaTable as first param
//-----------------------------------------------------------
function TByteCodeProto.CreateArray(Params:TList):integer;
var
  Tbl:TLuaTable;
  i:integer;
  idx:integer;
  IndexList:TList;
begin
    Result:=0;

    //-- Check that all params are numeric ------
    for i:=0 to Params.Count-1 do begin
        if(TXVariant(Params.Items[i]).VarType <> varDouble)then begin
           TXVariant(Params.Items[0]).Ptr:=NullPtrObject; //-- return NIL
           Exit; //-- All Params must be numeric !!
        end;
    end;

    //-- Create Tables for all dimensions ------
    IndexList:=TList.Create;
    for i:=0 to Params.Count-1 do begin
        idx:=TXVariant(Params.Items[i]).V;
        IndexList.Add(Pointer(idx));
    end;

    Tbl:=AddTableTo(IndexList,0);
    IndexList.Free;
    TXVariant(Params.Items[0]).Ptr:=Tbl; //-- return first dimension table
    Result:=0;
end;

//----------------------------------------------------------------------
// Create new Lua table(s) recursivelly by specified dimensions
//----------------------------------------------------------------------
function TByteCodeProto.AddTableTo(Indexes:TList;RecursLevel:integer):TLuaTable;
var
 Tbl,NewTbl:TLuaTable;
 i:integer;
 pV:TXVariant;
 Nelements:integer;
begin
    Nelements:=integer(Indexes.Items[RecursLevel]);
    Tbl:=TLuaTable.Create(InternalTablesList);
    Tbl.IndexedList:=TList.Create;
    for i:=0 to Nelements-1 do begin
      pV:=TXVariant.Create;
      Tbl.IndexedList.Add(pV);
      if(RecursLevel < (Indexes.Count-1))then begin
         NewTbl:=AddTableTo(Indexes,RecursLevel+1);
         if(NewTbl <> Nil)then begin
           pV.Ptr:=NewTbl;
         end;
      end;
    end;
    Result:=Tbl;
end;

//----------------------------------------------------------------------
// If Debug info present in ByteCode -
// return SrcLine where runtime error occured
// Else- Return "-1"
// ProgCounter must be 1-based (not 0- based)
//-----------------------------------------------------------------------
function TByteCodeProto.GetSrcLineByPC(ProgCounter:integer):integer;
begin
  Result:=-1;
  if((sizelineinfo = 0) or (ProgCounter > sizelineinfo))then begin
     Exit;
  end;
  //--lineinfo simply contains source line numbers for each PC ---
  Result:=lineinfo^[ProgCounter-1];
  Result:=Result and (not BPT_LINE_FLAG);
end;

//======================================================
// $VS23MAY2005
// Get Property of OLE object.
// Because of we don't know is OLE support currently
// added or not - we does'nt call Ole function directly
// but rather - find "_COM" package in globals list.
//=======================================================
procedure TByteCodeProto.GetIDispatchProp(pvObject,pvPropName,pvResult:TxVariant;SetPropFlag:boolean);
var
  S1:String;
  i:integer;
  ParamList:TList;
  FuncObj:TUserFuncObject;
begin

  //----- If OLE Object's Method call ----------
  if(SetPropFlag)then begin
     S1:='OlePropSet';         //--- Substitute Method name for "OleCall" method from package "_COM"
  end else begin
     S1:='OlePropGet';         //--- Substitute Method name for "OleCall" method from package "_COM"
  end;


  //-- Try to find class name in globals list ----------
  if(NOT GlobalVarsList.Find('_COM',i))then begin
      S1:='Package : _COM Not registered.';
      raise Exception.Create(S1);
  end;

   //-_-_-
   if(NOT FindMethodWithInheritance(Nil,i,S1,FuncObj))then begin
      raise Exception.Create(S1);
   end;
   //-_-_-

  //--- PREPARE TO CALL CLASS PACKAGE FUNCTION -------
  //-- Create list of parmaters from stack -------
  ParamList:=TList.Create;

  if(SetPropFlag)then begin
    ParamList.Add(pvPropName); //-- Just Set property value, ignore result
    ParamList.Add(pvObject);
    ParamList.Add(pvResult);
  end else begin
    pvResult.V:=pvPropName.V; //-- get Property name as first param (the same as name of method).
    ParamList.Add(pvResult);  //-- use it here for return property value to "pvResult"
    ParamList.Add(pvObject);
  end;

  FuncObj.FunctionName:='OLE:'+pvPropName.V; //-- for valid report in case of errors

  //--- Call user function
  try
     FuncObj.FunctionImplementation(ParamList); //-- on exit ParmList can contain result(s)
  except
     on E: Exception do begin
       S1:=E.Message; //--- get possible internal error message (especially usefull in case of OLE)
       ParamList.Free;
     raise Exception.Create('Error in get OLE object property:'+FuncObj.FunctionName+' '+S1);
     end;
  end;
  ParamList.Free;

end;


//------ Functions for set specified Global variable to String value -----------
function SetLuaGlobal(GlobalVarName:String;Value:String):integer;overload;
var
  idx:integer;
begin
   Result:=0;
   if(GlobalVarsList.Find(GlobalVarName,idx))then begin
     TXVariant(GLobalVarsList.Objects[idx]).V:=Value;
     Result:=1; //-- OK
   end;
end;

//------ Function for set specified Global variable to integer -----------
function SetLuaGlobal(GlobalVarname:String;Value:integer):integer;overload;
var
  idx:integer;
  r:Lua_Number;
begin
   Result:=0;
   if(GlobalVarsList.Find(GlobalVarName,idx))then begin
     r:=Value;
     TXVariant(GLobalVarsList.Objects[idx]).V:=r; //--numerics saved as VarDouble
     Result:=1; //-- OK
   end;
end;

//------ Function for set specified Global variable to Real (double) value -----------
function SetLuaGlobal(GlobalVarname:String;Value:real):integer;overload;
var
  idx:integer;
begin
   Result:=0;
   if(GlobalVarsList.Find(GlobalVarName,idx))then begin
     TXVariant(GLobalVarsList.Objects[idx]).V:=Value; //--numerics saved as VarDouble
     Result:=1; //-- OK
   end;
end;

//------ Function for set specified Global variable to Boolean value -----------
function SetLuaGlobal(GlobalVarname:String;Value:boolean):integer;overload;
var
  idx:integer;
begin
   Result:=0;
   if(GlobalVarsList.Find(GlobalVarName,idx))then begin
     TXVariant(GLobalVarsList.Objects[idx]).V:=Value;
     Result:=1; //-- OK
   end;
end;

//------ Function for set specified Global variable as Pointer to Object -----------
function SetLuaGlobal(GlobalVarname:String;Value:TObject):integer;overload;
var
  idx:integer;
begin
   Result:=0;
   if(GlobalVarsList.Find(GlobalVarName,idx))then begin
     TXVariant(GLobalVarsList.Objects[idx]).Ptr:=Value;
     Result:=1; //-- OK
   end;
end;





//===================================================================
initialization

 //--- Create Global Objects accessed from TByteCodeProto class and from other modules ---------
 NullPtrObject:=TXVariant.Create;
 NullPtrObject.Ptr:=Nil;

 //--- Create Overall Globals list : must be sorted!! ---
 GlobalVarsList:=TStringList.Create;
 GlobalVarsList.Sorted:=true;
 GlobalVarsList.Duplicates:=dupIgnore;  //dupError;

 RuntimeObjectCreator:=TRuntimeObjectCreator.Create;
 NewControlsOwner:=Nil;  //--- Used when NEW.SomeControl is created

 StaticPseudoObject:=TStaticGlobal.Create;

 //-- Add Global Values -----
 PiValue:=TXVariant.Create;
 PiValue.V:=PI;
 RegisterGlobalConst('PI',PiValue);
 RegisterGlobalVar('NEW',RuntimeObjectCreator);
 RegisterGlobalVar('NIL',NullPtrObject);
 RegisterGlobalVar('NULL',NullPtrObject);
 RegisterGlobalVar('STATIC',StaticPseudoObject);

 OnHandleGlobals:=Nil;
 OnDebugHook:=Nil;


 //--- Register some well known Objects for being able to create them in Runtime from LUA script ---
 RegisterClass(TButton);
 RegisterClass(TComboBox);
 RegisterClass(TPanel);
 RegisterClass(TEdit);
 //RegisterClass(TList); //-- not TPersistent
 RegisterClass(TStrings);
 RegisterClass(TStringList);
 RegisterClass(TEdit);
 RegisterClass(TMemo);
 RegisterClass(TImage);
 RegisterClass(TApplication);

 //--- Common dialogs ---------
 RegisterClass(TOpenDialog);
 RegisterClass(TSaveDialog);
 RegisterClass(TOpenPictureDialog);
 RegisterClass(TFontDialog);
 RegisterClass(TRuntimeObjectCreator);
end.

