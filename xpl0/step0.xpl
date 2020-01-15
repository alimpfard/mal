include intr.xpl;

string 0;
int I;
char Buffer(512);

\ read string from stdin
procedure JQInput;
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
function JQRead(Inp);
char Inp;
begin
    return Inp;
end;

function JQPrint(Inp);
char Inp;
begin
    return Inp;
end;

function JQEval(Inp);
char Inp;
begin
    return Inp;
end;

procedure JQRep;
begin
    loop begin 
        Text(0, "user> ");
        JQInput;
        if Buffer(0) = 0 then quit;
        Text(0, JQPrint(JQEval(JQRead(Buffer))));
        CrLf(0);
    end;
end;

JQRep;