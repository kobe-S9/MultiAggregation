
#ifndef _HIGHEST_
#define _HIGHEST_

#include "header.p4"

control Highest(
    inout headers hdr,
    inout metadata meta) {

    
    bit<32> bitmapResult = 0x0;
    bit<32> index;

    apply {
        bit<8>h1;
        bit<8>l0;
        bit<8>l1;

        h1 = (bit<8>)(hdr.Multi.types & 4w4);
        l0 = (bit<8>)(hdr.Multi.types & 4w2);
        l1 = (bit<8>)(hdr.Multi.types & 4w1);

        fanInDegree_reg.write(meta.valueIndex,hdr.Multi.fanInDegree);
        if(h1>0){
            index = meta.valueIndex+1;
            bit<8> fanInDegree;
            fanInDegree_reg.read(fanInDegree,index);
            fanInDegree = fanInDegree + 1;
            fanInDegree_reg.write(index,fanInDegree);
        }
        if(l0>0){
            index = meta.valueIndex+2;
            bit<8> fanInDegree;
            fanInDegree_reg.read(fanInDegree,index);
            fanInDegree = fanInDegree + 1;
            fanInDegree_reg.write(index,fanInDegree);
        }
        if(l1>0){
            index = meta.valueIndex+3;
            bit<8> fanInDegree;
            fanInDegree_reg.read(fanInDegree,index);
            fanInDegree = fanInDegree + 1;
            fanInDegree_reg.write(index,fanInDegree);
        }             
    }
    
}

#endif /* _HIGHEST_ */
