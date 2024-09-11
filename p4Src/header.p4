#ifndef _HEADERS_
#define _HEADERS_

const bit<16> TYPE_IPV4 = 0x800;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<8> value_t;

#define register_size 4000


// Define your registers
register<bit<32>>(register_size) bitmap_reg;
register<bit<32>>(register_size) counter_reg;
register<bit<1>>(10) ECN_reg;




header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_t {
    bit<16> sport;
    bit<16> dport;
    bit<16> length;
    bit<16> checksum;
}

header Multi_h {
    bit<32>   bitmap;
    //bit<32>   SeqNum;
    //bit<32>    fanInDegree;
    bit<1>    overflow;
    //bit<1>    isSWCollison;
    bit<1>    isResend;
    bit<1>    ECN;
    bit<4>    types;
    bit<1>    isACK;
    bit<32>   index;
}


header data_h {
    value_t d00;
    value_t d01;
    value_t d02;
    value_t d03;
}

struct metadata {

    bit<32> counterNow;
    bit<32> index;
    bit<32> valueIndex;
    bit<32> worker_bitmap_before;
    bit<32> ifaggregation;
    bit<1> ECN;
    bit<32> offset;
    bit<1> dropflag;
    bit<1> isACK;
    bit<4> isHigh;
    
    bit<16> ingress_port;
    bit<16> egress_port;
}


struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
    Multi_h      Multi;
    data_h       data;
}

#endif /* _HEADERS_ */
