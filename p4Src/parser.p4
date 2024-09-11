#ifndef _PARSERS_
#define _PARSERS_

#include "header.p4"
#include "types.p4"

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {

        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;

        }

    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            17: parse_udp; // UDP
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dport) {
            12345 : parse_Multi;
            default: accept;
        }
    }   
    
    state parse_Multi {
        packet.extract(hdr.Multi);
        transition parse_values;
    }

    
    state parse_values {
        packet.extract(hdr.data);
        transition accept;
    }
}


control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}





#endif /* _PARSERS_ */
