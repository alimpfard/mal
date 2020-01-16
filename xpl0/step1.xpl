include intr.xpl;
include lib.xpl;
include types.xpl;
include reader.xpl;
include printer.xpl;

string 0;
int I;
char Buffer(1024); \// 1K buffer for input

\// read string from stdin
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

\// array of char -> char ??
function XPLRead(Inp);
int Inp;
int Forms;
begin
    Forms := XPLReaderReadStr(Inp);
    if Forms = $00 or XPLMALError # 0 then begin
        Text(0, "Error: ");
        Text(0, XPLMALError);
        CrLf(0);
        XPLMALError := 0; \// Clear exception
        return XPLCreateNil;
    end;
    return Forms;
end;

function XPLPrint(Inp);
int Inp;
begin
    return XPLPrinterPrStr(Inp);
end;

function XPLEval(Inp);
int Inp;
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

begin
    Text(0, "123 = ");
    Text(0, IToA(123));
    CrLf(0);
    XPLRep;
end;