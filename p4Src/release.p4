#ifndef _release_
#define _release_

#include "header.p4"

control release(
    inout headers hdr, 
    inout metadata meta) {


    action release_reg(){

        bitmap_reg.write(meta.index, meta.bitmap);

        meta.counterNow = meta.counterNow + 0x1;
        counter_reg.write(meta.index, meta.counterNow);
    }

    action send_Result(){
        hdr.Multi.bitmap = meta.bitmap;
    }

    table release {
        key = {
            meta.isACK : exact;
        }
        actions = {
            release_reg;
        }
        size = 1024;
        default_action = noAction();
    }


    apply {
            release.apply();
            
    }
    
}

#endif /* _release_ */
