include intr.xpl;

string 0;
int I;
char Buffer(512);

\ read string from stdin
procedure XPLInput;
begin
    I := 0;
    loop begin
        Buffer(I) := ChIn(0);
        if Buffer(I) = $0D then quit;
        I := I + 1;
    end;
    Buffer(I) := 0;
end;

\ array of char -> char ??
function XPLRead(Inp);
char Inp;
begin
    return Inp;
end;

function XPLPrint(Inp);
char Inp;
begin
    return Inp;
end;

function XPLEval(Inp);
char Inp;
begin
    return Inp;
end;

procedure XPLRep;
begin
    loop begin 
        Text(0, "user> ");
        XPLInput;
        if Buffer(0) = 0 then quit;
        Text(0, XPLPrint(XPLEval(XPLRead(Buffer))));
        CrLf(0);
    end;
end;

XPLRep;