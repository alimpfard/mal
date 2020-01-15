import "jq/io" as io;

def __readline:
    . as $dot
    | io::fopen("/dev/stdout"; "w"; null; null)
    | fhwrite($dot)
    | fhclose
    | io::fopen("/dev/stdin"; "r"; null; null)
    | fhread
    ;

def read_file:
    io::fopen(.; "r"; null; null)
    | fhread
    ;

def _display:
    tostring
    | . + "\n" as $content
    | "/dev/stdout"
    | io::fopen(.; "w"; null; null)
    | fhwrite($content)
    ;