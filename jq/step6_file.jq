include "reader";
include "printer";
include "utils";
include "interp";
include "env";
include "core";

def read_line:
    . as $in
    | label $top
    | input;

def READ:
    read_str | read_form | .value;

def special_forms:
    [ "if", "def!", "let*", "fn*", "do" ];

def find_free_references(keys):
    def _refs:
        . as $dot
        | if .kind == "symbol" then
            if keys | contains([$dot.value]) then [] else [$dot.value] end
        else if "list" == $dot.kind then
            ($dot.value[1:] | map(_refs) | reduce .[] as $x ([]; . + $x)) + ($dot.value[0] | find_free_references(keys + special_forms))
        else if "vector" == $dot.kind then
            ($dot.value[1:] | map(_refs) | reduce .[] as $x ([]; . + $x)) + ($dot.value[0] | find_free_references(keys + special_forms))
        else
            []
        end end end;
    _refs | unique; 

def recurseflip(x; y):
    recurse(y; x);

def TCOWrap(env; retenv; continue):
    {
        ast: .,
        env: env,
        ret_env: retenv,
        finish: (continue | not),
        cont: true # set inside
    };

def EVAL(env):
    def _eval_here:
        .env as $env | .expr | EVAL($env);

    def hmap_with_env:
        .env as $env | .list as $list |
            if $list|length == 0 then
                empty
            else
                $list[0] as $elem |
                $list[1:] as $rest |
                    $elem.value.value | EVAL($env) as $resv |
                        {
                            value: {
                                key: $elem.key,
                                value: { kkind: $elem.value.kkind, value: $resv.expr }
                            },
                            env: env
                        },
                        ({env: $resv.env, list: $rest} | hmap_with_env)
            end;
    def map_with_env:
        .env as $env | .list as $list |
            if $list|length == 0 then
                empty
            else
                $list[0] as $elem |
                $list[1:] as $rest |
                    $elem | EVAL($env) as $resv |
                        { value: $resv.expr, env: env },
                        ({env: $resv.env, list: $rest} | map_with_env)
            end;
    . as $ast
    | { env: env, ast: ., cont: true, finish: false, ret_env: null }
    | [ recurseflip(.cont;
        .env as $_menv
        | if .finish then
            .cont |= false
        else
            (.ret_env//.env) as  $_retenv
            | .ret_env as $_orig_retenv
            | .ast
            | . as $init
            | $_menv | unwrapCurrentEnv as $currentEnv # unwrap env "package"
            | $_menv | unwrapReplEnv    as $replEnv    # -
            | $init
            |
            (select(.kind == "list") |
                if .value | length == 0 then 
                    . | TCOWrap($_menv; $_orig_retenv; false)
                else
                    (
                        (
                            .value | select(.[0].value == "def!") as $value |
                                ($value[2] | EVAL($_menv)) as $evval |
                                    addToEnv($evval; $value[1].value) as $val |
                                    $val.expr | TCOWrap($val.env; $_orig_retenv; false)
                        ) //
                        (
                            .value | select(.[0].value == "let*") as $value |
                                ($currentEnv | pureChildEnv | wrapEnv($replEnv)) as $subenv |
                                    (reduce ($value[1].value | nwise(2)) as $xvalue (
                                        $subenv;
                                        . as $env | $xvalue[1] | EVAL($env) as $expenv |
                                            env_set_($expenv.env; $xvalue[0].value; $expenv.expr))) | . as $env
                                                | $value[2] | TCOWrap($env; $_retenv; true)
                        ) //
                        (
                            .value | select(.[0].value == "do") as $value |
                                (reduce ($value[1:][]) as $xvalue (
                                    { env: $_menv, expr: {kind:"nil"} };
                                    .env as $env | $xvalue | EVAL($env)
                                )) | . as $ex | .expr | TCOWrap($ex.env; $_orig_retenv; false)
                        ) //
                        (
                            .value | select(.[0].value == "if") as $value |
                                $value[1] | EVAL($_menv) as $condenv |
                                    (if (["false", "nil"] | contains([$condenv.expr.kind])) then
                                        ($value[3] // {kind:"nil"})
                                    else
                                        $value[2]
                                    end) | TCOWrap($condenv.env; $_orig_retenv; true)
                        ) //
                        (
                            .value | select(.[0].value == "fn*") as $value |
                                # we can't do what the guide says, so we'll skip over this
                                # and ues the later implementation
                                # (fn* args body)
                                $value[1].value | map(.value) as $binds | {
                                    kind: "function",
                                    binds: $binds,
                                    env: env,
                                    body: $value[2],
                                    names: [], # we can't do that circular reference this
                                    free_referencess: $value[2] | find_free_references($currentEnv | env_dump_keys + $binds) # for dynamically scoped variables
                                } | TCOWrap($_menv; $_orig_retenv; false)
                        ) //
                        (
                            reduce .value[] as $elem (
                                [];
                                . as $dot | $elem | EVAL($_menv) as $eval_env |
                                    ($dot + [$eval_env.expr])
                            ) | . as $expr | first |
                                    interpret($expr[1:]; $_menv; _eval_here) as $exprenv |
                                    $exprenv.expr | TCOWrap($exprenv.env; $_orig_retenv; false)
                        ) //
                            TCOWrap($_menv; $_orig_retenv; false)
                    )
                end
            ) //
            (select(.kind == "vector") |
                if .value|length == 0 then
                    {
                        kind: "vector",
                        value: []
                    } | TCOWrap($_menv; $_orig_retenv; false)
                else
                    [ { env: env, list: .value } | map_with_env ] as $res |
                    {
                        kind: "vector",
                        value: $res | map(.value)
                    } | TCOWrap($res | last.env; $_orig_retenv; false)
                end
            ) //
            (select(.kind == "hashmap") |
                [ { env: env, list: (.value | to_entries) } | hmap_with_env ] as $res |
                {
                    kind: "hashmap",
                    value: $res | map(.value) | from_entries
                } | TCOWrap($res | last.env; $_orig_retenv; false)
            ) //
            (select(.kind == "function") |
                . | TCOWrap($_menv; $_orig_retenv; false) # return this unchanged, since it can only be applied to
            ) //
            (select(.kind == "symbol") |
                .value | env_get($currentEnv) | TCOWrap($_menv; null; false)
            ) // TCOWrap($_menv; $_orig_retenv; false)
        end
    ) ] 
    | last as $result
    | ($result.ret_env // $result.env) as $env
    | $result.ast
    | addEnv($env);

def PRINT:
    pr_str;

def rep(env):
    READ | EVAL(env) as $expenv |
        if $expenv.expr != null then
            $expenv.expr | PRINT
        else
            null
        end | addEnv($expenv.env);

def repl_(env):
    ("user> " | _print) |
    (read_line | rep(env));

# we don't have no indirect functions, so we'll have to interpret the old way
def replEnv:
    {
        parent: null,
        environment: ({
            "+": {
                kind: "fn", # native function
                inputs: 2,
                function: "number_add"
            },
            "-": {
                kind: "fn", # native function
                inputs: 2,
                function: "number_sub"
            },
            "*": {
                kind: "fn", # native function
                inputs: 2,
                function: "number_mul"
            },
            "/": {
                kind: "fn", # native function
                inputs: 2,
                function: "number_div"
            },
            "eval": {
                kind: "fn",
                inputs: 1,
                function: "eval"
            }
        } + core_identify)
    };

def repl(env):
    def xrepl:
        (.env as $env | try repl_($env) catch addEnv($env)) as $expenv |
            {
                value: $expenv.expr,
                stop: false,
                env: ($expenv.env // .env)
            } | ., xrepl;
    {stop: false, env: env} | xrepl | if .value then (.value | _print) else empty end;

def eval_ign(expr):
    . as $env | expr | rep($env) | .env;

def eval_val(expr):
    . as $env | expr | rep($env) | .expr;

def getEnv:
    replEnv
    | wrapEnv
    | eval_ign("(def! not (fn* (a) (if a false true)))")
    | eval_ign("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\\nnil)\")))))))");

def main:
    if $ARGS.positional|length > 0 then
        getEnv as $env |
        env_set_($env; "*ARGV*"; $ARGS.positional[1:] | wrap("list")) |
        eval_val("(load-file \($ARGS.positional[0] | tojson))")
    else
        repl( getEnv as $env | env_set_($env; "*ARGV*"; [] | wrap("list")) )
    end;

main