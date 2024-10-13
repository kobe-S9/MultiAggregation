from scapy.all import *
from scapy.packet import Packet
from scapy.fields import BitField, IntField
import sys
import threading


class Multi(Packet):
    name = "Multi"
    fields_desc = [
        IntField("bitmap", 0),
        BitField("fanIndegree", 0, 8),
        BitField("overflow", 0, 1),
        BitField("isResend", 0, 1),
        BitField("ECN", 0, 1),
        BitField("types", 0, 4),
        BitField("isACK", 0, 1),
        IntField("index", 0)
    ]


class data0(Packet):
    name = "data0"
    fields_desc = [
        BitField("d00", 0, 8),
        BitField("d01", 0, 8),
        BitField("d02", 0, 8),
        BitField("d03", 0, 8),
        BitField("d04", 0, 8)
    ]

class data1(Packet):
    name = "data1"
    fields_desc = [
        BitField("d00", 0, 8),
        BitField("d01", 0, 8),
        BitField("d02", 0, 8),
        BitField("d03", 0, 8),
        BitField("d04", 0, 8)
    ]

class data2(Packet):
    name = "data2"
    fields_desc = [
        BitField("d00", 0, 8),
        BitField("d01", 0, 8),
        BitField("d02", 0, 8),
        BitField("d03", 0, 8),
        BitField("d04", 0, 8)
    ]

class data3(Packet):
    name = "data3"
    fields_desc = [
        BitField("d00", 0, 8),
        BitField("d01", 0, 8),
        BitField("d02", 0, 8),
        BitField("d03", 0, 8),
        BitField("d04", 0, 8)
    ]

class result(Packet):
    name = "result"
    fields_desc = [
        BitField("d00", 0, 32),
        BitField("d01", 0, 32),
        BitField("d02", 0, 32),
        BitField("d03", 0, 32),
        BitField("d04", 0, 32)
    ]
# 绑定层次关系,肯定全部取走不然有的进位了，但没有人发那8位，所以不知道取不取
bind_layers(UDP, Multi)
bind_layers(Multi, data0)
bind_layers(data0, data1)  
bind_layers(data1, data2)
bind_layers(data2, data3)


class receiver(object):
    def __init__(self, interface="eth0"):
        self.interface = interface
        self.stop_event = threading.Event()  # 用于停止监听

    def packet_callback(self, packet):
        # 如果数据包包含 Multi 层，开始解析
        if packet.haslayer(Multi):            
            print("Received Multi packet:")
            packet.show()
            ethernet = packet.getlayer(Ether)
            ip = packet.getlayer(IP)
            udp = packet.getlayer(UDP)
            Multi_layer = packet.getlayer(Multi)
            data0_layer = packet.getlayer(data0)
            data1_layer = packet.getlayer(data1)
            data2_layer = packet.getlayer(data2)
            data3_layer = packet.getlayer(data3)          
            if Multi_layer.bitmap == 3:
                Multi_layer.isACK = 1
                Result = result()
                Result.d00 =((data0_layer.d00 << 24) + (data1_layer.d00 << 16) + (data2_layer.d00 << 8)+ (data3_layer.d00)) // Multi_layer.fanIndegree
                Result.d01 =((data0_layer.d01 << 24) + (data1_layer.d01 << 16) + (data2_layer.d01 << 8) + (data3_layer.d01)) // Multi_layer.fanIndegree
                Result.d02 =((data0_layer.d02 << 24) + (data1_layer.d02 << 16) + (data2_layer.d02 << 8) + (data3_layer.d02)) // Multi_layer.fanIndegree
                Result.d03 =((data0_layer.d03 << 24) + (data1_layer.d03 << 16) + (data2_layer.d03 << 8) + (data3_layer.d03)) // Multi_layer.fanIndegree
                Result.d04 =((data0_layer.d04 << 24) + (data1_layer.d04 << 16) + (data2_layer.d04 << 8) + (data3_layer.d04)) // Multi_layer.fanIndegree

                # 构建IP层
                ip.dst_ip = "224.0.0.1"#组播地址
                ip.src_ip = "10.0.0.3"

                packet = ethernet / ip / udp / Multi_layer / Result

                print("Modified data packet:")
                packet.show()
                sendp(packet)
                # 触发停止事件以结束当前监听
                self.stop_event.set()
            elif Multi_layer.isACK == 1:
                sendp(packet)
            else:
                print("Aggregation not completed")

    def run(self):
        while True:
            self.stop_event.clear()  # 清除停止事件
            print("Listening...")
            sniff(iface=self.interface, filter="udp", prn=self.packet_callback,
                  stop_filter=lambda p: self.stop_event.is_set())
            print("Listening stopped, restarting...")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Using default interface\n")
        receiver1 = receiver()
    else:
        receiver1 = receiver(interface=sys.argv[1])
    receiver1.run()
