/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "header.p4"
#include "check.p4"
#include "parser.p4"
#include "processor.p4"
#include "updateCAB.p4"



/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
//转发和丢弃    
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {

        //set the src mac address as the previous dst
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

       //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dstAddr;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl -1;

    }

    action multicast(bit<16> mcast_grp) {
        standard_metadata.mcast_grp = mcast_grp;
    }

    table ipv4_lpm {
        key = {
            meta.dropflag: exact;
            meta.isACK:exact;
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            multicast;
        }

        default_action = drop();
    }

    Check() checker;
    Processor() pro1;
    Processor() pro2;
    Processor() pro3;
    Processor() pro4;
    updateCAB() updateCABer;
    
//初始化

    apply {

        //如果是Multi包则初始化获取当前交换机聚合状态。
        if(hdr.Multi.isValid())
        {
            if(hdr.Multi.isACK == 1){
                //广播
                meta.dropflag = 0;
                meta.isACK = 1;
            }else{
                    checker.apply(hdr,meta);
                
                //检查位图和计数器判断下一个动作
                    if(meta.ifaggregation == 0){
                        if(meta.counterNow < 2 )//为2是因为这里的网络拓扑只设置了2个工作节点。
                        {
                            pro1.apply(meta, hdr.data.d00);
                            pro2.apply(meta, hdr.data.d01);
                            pro3.apply(meta, hdr.data.d02);
                            pro4.apply(meta, hdr.data.d03);
                            updateCABer.apply(hdr,meta);
                            if(meta.counterNow < 2 ){
                                meta.dropflag = 1;
                            }
                        
                        }else{
                            //该工作节点的包没有聚合过，但显示已经聚合完成，说明了什么？要实现什么功能？
                            //worker重发
                        
                        }

                    }else{
                        //已经聚合过则ECN = pck.ecn(没有实现）然后drop
                    }

            }
            
        }
        
        //only if IPV4 the rule is applied. Therefore other packets will not be forwarded.
        if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();

        }


    }
}




/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        //parsed headers have to be added again into the packet.
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.Multi);
        packet.emit(hdr.data);

    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
