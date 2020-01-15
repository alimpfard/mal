import "io" as io;

def _debug(ex):
    . as $top
    | ex
    | debug
    | $top;

def _print:
    tostring;

def nwise(n):
    def _nwise:
        if length <= n then 
            .
        else
            .[0:n], (.[n:] | _nwise)
        end;
    _nwise;

def abs(x):
    if x < 0 then 0 - x else x end;

def jqmal_error(e):
    error("JqMAL Exception :: " + e);

def is_jqmal_error:
    startswith("JqMAL Exception :: ");

def wrap(kind):
    {
        kind: kind,
        value: .
    };

def wrap2(kind; opts):
    opts + {
        kind: kind,
        value: .
    };

def isPair:
    if (.kind == "list" or .kind == "vector") then
        .value | length > 0
    else
        false
    end;

def isPair(x):
    x | isPair;

def find_free_references(keys):
    def _refs:
      if . == null then [] else
        . as $dot
        | if .kind == "symbol" then
            if keys | contains([$dot.value]) then [] else [$dot.value] end
        else if "list" == $dot.kind then
            # if - scan args
            # def! - scan body
            # let* - add keys sequentially, scan body
            # fn* - add keys, scan body
            # quote - []
            # quasiquote - ???
            $dot.value[0] as $head
            | if $head.kind == "symbol" then 
                (
                    select($head.value == "if") | $dot.value[1:] | map(_refs) | reduce .[] as $x ([]; . + $x)
                ) // (
                    select($head.value == "def!") | $dot.value[2] | _refs
                ) // (
                    select($head.value == "let*") | $dot.value[2] | find_free_references(($dot.value[1].value as $value | ([ range(0; $value|length; 2) ] | map(select(. % 2 == 0) | $value[.].value))) + keys)
                ) // (
                    select($head.value == "fn*") | $dot.value[2] | find_free_references(($dot.value[1].value | map(.value)) + keys) 
                ) // (
                    select($head.value == "quote") | []
                ) // (
                    select($head.value == "quasiquote") | []
                ) // ($dot.value | map(_refs) | reduce .[] as $x ([]; . + $x))
              else
                [ $dot.values[1:][] | _refs ]
              end
        else if "vector" == $dot.kind then
            ($dot.value | map(_refs) | reduce .[] as $x ([]; . + $x))
        else if "hashmap" == $dot.kind then
            ([$dot.value | to_entries[] | ({kind: .value.kkind, value: .key}, .value.value) ] | map(_refs) | reduce .[] as $x ([]; . + $x))
        else
            []
        end end end end
      end;
    _refs | unique;

def tomal:
    (
        select(type == "array") | (
            map(tomal) | wrap("list")
        )
    ) // (
        select(type == "string") | (
            if startswith("sym/") then
                .[4:] | wrap("symbol")
            else
                wrap("string")
            end
        )
    ) // (
        select(type == "number") | (
            wrap("number")
        )
    );

def _display:
    io::_display;

def __readline:
    io::__readline;

def read_file:
    io::read_file;

def _halt:
    halt;