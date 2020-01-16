string 0;

function IsDigit(X);
char X;
begin
    if X = ^0 or
       X = ^1 or
       X = ^2 or
       X = ^3 or
       X = ^4 or
       X = ^5 or
       X = ^6 or
       X = ^7 or
       X = ^8 or
       X = ^9 then return 1
    else
        return 0;
end;

function IToA(Value);
int Value;
char Result(40);
char Ptr;
char Ptr1;
char TmpChar;
int TmpValue;
begin
    Result := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    Ptr := Result;
    Ptr1 := Result;

    loop begin
        TmpValue := Value;
        Value := Value / 10;
        Ptr(0) := Rem(0) + ^0;
        Ptr := Ptr + 1;
        if Value <= 0 then quit;
    end;

    if TmpValue < 0 then begin
        Ptr(0) := ^-;
        Ptr := Ptr + 1;
    end;

    Ptr(0) := 0;
    Ptr := Ptr - 1;

    loop begin
        if Ptr <= Ptr1 then quit;
        TmpChar := Ptr(0);
        Ptr(0) := Ptr1(0);
        Ptr := Ptr - 1;
        Ptr1(0) := TmpChar;
        Ptr1 := Ptr1 + 1;
    end;
    return Result;
end;

ffunction PrintRange;

function AToI(Str);
char Str;
int Value;
int I;
begin
    Value := 0;
    I := 0;

    loop begin
        if Str(I) = 0 then quit;
        if Str(I) < ^0 or Str(I) > ^9 then quit; \ Something is broken here
        Value := Value * 10 + (Str(I) - ^0);
        I := I + 1;
    end;
    return Value;
end;

function SPrintF0(Buffer, Str);
char Buffer;
char Str;
int I;
begin
    I := 0;
    loop begin
        Buffer(I) := Str(I);
        if Str(I) = 0 then quit;
        I := I + 1;
    end;
    return I;
end;

function SPrintF1(Buffer, Fmt, Value);
char Buffer;
char Fmt;
int Value;
int X;
begin
    X := 0;
    case Fmt of
        ^d: begin
            Value := IToA(Value);
            X := SPrintF0(Buffer, Value);
        end;
        ^s:
            X := SPrintF0(Buffer, Value)
        other begin end;
    return X;
end;

procedure PrintRange(Str, RStart, REnd);
char Str;
int RStart, REnd, I;
begin
    Text(0, "Range from ");
    IntOut(0, RStart);
    Text(0, " To ");
    IntOut(0, REnd);
    Text(0, ": ''");
    for I := RStart to REnd do
        ChOut(0, Str(I));
    Text(0, "''");
    CrLf(0);
end;

function StrLen(Str);
char Str;
int Size;
begin
    Size := 0;
    loop begin
        if Str(Size) = 0 then quit;
        Size := Size + 1;
    end;
    return Size + 1;
end;

function StrCpy(Str);
char Str;
char Copy;
int Size;
int I;
begin
    Size := StrLen(Str);
    Copy := MAlloc(Size + 1);
    for I := 0 to Size do
        Copy(I) := Str(I);
    return Copy; 
end;