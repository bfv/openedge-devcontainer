
var File f = new File("hello.p").

var int i = 30.  // set to 20 for debugging (if that works...)

waitblock:
do while i > 0:
    message "waited " + string(i) " seconds for debugger attach ...".
    pause 1 no-message. // Click continue or press f5 to continue debugging
    i -= 1.
    if debugger:visible then do:
        pause 1 no-message. 
        leave waitblock.
    end.
end.

output to /tmp/bla.txt.
put unformatted "Hello, World".
output close.

def var p as Person no-undo.
p = new Person().
message p:Hello().
delete object p. 

message f:ToString().
delete object f.

