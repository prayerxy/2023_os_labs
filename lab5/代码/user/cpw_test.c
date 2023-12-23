#include <ulib.h>
#include <stdio.h>

const int max_child = 10;
int
main(void) {
    //0 - 9 
    int n,pid,code;
    int sum = 0, iscaculate = 0;
    for (n = 0; n < max_child; n ++) {
        if((pid = fork())==0){
            cprintf("Child %d born!\n",n);
            cprintf("Child %d died!\n",n);
            exit(0);
            
        }
    }

    for (; n > 0; n --) {
        if (wait() != 0) {
            panic("wait stopped early\n");
        }
    }
    cprintf("all children below has died!\n");
    if((pid = fork())==0){
        iscaculate = 1;
    }
    if(iscaculate){
        cprintf("let a child caculate sum from 0 to 9\n");
        for(int i=0;i<10;i++){
            sum+=i;
        }
        cprintf("caculate over\n");
        cprintf("sum :%d\n",sum);
        exit(0);
    }
    assert(waitpid(pid, &code) == 0);
    yield();
    cprintf("test pass.\n");
    return 0;
    
}