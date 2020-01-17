int TokenPosition;

\ We limit each token to be 512 characters long max
\ We limit the entire token sequence to be at most 1024 tokens long
char Tokens(64, 64);
char Token(64);
int XPLMALError;
int L;

\ We leak __ALL__ the memory

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
end;

procedure XPLReaderNext;
begin 
    XPLReaderPeek;
    TokenPosition := TokenPosition + 1;
end;

function XPLReaderTokenize(Str, Pos);
char Str; \ input string
int Pos;  \ position in input string
int IPos; \ End position
int StringEscaped; \ Have we seen a backslash recently?
begin
    \ Read token
    StringEscaped := 0;
    IPos := Pos(0);
    \ TellPos(Pos(0), StrLen(Str));

    if Str(IPos) = 0 then
        return IPos;

    loop begin \ Remove leading spaces...or commas
        case Str(IPos) of
            ^ : Pos(0) := IPos + 1;
            ^,: Pos(0) := IPos + 1
        other quit;
        IPos := Pos(0);
    end;

    \ skip comments
    if Str(IPos) = ^; then
        loop begin
            Pos(0) := IPos; \ update beginning of token
            if Str(IPos) = $0A then quit;
            if Str(IPos) = $00 then quit;
            IPos := IPos + 1;
        end;

    \ ~@
    if Str(IPos) = ^~ and Str(IPos + 1) = ^@ then
        return IPos + 2;

    \ Special chars
    case Str(IPos) of
        ^[:    IPos := IPos + 1;
        ^]:    IPos := IPos + 1;
        ^{:    IPos := IPos + 1;
        ^}:    IPos := IPos + 1;
        ^(:    IPos := IPos + 1;
        ^):    IPos := IPos + 1;
        ^':    IPos := IPos + 1;    
        ^`:    IPos := IPos + 1;
        ^~:    IPos := IPos + 1;
        ^^:    IPos := IPos + 1;
        ^@:    IPos := IPos + 1
    other begin end;
    
    if IPos # Pos(0) then
        return IPos; \ We have a complete token already
    
    \ Match strings
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
                        quit; \ EOF while reading string
                    end
            other begin
                if StringEscaped then
                    StringEscaped := 0;
            end;
        end;
    
    if IPos # Pos(0) then
        return IPos;

    \ Read other random crap
    loop begin
        case Str(IPos) of
            ^[:     quit;
            ^]:     quit;
            ^{:     quit;
            ^}:     quit;
            ^(:     quit;
            ^):     quit;
            ^':     quit;
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

procedure ListAllTokens;
int TP;
int I;
begin
    TP := TokenPosition;
    loop begin
        I := 0;
        if Tokens(TP, 0) = 0 then quit;
        loop begin
            if Tokens(TP, I) = 0 then quit;
            ChOut(0, Tokens(TP, I));
            I := I + 1;
        end;
        CrLf(0);
        TP := TP + 1;
    end;
end;

procedure XPLReaderReadList(Ender);
char Ender;
int List;
int ListLast;
int ListLastP;
begin
    \ Eat the opening thingy
    XPLReaderNext;
    \ Prepare a list-y structure
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
    \ Text(0, Token);
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
            XPLReaderReadInto(1) := ProcessEscapes(Token);
        end
    else if
        IsDigit(Token(0)) or (Token(0) = ^- and IsDigit(Token(1))) then begin
            XPLReaderReadInto(0) := NumberKind;
            XPLReaderReadInto(1) := AToI(Token);
        end
    else begin
        XPLReaderReadInto(0) := SymbolKind;
        XPLReaderReadInto(1) := StrCpy(Token);
    end;
end;

procedure AssertConformingToHash(Node);
int Node;
int Count;
begin
    Count := 0;
    loop begin
        if Node = 0 or Node(0) >= InvalidKind or Node(0) < 0 then quit;
        Count := Count + 1;
        Node := Node(2); \ next
    end;
    if Rem(Count / 2) # 0 then
        XPLMALError := "Expected an even number of items in a hash";
end;

\ Return a tagged linked list in the form
\ [Next, Data, Kind] -> [...]
\
\ Numbers,Strings,Symnols,KWs,
\     True,False and Nil are to be encoded as
\ [Kind, Value, (next)]
\
\ A list is to be encoded as
\ [ListKind, @Children, (next)]
\            |
\            +-> Node -> Node -> ... -> 0
\
\ Similarly, Hashes are to be encoded as lists of alternating keys and values
\ This does have the downside of slowing the hash lookup to O(n), but anything 
\ more sophisticated adds a lot of complexity
function XPLReaderReadForm;
int Encoded;
int NValue, MValue;
begin
    if XPLMALError # $00 then
        return 0; \ bubble the error up

    Encoded := XPLReaderReadInto;
    XPLReaderPeek;
    \ Text(0, "Peeked and saw ''");
    \ ChOut(0, Token(0));
    \ Text(0, "''");
    \ CrLf(0);
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
            end;
        ^{:
            begin
                XPLReaderReadInto(0) := HashKind;
                XPLReaderReadList(^});
                AssertConformingToHash(Encoded(1)); \ Assert that the number of elements in the hash is even
            end;
        \ Special Reader Macros
        ^@:
            begin
                XPLReaderReadInto(0) := ListKind;
                NValue := MAlloc(6);
                XPLReaderReadInto(1) := NValue;
                NValue(0) := SymbolKind;
                NValue(1) := StrCpy("deref");
                NValue(2) := MAlloc(6);
                XPLReaderReadInto := NValue(2);
                XPLReaderReadInto(2) := 0;
                XPLReaderNext;
                XPLReaderReadForm;
            end;
        ^':
            begin
                XPLReaderReadInto(0) := ListKind;
                NValue := MAlloc(6);
                XPLReaderReadInto(1) := NValue;
                NValue(0) := SymbolKind;
                NValue(1) := StrCpy("quote");
                NValue(2) := MAlloc(6);
                XPLReaderReadInto := NValue(2);
                XPLReaderReadInto(2) := 0;
                XPLReaderNext;
                XPLReaderReadForm;
            end;
        ^`:
            begin
                XPLReaderReadInto(0) := ListKind;
                NValue := MAlloc(6);
                XPLReaderReadInto(1) := NValue;
                NValue(0) := SymbolKind;
                NValue(1) := StrCpy("quasiquote");
                NValue(2) := MAlloc(6);
                XPLReaderReadInto := NValue(2);
                XPLReaderReadInto(2) := 0;
                XPLReaderNext;
                XPLReaderReadForm;
            end;
        ^~:
            begin
                XPLReaderReadInto(0) := ListKind;
                NValue := MAlloc(6);
                XPLReaderReadInto(1) := NValue;
                NValue(0) := SymbolKind;
                NValue(1) := StrCpy(if Token(1) = ^@ then "splice-unquote" else "unquote");
                NValue(2) := MAlloc(6);
                XPLReaderReadInto := NValue(2);
                XPLReaderReadInto(2) := 0;
                XPLReaderNext;
                XPLReaderReadForm;
            end;
        ^^:
            begin
                XPLReaderReadInto(0) := ListKind;
                NValue := MAlloc(6);
                XPLReaderReadInto(1) := NValue;
                NValue(0) := SymbolKind;
                NValue(1) := StrCpy("with-meta"); \ (with-meta .. ..)
                NValue(2) := MAlloc(6);

                XPLReaderReadInto := NValue(2);
                XPLReaderNext;
                XPLReaderReadForm;
                
                MValue := NValue(2); \ (with-meta X ..)

                NValue(2) := MAlloc(6); \ (with-meta .. ..)
                XPLReaderReadInto := NValue(2);
                NValue := NValue(2);
                XPLReaderReadForm; \ (with-meta Y ..)

                NValue(2) := MValue; \ (with-meta Y X)
                MValue(2) := 0;
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

int Initialized;

function XPLReaderReadStr(Str);
char Str;
int Position;
int NextPosition;
int I;
begin
    if Initialized = 0 then begin
        Initialized := 1;
        XPLReaderReadStr("{:a {:b {:c 3}}}"); \ Read something?
    end;

    XPLMALError := 0; \ Clear exception
    Position := 0; \ start at the beginning of string
    NextPosition := XPLReaderTokenize(Str, addr Position);
    \ TellPos(Position, NextPosition);
    TokenPosition := 0; \ Should we do something about this? 
                        \ is this called recursively at all?
    if Position = NextPosition then
        return XPLCreateNil;
    loop begin
        I := 0;
        if Position = NextPosition then quit;
        \ PrintRange(Str, Position, NextPosition - 1);
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
    Tokens(TokenPosition, 0) := 0; \ Reset the next token to be empty

    TokenPosition := 0;
    XPLReaderReadInto := MAlloc(6);
    return XPLReaderReadForm;
end;