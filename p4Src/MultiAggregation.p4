/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "header.p4"
#include "parser.p4"
#include "processor.p4"


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

bit<32> bitmapResult = 0x0;

// Define your registers
register<bit<32>>(register_size) bitmap_reg;
register<bit<32>>(register_size) counter_reg;
register<bit<1>>(10) ECN_reg;
register<bit<8>>(register_size) fanInDegree_reg;

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


//check
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


//update

        
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
            meta.isSend = 1;
            meta.dropflag = 0;
            hdr.Multi.bitmap = meta.worker_bitmap_before | hdr.Multi.bitmap;//只有一个不完全.
            meta.types = 4w8;
            if(c2>0){
                meta.types = meta.types |4w4;
            }
            if(c3>0){
                meta.types = meta.types |4w2;
            }
            if(c4>0){
                meta.types = meta.types |4w1;
            }
            hdr.Multi.types = meta.types;
        }else{
            meta.isSend = 0;
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



//release

    action release_reg(){
        counter_reg.write(meta.valueIndex,0);
        counter_reg.write(meta.valueIndex+1,0);
        counter_reg.write(meta.valueIndex+2,0);
        counter_reg.write(meta.valueIndex+3,0);

        bitmap_reg.write(meta.valueIndex,0);
        bitmap_reg.write(meta.valueIndex+1,0);
        bitmap_reg.write(meta.valueIndex+2,0);
        bitmap_reg.write(meta.valueIndex+3,0);

        ECN_reg.write(meta.valueIndex,0);
    }  

    table release {
        key = {
            meta.isACK : exact;
        }
        actions = {
            release_reg;
        }
        size = 1024;
        default_action = release_reg();
    }



    //Check() checker;
    //Highest() Highester;
    Processor() pro;
    //updateCAB() updateCABer;
    //Release() releaser;
//初始化

    apply {

        //如果是Multi包则初始化获取当前交换机聚合状态。
        if(hdr.Multi.isValid())
        {
            if(hdr.Multi.isACK == 1){
                //广播
                meta.dropflag = 0;
                meta.isACK = 1;
                release.apply();
            }else{
            //checkBitmap.apply();
                meta.offset = (bit<32>)(hdr.Multi.types & 4w7);

                if(hdr.Multi.types > 7){
                    meta.offset = 0;
                    meta.types = hdr.Multi.types;
                    meta.high = meta.types & 4w4;
                    meta.low = meta.types & 4w2;
                    meta.LOW = meta.types & 4w1;
                }
                readMultimd.apply();    
                meta.isResubmit = 0;                    
                if(standard_metadata.instance_type == 6){
                    meta.isResubmit = 1;
                    hdr.Multi.types = meta.types;
                    meta.high = meta.types & 4w4;
                    meta.low = meta.types & 4w2;
                    meta.LOW = meta.types & 4w1;
                    pro.apply(meta,hdr);
                    meta.ifaggregation = 1;
                    meta.isSend = 1;
                    meta.dropflag = 0;
                }
                //检查位图和计数器判断下一个动作
                    if(meta.ifaggregation == 0){
                        if(meta.counterNow < 2 )//为2是因为这里的网络拓扑只设置了2个工作节点。
                        {
                            pro.apply(meta,hdr);
                            //高位包
                            if(hdr.Multi.types > 7){
                                bit<32> index;
                                fanInDegree_reg.write(meta.valueIndex,hdr.Multi.fanInDegree);
                                if(meta.high != 0){
                                    index = meta.valueIndex+1;
                                    bit<8> fanInDegree;
                                    fanInDegree_reg.read(fanInDegree,index);
                                    fanInDegree = fanInDegree + 1;
                                    fanInDegree_reg.write(index,fanInDegree);
                                }
                                if(meta.low != 0){
                                    index = meta.valueIndex+2;
                                    bit<8> fanInDegree;
                                    fanInDegree_reg.read(fanInDegree,index);
                                    fanInDegree = fanInDegree + 1;
                                    fanInDegree_reg.write(index,fanInDegree);
                                }
                                if(meta.LOW != 0){
                                    index = meta.valueIndex+3;
                                    bit<8> fanInDegree;
                                    fanInDegree_reg.read(fanInDegree,index);
                                    fanInDegree = fanInDegree + 1;
                                    fanInDegree_reg.write(index,fanInDegree);
                                }   
                            }
                                updateAll.apply();
                                sendCheck.apply();
                                if(meta.isSend == 1 && meta.isResubmit == 0){
                                    hdr.Multi.types = meta.types;
                                    resubmit_preserving_field_list(1);
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

        packet.emit(hdr.high);
        packet.emit(hdr.low);
        packet.emit(hdr.LOW);

        

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
