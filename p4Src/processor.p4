#ifndef _PROCESSOR_
#define _PROCESSOR_

#include "header.p4"

// Sum calculator
// Each control handles two value_reg
control Processor(
    inout metadata meta,
   inout headers hdr) {



    //register<bit<8>>(register_size) values;

    register<bit<8>>(register_size) values0;//data0
    register<bit<8>>(register_size) values1;//d1
    register<bit<8>>(register_size) values2;//d2
    register<bit<8>>(register_size) values3;//d3
    register<bit<8>>(register_size) values4;//d4

/*
    action read_action() {
        meta.valueIndex = meta.valueIndex + meta.offset;
        values.read(data, (bit<32>)meta.valueIndex);
    }
    action write_action() {
        values.write((bit<32>)meta.valueIndex, data);
    }

    action sum_read_action() {
        bit<8>read_value;
        values.read(read_value, (bit<32>)meta.valueIndex);
        data = read_value + data;
        values.write((bit<32>)meta.valueIndex, data);
    }

    table add {
        key = {
            meta.worker_bitmap_before:range;
            meta.ifaggregation:exact;
        }
        actions = {
            read_action;
            write_action;
            sum_read_action;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }
*/
    apply {
            if(meta.ifaggregation == 0)
            {
                if(meta.worker_bitmap_before == 0){
                    values0.write(meta.valueIndex+meta.offset, hdr.data.d00);
                    values1.write(meta.valueIndex+meta.offset, hdr.data.d01);
                    values2.write(meta.valueIndex+meta.offset, hdr.data.d02);
                    values3.write(meta.valueIndex+meta.offset, hdr.data.d03);
                    values4.write(meta.valueIndex+meta.offset, hdr.data.d04);                    
                }
                if(meta.worker_bitmap_before > 0 && meta.worker_bitmap_before < 4294967295){
                    bit<8>read_value;

                    values0.read(read_value, meta.valueIndex+meta.offset);
                    values0.write((bit<32>)meta.valueIndex+meta.offset, hdr.data.d00+read_value);

                    values1.read(read_value, meta.valueIndex+meta.offset);
                    values1.write((bit<32>)meta.valueIndex+meta.offset, hdr.data.d01+read_value);

                    values2.read(read_value, meta.valueIndex+meta.offset);
                    values2.write((bit<32>)meta.valueIndex+meta.offset, hdr.data.d02+read_value);

                    values3.read(read_value, meta.valueIndex+meta.offset);
                    values3.write((bit<32>)meta.valueIndex+meta.offset, hdr.data.d03+read_value);

                    values4.read(read_value, meta.valueIndex+meta.offset);
                    values4.write((bit<32>)meta.valueIndex+meta.offset, hdr.data.d04+read_value);                    
                }
            }
            if(meta.isResubmit == 1){
                values0.read(hdr.data.d00,meta.valueIndex);
                values1.read(hdr.data.d01,meta.valueIndex);
                values2.read(hdr.data.d02,meta.valueIndex);
                values3.read(hdr.data.d03,meta.valueIndex);
                values4.read(hdr.data.d04,meta.valueIndex);


                if(meta.high != 0){
                    hdr.high.setValid();
                    values0.read(hdr.high.d00,meta.valueIndex+1);
                    values1.read(hdr.high.d01,meta.valueIndex+1);
                    values2.read(hdr.high.d02,meta.valueIndex+1);
                    values3.read(hdr.high.d03,meta.valueIndex+1);
                    values4.read(hdr.high.d04,meta.valueIndex+1);
                }

                if(meta.low != 0){
                    hdr.low.setValid();
                    values0.read(hdr.low.d00,meta.valueIndex+2);
                    values1.read(hdr.low.d01,meta.valueIndex+2);
                    values2.read(hdr.low.d02,meta.valueIndex+2);
                    values3.read(hdr.low.d03,meta.valueIndex+2);
                    values4.read(hdr.low.d04,meta.valueIndex+2);
                }

                if(meta.LOW != 0){
                    hdr.LOW.setValid();
                    values0.read(hdr.LOW.d00,meta.valueIndex+3);
                    values1.read(hdr.LOW.d01,meta.valueIndex+3);
                    values2.read(hdr.LOW.d02,meta.valueIndex+3);
                    values3.read(hdr.LOW.d03,meta.valueIndex+3);
                    values4.read(hdr.LOW.d04,meta.valueIndex+3);
                }               
            }
       
            

        //add.apply();
    }
}

#endif /* _PROCESSOR_ */
