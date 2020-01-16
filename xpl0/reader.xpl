int TokenPosition;

\// We limit each token to be 512 characters long max
\// We limit the entire token sequence to be at most 1024 tokens long
char Tokens(64, 64);
char Token(64);
int XPLMALError;
int L;

\// We leak __ALL__ the memory

procedure TellPos(From, Too);
int From, Too;
begin
    Text(0, "From ");
    IntOut(0, From);
    Text(0, " To ");
    IntOut(0, Too);
    CrLf(0);
end;

procedure XPLReaderPeek;
begin
    L := 0;
    loop begin
        Token(L) := Tokens(TokenPosition, L);
        if Token(L) = 0 then quit;
        L := L + 1;
    end;
    Token(L) := 0;
    Token(L + 1) := 0;
end;

procedure XPLReaderNext;
begin 
    XPLReaderPeek;
    TokenPosition := TokenPosition + 1;
end;

function XPLReaderTokenize(Str, Pos);
char Str; \// input string
int Pos;  \// position in input string
int IPos;
int StringEscaped;
begin
    \// Read token
    StringEscaped := 0;
    IPos := Pos(0);
    \// TellPos(Pos(0), StrLen(Str));

    if Str(IPos) = 0 then
        return IPos;

    loop begin \// Remove leading spaces...or commas
        case Str(IPos) of
            ^ : Pos(0) := IPos + 1;
            ^,: Pos(0) := IPos + 1
        other quit;
        IPos := Pos(0);
    end;

    \// skip comments
    if Str(IPos) = ^; then
        loop begin
            Pos(0) := IPos; \// update beginning of token
            if Str(IPos) = $0A then quit;
            if Str(IPos) = $00 then quit;
            IPos := IPos + 1;
        end;

    \// ~@
    if Str(IPos) = ^~ and Str(IPos + 1) = ^@ then
        return IPos + 3;

    \// Special chars
    case Str(IPos) of
        ^[:     IPos := IPos + 1;
        ^]:     IPos := IPos + 1;
        ^{:     IPos := IPos + 1;
        ^}:     IPos := IPos + 1;
        ^(:     IPos := IPos + 1;
        ^):     IPos := IPos + 1;
        ^': \' 
                IPos := IPos + 1;    
        ^`:     IPos := IPos + 1;
        ^~:     IPos := IPos + 1;
        ^^:     IPos := IPos + 1;
        ^@:     IPos := IPos + 1
    other begin end;
    
    if IPos # Pos(0) then
        return IPos; \ We have a complete token already
    
    \// Match strings
    if Str(IPos) = ^" then
        loop begin
            IPos := IPos + 1;
            case Str(IPos) of
                ^": 
                    if StringEscaped then
                        StringEscaped := 0
                    else begin
                        IPos := IPos + 1;
                        quit;
                    end;
                ^\:
                    if StringEscaped then
                        StringEscaped := 0
                    else
                        StringEscaped := 1;
                $00:
                    begin
                        XPLMALError := "EOF while reading string";
                        quit; \// EOF while reading string
                    end
            other begin end;
        end;
    
    if IPos # Pos(0) then
        return IPos;

    \// Read other random crap
    loop begin
        case Str(IPos) of
            ^[:     quit;
            ^]:     quit;
            ^{:     quit;
            ^}:     quit;
            ^(:     quit;
            ^):     quit;
            ^': \' 
                    quit;
            ^":     quit;
            ^`:     quit;
            ^~:     quit;
            ^^:     quit;
            ^;:     quit;
            ^ :     quit;
            ^@:     quit;
            $00:    quit
        other IPos := IPos + 1;
    end;

    return IPos;
end;

int XPLReaderReadInto;

ffunction XPLReaderReadForm;

procedure XPLReaderReadList(Ender);
char Ender;
int List;
int ListLast;
int ListLastP;
begin
    \// Eat the opening thingy
    XPLReaderNext;
    \// Prepare a list-y structure
    ListLast := MAlloc(6);
    ListLast(2) := 0;
    ListLast(1) := 0;
    List := XPLReaderReadInto;
    List(1) := ListLast;
    loop begin 
        XPLReaderPeek;

        if Token(0) = Ender then begin 
            XPLReaderNext;
            quit;
        end;

        if Token(0) = $00 then begin
            XPLMALError := "EOF while reading list";
            quit;
        end;

        XPLReaderReadInto := ListLast;
        XPLReaderReadForm;
        
        ListLastP := MAlloc(6);
        ListLastP(2) := 0;
        ListLastP(1) := 0;
        ListLast(2) := ListLastP;
        ListLast := ListLastP;
    end;
    XPLReaderReadInto := List;
end;

procedure XPLReaderReadAtom;
begin
    XPLReaderNext;
    \// Text(0, Token);
    if
        Token(0) = ^t and
        Token(1) = ^r and
        Token(2) = ^u and
        Token(3) = ^e and
        Token(4) = $00 then
            XPLReaderReadInto(0) := TrueKind
    else if
        Token(0) = ^f and
	    Token(1) = ^a and
	    Token(2) = ^l and
	    Token(3) = ^s and
	    Token(4) = ^e and
        Token(5) = $00 then 
            XPLReaderReadInto(0) := FalseKind
    else if 
        Token(0) = ^n and
	    Token(1) = ^i and
	    Token(2) = ^l and
        Token(3) = $00 then
            XPLReaderReadInto(0) := NilKind
    else if
        Token(0) = ^: then begin
            XPLReaderReadInto(0) := KeywordKind;
            XPLReaderReadInto(1) := StrCpy(Token);
        end
    else if 
        Token(0) = ^" then begin
            XPLReaderReadInto(0) := StringKind;
            XPLReaderReadInto(1) := StrCpy(Token);
        end
    else if
        IsDigit(Token(0)) then begin
            XPLReaderReadInto(0) := NumberKind;
            XPLReaderReadInto(1) := AToI(Token);
        end
    else begin
        XPLReaderReadInto(0) := SymbolKind;
        XPLReaderReadInto(1) := StrCpy(Token);
    end;
end;

\// Return a tagged linked list in the form
\// [Next, Data, Kind] -> [...]
\//
\// Numbers,Strings,Symnols,KWs,
\//     True,False and Nil are to be encoded as
\// [Kind, Value, (next)]
\//
\// A list is to be encoded as
\// [ListKind, @Children, (next)]
\//            |
\//            +-> Node -> Node -> ... -> 0
\//
\// Similarly, Hashes are to be encoded as
\// [HashKind, @Children, (next)]
\//            |   +-------------------------------------+
\//            |   v                                     |
\//            +-> [HashElementKind, @Children, (next)  -+]
\//                                  |
\//                                  +-> Node -> Node -> 0
function XPLReaderReadForm;
int Encoded;
begin
    if XPLMALError # $00 then
        return 0; \// bubble the error up

    Encoded := XPLReaderReadInto;
    XPLReaderPeek;
    \// Text(0, "Peeked and saw ''");
    \// ChOut(0, Token(0));
    \// Text(0, "''");
    \// CrLf(0);
    case Token(0) of
        ^(:
            begin
                XPLReaderReadInto(0) := ListKind;
                XPLReaderReadList(^));
            end;
        ^[:
            begin
                XPLReaderReadInto(0) := VectorKind;
                XPLReaderReadList(^]);
            end
    other
        begin
            XPLReaderReadAtom;
        end;
    
    return Encoded;
end;

function XPLCreateNil;
int Val;
begin
    Val := MAlloc(6);
    Val(0) := NilKind;
    return Val;
end;

function XPLReaderReadStr(Str);
char Str;
int Position;
int NextPosition;
int I;
begin
    XPLMALError := 0; \// Clear exception
    Position := 0; \// start at the beginning of string
    NextPosition := XPLReaderTokenize(Str, addr Position);
    \// TellPos(Position, NextPosition);
    TokenPosition := 0; \// Should we do something about this? 
                        \// is this called recursively at all?
    if Position = NextPosition then
        return XPLCreateNil;
    loop begin
        I := 0;
        if Position = NextPosition then quit;
        \// PrintRange(Str, Position, NextPosition - 1);
        loop begin
            if Position = NextPosition then quit;
            Tokens(TokenPosition, I) := Str(Position);
            Position := Position + 1;
            I := I + 1;
        end;
        Tokens(TokenPosition, I) := 0;
        NextPosition := XPLReaderTokenize(Str, addr Position);
        TokenPosition := TokenPosition + 1;
    end;
    Tokens(TokenPosition, 0) := 0; \// Reset the next token to be empty

    TokenPosition := 0;
    XPLReaderReadInto := MAlloc(6);
    return XPLReaderReadForm;
end;