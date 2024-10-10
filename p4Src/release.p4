#ifndef _Release_
#define _Release_

#include "header.p4"

control Release(
    inout headers hdr, 
    inout metadata meta) {


    action release_reg(){
        counter_reg.write(meta.valueIndex,0);
        counter_reg.write(meta.valueIndex+1,0);
        counter_reg.write(meta.valueIndex+2,0);
        counter_reg.write(meta.valueIndex+3,0);

        bitmap_reg.write(meta.valueIndex,0);
        bitmap_reg.write(meta.valueIndex+1,0);
        bitmap_reg.write(meta.valueIndex+2,0);
        bitmap_reg.write(meta.valueIndex+3,0);

        ECN_reg.write(meta.valueIndex,0);
    }  

    table release {
        key = {
            meta.isACK : exact;
        }
        actions = {
            release_reg;
        }
        size = 1024;
        default_action = release_reg();
    }


    apply {
            release.apply();
            
    }
    
}

#endif /* _Release_ */
