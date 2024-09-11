#ifndef _PROCESSOR_
#define _PROCESSOR_

#include "header.p4"

// Sum calculator
// Each control handles two value_reg
control Processor(
    inout metadata meta,
    inout value_t data) {

/*
    action sum_read_action() {
        bit<32>read_value;
        bit<32>value_out;

        meta.valueIndex = meta.valueIndex + meta.offset;
        
        value_reg.read(read_value, meta.valueIndex);
        value_out = read_value + data;
        value_reg.write(meta.valueIndex, value_out);

        data = value_out;
        meta.offset = meta.offset + 0x1;
    }
*/

    register<bit<8>>(register_size) values;

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

    apply {
        add.apply();
    }
}

#endif /* _PROCESSOR_ */
