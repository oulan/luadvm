//-------------------------------------------------------
// Wrapper for Mathematical Routines callable from Lua
//-------------------------------------------------------
unit LuaPackage_Math;
 interface
 uses Windows, Messages, SysUtils,Classes,LuaInter,Math;

 //--------------------------------------------------------------------
 // Pachage Class for collect some general purpose mathematical functions
 //--------------------------------------------------------------------
 type Package_Math=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function pckg_Mod(Params:TList):integer;
    function pckg_Abs(Params:TList):integer;
    function pckg_Exp(Params:TList): Integer;
    function pckg_Ceil(Params:TList):integer;
    function pckg_Floor(Params:TList):integer;
    function pckg_Frac(Params:TList):integer;
    function pckg_Frexp(Params:TList):integer;
    function pckg_Int(Params:TList):integer;
    function pckg_IntPower(Params:TList):integer;
    function pckg_Ldexp(Params:TList):integer;
    function pckg_Ln(Params:TList):integer;
    function pckg_LnXP1(Params:TList):integer;
    function pckg_Log10(Params:TList):integer;
    function pckg_Log2(Params:TList):integer;
    function pckg_LogN(Params:TList):integer;
    function pckg_Max(Params:TList):integer;
    function pckg_TblMax(Params:TList):integer; //-- $VS25MAY2004
    function pckg_Min(Params:TList):integer;
    function pckg_Power(Params:TList):integer;
    function pckg_Round(Params:TList):integer;
    function pckg_Sqr(Params:TList):integer;
    function pckg_Sqrt(Params:TList):integer;
    function pckg_Trunc(Params:TList):integer;
    function pckg_Sin(Params:TList):integer;
    function pckg_Cos(Params:TList):integer;
    function pckg_Tan(Params:TList):integer;
    function pckg_ArcCos(Params:TList):integer;
    function pckg_ArcSin(Params:TList):integer;
    function pckg_ArcTan(Params:TList):integer;
    function pckg_Randomize(Params:TList):integer;
    function pckg_Random(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;

//---------------------------------------------------------
// Global Instances of above Packages-Classes
//---------------------------------------------------------
var
//-- Package Instance (created in Initialization section)
PACK_MATH:Package_Math;


implementation
//---------------------------------------------------------
// Add all functions to internal list
//---------------------------------------------------------
procedure Package_Math.RegisterFunctions;
begin
  Methods.AddObject('Mod',TUserFuncObject.CreateWithName('Mod',pckg_Mod));
  Methods.AddObject('Abs',TUserFuncObject.CreateWithName('Abs',pckg_Abs ));
  Methods.AddObject('Exp',TUserFuncObject.CreateWithName('Exp',pckg_Exp ));
  Methods.AddObject('Ceil',TUserFuncObject.CreateWithName('Ceil',pckg_Ceil ));
  Methods.AddObject('Floor',TUserFuncObject.CreateWithName('Floor',pckg_Floor ));
  Methods.AddObject('Frac',TUserFuncObject.CreateWithName('Frac',pckg_Frac ));
  Methods.AddObject('Frexp',TUserFuncObject.CreateWithName('Frexp',pckg_Frexp ));
  Methods.AddObject('Int',TUserFuncObject.CreateWithName('Int',pckg_Int ));
  Methods.AddObject('IntPower',TUserFuncObject.CreateWithName('IntPower',pckg_IntPower ));
  Methods.AddObject('Ldexp',TUserFuncObject.CreateWithName('Ldexp',pckg_Ldexp ));
  Methods.AddObject('Ln',TUserFuncObject.CreateWithName('Ln',pckg_Ln ));
  Methods.AddObject('LnXP1',TUserFuncObject.CreateWithName('LnXP1',pckg_LnXP1 ));
  Methods.AddObject('Log10',TUserFuncObject.CreateWithName('Log10',pckg_Log10 ));
  Methods.AddObject('Log2',TUserFuncObject.CreateWithName('Log2',pckg_Log2 ));
  Methods.AddObject('LogN',TUserFuncObject.CreateWithName('LogN',pckg_LogN ));
  Methods.AddObject('Max',TUserFuncObject.CreateWithName('Max',pckg_Max ));
  Methods.AddObject('TblMax',TUserFuncObject.CreateWithName('TblMax',pckg_TblMax)); //- $VS25MAY2004
  Methods.AddObject('Min',TUserFuncObject.CreateWithName('Min',pckg_Min ));
  Methods.AddObject('Power',TUserFuncObject.CreateWithName('Power',pckg_Power ));
  Methods.AddObject('Round',TUserFuncObject.CreateWithName('Round',pckg_Round ));
  Methods.AddObject('Sqr',TUserFuncObject.CreateWithName('Sqr',pckg_Sqr ));
  Methods.AddObject('Sqrt',TUserFuncObject.CreateWithName('Sqrt',pckg_Sqrt ));
  Methods.AddObject('Trunc',TUserFuncObject.CreateWithName('Trunc',pckg_Trunc ));
  Methods.AddObject('Sin',TUserFuncObject.CreateWithName('Sin',pckg_Sin ));
  Methods.AddObject('Cos',TUserFuncObject.CreateWithName('Cos',pckg_Cos ));
  Methods.AddObject('Tan',TUserFuncObject.CreateWithName('Tan',pckg_Tan ));
  Methods.AddObject('ArcCos',TUserFuncObject.CreateWithName('ArcCos',pckg_ArcCos ));
  Methods.AddObject('ArcSin',TUserFuncObject.CreateWithName('ArcSin',pckg_ArcSin ));
  Methods.AddObject('ArcTan',TUserFuncObject.CreateWithName('ArcTan',pckg_ArcTan ));
  Methods.AddObject('Randomize',TUserFuncObject.CreateWithName('Randomize',pckg_Randomize));
  Methods.AddObject('Random',TUserFuncObject.CreateWithName('Random',pckg_Random));
end;

//-----------------------------------------------------
// Result=math.Mod(10,3) -- Result=1
// Only Int part of params used
//-----------------------------------------------------
function Package_Math.pckg_Mod(Params:TList):integer;
var
  R1:Integer;
  R2:Integer;
  Res:Lua_Number;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=TXVariant(Params.Items[1]).V;
  Res:=R1 mod R2;
  TXVariant(Params.Items[0]).V:=Res;
end;

//-----------------------------------------------------
// Absolute value of parameter.
//-----------------------------------------------------
function Package_Math.pckg_Abs(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Abs(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Exp(X: Real): Real;
//Exp returns the value of e raised to the power of X, where e is the base of the natural logarithms.
//-----------------------------------------------------
function Package_Math.pckg_Exp(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Exp(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Ceil(X):Integer;
//Call Ceil to obtain the lowest integer greater than
//or equal to X.
//  For example:
//Ceil(-2.8) = -2
//Ceil(2.8) = 3
//Ceil(-1.0) = -1
//-----------------------------------------------------
function Package_Math.pckg_Ceil(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Ceil(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Funciton Floor(X): Integer;
// Call Floor to obtain the highest integer less than or equal to X.
// For example:
// Floor(-2.8) = -3
// Floor(2.8) = 2
// Floor(-1.0) = -1
//-----------------------------------------------------
function Package_Math.pckg_Floor(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Floor(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Frac(X)
//The Frac function returns the fractional part of the argument X.
//The result is the fractional part of X; that is, Frac(X) = X - Int(X).
//-----------------------------------------------------
function Package_Math.pckg_Frac(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Frac(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Calculate Mantissa and Exponent of argument.
// Mantissa,Exponent=Frexp(X);
//-----------------------------------------------------
function Package_Math.pckg_Frexp(Params:TList):integer;
var
  R1:Extended;
  Mantissa:Extended;
  Expon:Integer;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  //Mantissa:=TXVariant(Params.Items[1]).V;
  //Expon:=TXVariant(Params.Items[2]).V;
  Frexp(R1,Mantissa,Expon);
  TXVariant(Params.Items[0]).V:=Mantissa;
  TXVariant(Params.Items[1]).V:=Expon;
end;

//-----------------------------------------------------
// IntPart=Int(X)
// return integer part of X eg.
// ix=Int(10.23424) ix=10.
//-----------------------------------------------------
function Package_Math.pckg_Int(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Int(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// IntPower(Base,Exponent);
// IntPower raises Base to the power specified by Exponent
// Exponent must be integer value.
//-----------------------------------------------------
function Package_Math.pckg_IntPower(Params:TList):integer;
var
  R1:Real;
  R2:Real;
  Expon:integer;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  Expon:=TXVariant(Params.Items[1]).V;
  R2:=IntPower(R1,Expon);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Ldexp(X,P);
//Ldexp returns X times (2 to the power of P).
//"P" argument must be integer
//-------------------------------------------------------
function Package_Math.pckg_Ldexp(Params:TList):integer;
var
  R1:Real;
  R2:Real;
  Expon:integer;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  Expon:=TXVariant(Params.Items[1]).V;
  R2:=Ldexp(R1,Expon);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Ln(X)
// returns the natural logarithm (Ln(e) = 1) of the X.
//-----------------------------------------------------
function Package_Math.pckg_Ln(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Ln(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// LnXP1(X)
// returns the natural logarithm of (X+1).
// Use LnXP1 when X is a value near 0.
//-----------------------------------------------------
function Package_Math.pckg_LnXP1(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=LnXP1(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Log10(X) - deciaml logarithm.
// Log10 returns the log base 10 of X.
//-----------------------------------------------------
function Package_Math.pckg_Log10(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Log10(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Log2(X)
// Log2 returns the log base 2 of X.
//-----------------------------------------------------
function Package_Math.pckg_Log2(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Log2(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// LogN(N,X);
// LogN returns the log base N of X.
//-----------------------------------------------------
function Package_Math.pckg_LogN(Params:TList):integer;
var
  R1:Real;
  R2:Real;
  X:Extended;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  X:=TXVariant(Params.Items[1]).V;
  R2:=LogN(R1,X);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Max(R1,R2);
// Return maximal from R1,R2
//-----------------------------------------------------
function Package_Math.pckg_Max(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=TXVariant(Params.Items[1]).V;
  R2:=Max(R1,R2);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Find Max from Table elements
// eg. local Tbl={10,100,20,30};
// myMax=math.TblMax(Tbl);
// myMax take value of 100
//-----------------------------------------------------
function Package_Math.pckg_TblMax(Params:TList):integer;
label
 lblErr;
var
  xObj:TObject;
  xTbl:TLuaTable;
  R1:Real;
  RMax:Real;
  xLst:TList;
  i:integer;
begin
  Result:=0;
  if(NOT TXVariant(Params.Items[0]).IsObject)then begin
    goto lblErr;
  end;

  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TLuaTable))then begin
       goto lblErr;
  end;

  xTbl:=TLuaTable(xObj);
  xLst:=xTbl.iList;

  if(xLst = Nil)then begin
    TXVariant(Params.Items[0]).V:=0.0;
    Exit;
  end;

  //--- Find Max from list of TxVariants ------
  RMax:=-1e38;   //---- I don't know maxdouble const, so use this one...
  for i:=0 to xLst.Count-1 do begin
      R1:=TxVariant(xLst.Items[i]).V;
      if(R1 > RMax)then begin
         RMax:=R1;
      end;
  end;

  TXVariant(Params.Items[0]).V:=RMax;
  Exit;

//------ err exits --------------
lblErr:
    raise Exception.Create('Function:math.TblMax() Parameter must be a Table!');

end;

//-----------------------------------------------------
// Min(R1,R2);
// return minimal from R1,R2
//-----------------------------------------------------
function Package_Math.pckg_Min(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=TXVariant(Params.Items[1]).V;
  R2:=Min(R1,R2);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
//Power(Base, Exponent)
// Power raises Base to any power. For fractional exponents or exponents greater than MaxInt,
// Base must be greater than 0.
//-----------------------------------------------------
function Package_Math.pckg_Power(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=TXVariant(Params.Items[1]).V;
  R2:=Power(R1,R2);
  TXVariant(Params.Items[0]).V:=R2;
end;

//------------------------------------------------------------------------------------------
//Round(X);
//The Round function rounds value of X to an integer-like value.(witout fractional part).
//Round returns value that is the value of X rounded to the nearest whole number.
//If X is exactly halfway between two whole numbers, the result is always the even number.
//For very large value of X ,a run-time error can be generated.
//------------------------------------------------------------------------------------------
function Package_Math.pckg_Round(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Round(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Sqr(X);
// Returns square of argument X.
//-----------------------------------------------------
function Package_Math.pckg_Sqr(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Sqr(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Sqrt(X);
// Returns square root of argument X.
//-----------------------------------------------------
function Package_Math.pckg_Sqrt(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Sqrt(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Trunc(X);
//The Trunc function truncates X (delete fractal part).
//-----------------------------------------------------
function Package_Math.pckg_Trunc(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Trunc(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Sin(X)
// Calculate Sinus function. X value mesured in radians.
//-----------------------------------------------------
function Package_Math.pckg_Sin(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Sin(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Cos(X)
// Calculate Cosinus function. X value mesured in radians.
//-----------------------------------------------------
function Package_Math.pckg_Cos(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Cos(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Tan(X)
// Calculate Tangent function. X value mesured in radians.
// Tan(X)=Sin(X)/Cos(X)
//-----------------------------------------------------
function Package_Math.pckg_Tan(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=Tan(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// ArcCos(X)
// Return angle value whose Cos func is X.
// So X must be in range of [-1 to 1]
// Returnded Angle mesured in radians (From 0 to PI).
//-----------------------------------------------------
function Package_Math.pckg_ArcCos(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=ArcCos(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// ArcSin(X)
// Return angle value whose Sin func is X.
// So X must be in range of [-1 to 1]
// Returned Angle mesured in radians (From 0 to PI).
//-----------------------------------------------------
function Package_Math.pckg_ArcSin(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=ArcSin(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// ArcTan(X)
// Return angle value whose Tangent func is X.
// So X must be in range of [-1 to 1]
// Returned Angle mesured in radians (From 0 to PI).
//-----------------------------------------------------
function Package_Math.pckg_ArcTan(Params:TList):integer;
var
  R1:Real;
  R2:Real;
begin
  Result:=0;
  R1:=TXVariant(Params.Items[0]).V;
  R2:=ArcTan(R1);
  TXVariant(Params.Items[0]).V:=R2;
end;

//-----------------------------------------------------
// Randomize();
// Initiate random generator with value based on
// current time. Must be called before series of
// Random() functions calls.
//-----------------------------------------------------
function Package_Math.pckg_Randomize(Params:TList):integer;
begin
  Result:=0;
  Randomize;
end;


//----------------------------------------------------------------------
// Get Random value. Before calls of Random
// function, Randomize() can be called for get random
// sequence different each time.
// Form of calls:
// Random()        -- return random value in range 0.0 to 1.0
// Random(Range)   -- return INTEGER Random number in specified range
// Note: Only integer part of Range has meaning.
//----------------------------------------------------------------------
function Package_Math.pckg_Random(Params:TList):integer;
var
  R1:Real;
  iR:integer;
  R2:Real;
begin
  Result:=0;
  if(VarType(TXVariant(Params.Items[0]).V) = varEmpty)then begin
     R2:=Random;
  end else begin
     R1:=TXVariant(Params.Items[0]).V;
     iR:=Trunc(R1);
     R2:=Random(iR);
  end;

  TXVariant(Params.Items[0]).V:=R2;
end;


//=======================================================================
initialization
//--- Create string package -----
PACK_MATH:=Package_Math.Create;
PACK_MATH.RegisterFunctions;

//--- Register this package -----
LuaInter.RegisterGlobalVar('math',PACK_MATH);

end.
