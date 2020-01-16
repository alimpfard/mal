function XPLPrinterSPrStr(Value, Form);
char Value;
int Form;
int Val;
int ListPrinted;
begin
    \// Text(0, "SPrStr Form of kind ");
    \// IntOut(0, Form(0));
    \// CrLf(0);
    case Form(0) of
        NumberKind: begin
            Val := IToA(Form(1)); 
            Value := Value + SPrintF0(Value, Val);
            end;
        SymbolKind:
            Value := Value + SPrintF0(Value, Form(1));
        StringKind:
            Value := Value + SPrintF0(Value, Form(1));
        KeywordKind:
            Value := Value + SPrintF0(Value, Form(1));
        TrueKind:
            Value := Value + SPrintF0(Value, "true");
        FalseKind:
            Value := Value + SPrintF0(Value, "false");
        NilKind:
            Value := Value + SPrintF0(Value, "nil");
        ListKind: begin
            Form := Form(1); \// Children
            Value(0) := ^(;
            Value := Value + 1;
            ListPrinted := 0;
            loop begin
                if Form = 0 then quit;
                if Form(0) < 0 or Form(0) > InvalidKind then quit;
                ListPrinted := 1;
                Value := XPLPrinterSPrStr(Value, Form);
                Value := Value + SPrintF0(Value, " ");
                Form := Form(2);
            end;
            Value(0 - ListPrinted) := ^);
            if ListPrinted = 0 then
                Value := Value + 1;
            Value(0) := 0;
        end;
        VectorKind: begin
            Form := Form(1); \// Children
            Value(0) := ^[;
            Value := Value + 1;
            ListPrinted := 0;
            loop begin
                if Form = 0 then quit;
                if Form(0) < 0 or Form(0) > InvalidKind then quit;
                ListPrinted := 1;
                Value := XPLPrinterSPrStr(Value, Form);
                Value := Value + SPrintF0(Value, " ");
                Form := Form(2);
            end;
            Value(0 - ListPrinted) := ^];
            if ListPrinted = 0 then
                Value := Value + 1;
            Value(0) := 0;
        end
    other begin
        Text(0, "Unknown Kind ");
        IntOut(0, Form(0));
        Text(0, " In ");
        IntOut(0, Form);
        CrLf(0);
    end;
    return Value;
end;

function XPLPrinterPrStr(Form);
int Form;
char VBuffer(512);
int Str;
begin

    Str := VBuffer;
    XPLPrinterSPrStr(Str, Form);
    return Str;
end;