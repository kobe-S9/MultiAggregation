#ifndef _updateCAB_
#define _updateCAB_

#include "header.p4"

control updateCAB(
    inout headers hdr, 
    inout metadata meta) {
    
    bit<1>isSend;
        
    action update_All(){
        bit<32>bitmap;
        bitmap = meta.worker_bitmap_before | hdr.Multi.bitmap;
        bitmap_reg.write(meta.valueIndex+meta.offset,bitmap);

        meta.counterNow = meta.counterNow + 0x1;
        counter_reg.write(meta.valueIndex+meta.offset, meta.counterNow);

        ECN_reg.write(meta.index,meta.ECN);
    }

    action send_Check(){
        bit<32> c1;
        bit<32> c2;
        bit<32> c3;
        bit<32> c4;

        bit<8> f1;
        bit<8> f2;
        bit<8> f3;
        bit<8> f4;

        counter_reg.read(c1,meta.valueIndex);
        counter_reg.read(c2,meta.valueIndex+1);
        counter_reg.read(c3,meta.valueIndex+2);
        counter_reg.read(c4,meta.valueIndex+3);

        fanInDegree_reg.read(f1,meta.valueIndex);
        fanInDegree_reg.read(f2,meta.valueIndex+1);
        fanInDegree_reg.read(f3,meta.valueIndex+2);
        fanInDegree_reg.read(f4,meta.valueIndex+3);

        if(c1 == (bit<32>)f1 && c2 == (bit<32>)f2 && c3 == (bit<32>)f3 && c4 == (bit<32>)f4){
            isSend = 1;
            meta.dropflag = 0;
            hdr.Multi.bitmap = meta.worker_bitmap_before | hdr.Multi.bitmap;
        }else{
            isSend = 0;
            meta.dropflag = 1;
        }
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



    table sendCheck {
        key = {
            hdr.Multi.isACK : exact;
        }
        actions = {
            send_Check;
        }
        size = 1024;
        default_action = send_Check();
    }



    apply {
            updateAll.apply();
            sendCheck.apply();

    }
    
}

#endif /* _updateCAB_ */
