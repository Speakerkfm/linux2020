#!/bin/bash

check() {
	return 0
}

depends() {
	return 0
}

install() {
	inst_hook cleanup 00 "$moddir/test.sh"
}
[vagrant@localhost 41test]$ cat test.sh
#!/bin/bash
exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'



                 _.._
              .-'    `-.
             :          ;
             ; ,_    _, ;
             : \{"  "}/ :
            ,'.'"=..=''.'.
           ; / \      / \ ;
         .' ;   '.__.'   ; '.
      .-' .'              '. '-.
    .'   ;                  ;   '.
   /    /                    \    \
  ;    ;                      ;    ;
  ;   `-._                  _.-'   ;
   ;      ""--.        .--""      ;
    '.    _    ;      ;    _    .'
    {""..' '._.-.    .-._.' '..""}
     \           ;  ;           /
      :         :    :         :
      :         :.__.:         :
       \       /"-..-"\       /    fsc
        '-.__.'        '.__.-'

msgend
sleep 10
echo "continuing...."