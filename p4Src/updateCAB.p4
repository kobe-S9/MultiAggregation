#ifndef _updateCAB_
#define _updateCAB_

#include "header.p4"

control updateCAB(
    inout headers hdr, 
    inout metadata meta) {


    action update_All(){
        bit<32>bitmap;
        bitmap = meta.worker_bitmap_before | hdr.Multi.bitmap;
        bitmap_reg.write(meta.valueIndex+meta.offset,bitmap);

        meta.counterNow = meta.counterNow + 0x1;
        counter_reg.write(meta.valueIndex+meta.offset+4, meta.counterNow);

        ECN_reg.write(meta.index,meta.ECN);
    }

    action send_Result(){
        hdr.Multi.bitmap = meta.worker_bitmap_before | hdr.Multi.bitmap;
    }

    table updateAll {
        key = {
            hdr.Multi.isACK : exact;
        }
        actions = {
            update_All;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table sendResult {
        key = {
            hdr.Multi.isACK : exact;
        }
        actions = {
            send_Result;
        }
        size = 1024;
        default_action = send_Result();
    }

    apply {
            updateAll.apply();
            
            if(meta.counterNow == 2){
                sendResult.apply();
            }
    }
    
}

#endif /* _updateCAB_ */
