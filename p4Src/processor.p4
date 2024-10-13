#ifndef _PROCESSOR_
#define _PROCESSOR_

#include "header.p4"

// Sum calculator
// Each control handles two value_reg
control Processor(
    inout metadata meta,
   inout headers hdr) {



    //register<bit<32>>(register_size) values;

    register<bit<32>>(register_size) values0;//data0
    register<bit<32>>(register_size) values1;//d1
    register<bit<32>>(register_size) values2;//d2
    register<bit<32>>(register_size) values3;//d3
    register<bit<32>>(register_size) values4;//d4

    apply {
            bit<32> d00 =(bit<32>) hdr.data.d00;
            bit<32> d01 =(bit<32>) hdr.data.d01;
            bit<32> d02 =(bit<32>) hdr.data.d02;
            bit<32> d03 =(bit<32>) hdr.data.d03;
            bit<32> d04 =(bit<32>) hdr.data.d04;

            if(meta.isResubmit == 1){
                //取数
                values0.read(d00,meta.index);
                values1.read(d01,meta.index);
                values2.read(d02,meta.index);
                values3.read(d03,meta.index);
                values4.read(d04,meta.index);

                //取高8位
                hdr.data.d00 = (bit<8>)(d00 >> 24);
                hdr.data.d01 = (bit<8>)(d01 >> 24);
                hdr.data.d02 = (bit<8>)(d02 >> 24);
                hdr.data.d03 = (bit<8>)(d03 >> 24);
                hdr.data.d04 = (bit<8>)(d04 >> 24);

                //high
                hdr.high.setValid();
                hdr.high.d00 = (bit<8>)((d00 >> 16) & 0xFF);
                hdr.high.d01 = (bit<8>)((d01 >> 16) & 0xFF);
                hdr.high.d02 = (bit<8>)((d02 >> 16) & 0xFF);
                hdr.high.d03 = (bit<8>)((d03 >> 16) & 0xFF);
                hdr.high.d04 = (bit<8>)((d04 >> 16) & 0xFF);


                hdr.Low.setValid();
                hdr.Low.d00 = (bit<8>)((d00 >> 8) & 0xFF);
                hdr.Low.d01 = (bit<8>)((d01 >> 8) & 0xFF);
                hdr.Low.d02 = (bit<8>)((d02 >> 8) & 0xFF);
                hdr.Low.d03 = (bit<8>)((d03 >> 8) & 0xFF);
                hdr.Low.d04 = (bit<8>)((d04 >> 8) & 0xFF);

                hdr.Lowest.setValid();
                hdr.Lowest.d00 = (bit<8>)(d00 & 0xFF);
                hdr.Lowest.d01 = (bit<8>)(d01 & 0xFF);
                hdr.Lowest.d02 = (bit<8>)(d02 & 0xFF);
                hdr.Lowest.d03 = (bit<8>)(d03 & 0xFF);
                hdr.Lowest.d04 = (bit<8>)(d04 & 0xFF);

                //更新字节长度
                hdr.udp.length = hdr.udp.length + 15;
                hdr.ipv4.totalLen = hdr.ipv4.totalLen + 15;
     
            }else{
                if(meta.offset == 0){//高8位
                    d00 = d00 << 24;
                    d01 = d01 << 24;
                    d02 = d02 << 24;
                    d03 = d03 << 24;
                    d04 = d04 << 24;
                }

                if(meta.offset == 1){//次高8位
                    d00 = d00 << 16;
                    d01 = d01 << 16;
                    d02 = d02 << 16;
                    d03 = d03 << 16;
                    d04 = d04 << 16;
                }

                if(meta.offset == 2){//次低8位
                    d00 = d00 << 8;
                    d01 = d01 << 8;
                    d02 = d02 << 8;
                    d03 = d03 << 8;
                    d04 = d04 << 8;
                }

                if(meta.firstPacket == 0){//first
                    values0.write(meta.index, d00);
                    values1.write(meta.index, d01);
                    values2.write(meta.index, d02);
                    values3.write(meta.index, d03);
                    values4.write(meta.index, d04);                    
                }else{

                    bit<32>read_value;
                    bit<32>carry;
                    bit<64>sum;

                    //d00
                    values0.read(read_value, meta.index);
                    sum = (bit<64>)read_value + (bit<64>)d00;
                    carry =(bit<32>) (sum >> 32);
                    if(carry > 0){//溢出
                        values0.write(meta.index, 0xffffffff);
                    }else{
                        values0.write(meta.index, (bit<32>)sum);
                    }

                    //d01
                    values1.read(read_value, meta.index);
                    sum = (bit<64>)read_value + (bit<64>)d01;
                    carry =(bit<32>) (sum >> 32);
                    if(carry > 0){
                        values1.write(meta.index, 0xffffffff);
                    }else{
                        values1.write(meta.index, (bit<32>)sum);
                    }

                    //d02
                    values2.read(read_value, meta.index);
                    sum = (bit<64>)read_value + (bit<64>)d02;
                    carry =(bit<32>) (sum >> 32);
                    if(carry > 0){
                        values2.write(meta.index, 0xffffffff);
                    }else{
                        values2.write(meta.index, (bit<32>)sum);
                    }

                    //d03
                    values3.read(read_value, meta.index);
                    sum = (bit<64>)read_value + (bit<64>)d03;
                    carry =(bit<32>) (sum >> 32);
                    if(carry > 0){
                        values3.write(meta.index, 0xffffffff);
                    }else{
                        values3.write(meta.index, (bit<32>)sum);
                    }

                    //d04
                    values4.read(read_value, meta.index);
                    sum = (bit<64>)read_value + (bit<64>)d04;
                    carry =(bit<32>) (sum >> 32);
                    if(carry > 0){
                        values4.write(meta.index, 0xffffffff);
                    }else{
                        values4.write(meta.index, (bit<32>)sum);
                    }

                }
            }
       
            

        //add.apply();
    }
}

#endif /* _PROCESSOR_ */
