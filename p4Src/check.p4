
#ifndef _CHECK_
#define _CHECK_

#include "header.p4"

control Check(
    inout headers hdr,
    inout metadata meta) {

    
    bit<32> bitmapResult = 0x0;
    
    // Define your registers
    register<bit<32>>(register_size) bitmap_reg;
    register<bit<32>>(register_size) counter_reg;
    register<bit<1>>(10) ECN_reg;
    register<bit<8>>(register_size) fanInDegree_reg;

    action read_Multi_md() {
        bit<32>   bitmapR;
        bit<32>   counterR;
        bit<1>    ECNR;
        bit<32>   SeqNumR;

        meta.isHigh = hdr.Multi.types & 4w8;
        meta.index = hdr.Multi.index;
        meta.isACK = hdr.Multi.isACK;
        meta.valueIndex = hdr.Multi.index * 4;
        meta.types = hdr.Multi.types;

        bitmap_reg.read(bitmapR, meta.valueIndex+meta.offset);
        meta.worker_bitmap_before = bitmapR;
        meta.ifaggregation = bitmapR & hdr.Multi.bitmap;
        
        counter_reg.read(counterR, meta.valueIndex+meta.offset);
        meta.counterNow = counterR;

        ECN_reg.read(ECNR, meta.index);
        meta.ECN = ECNR;

    }


    table readMultimd {
        key = {
            hdr.Multi.isACK : exact;
        }
        actions = {
            read_Multi_md;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }



    apply {
            //checkBitmap.apply();
            meta.offset = (bit<32>)(hdr.Multi.types & 4w7);
            if(meta.offset == 1){
                meta.offset = 3;
            }
            if(meta.offset == 2){
                meta.offset = 2;
            }
            if(meta.offset == 4){
                meta.offset = 1;
            }
            if(hdr.Multi.types > 7){
                meta.offset = 0;
            }
            readMultimd.apply();                        
    }
    
}




#endif /* _CHECK_ */
