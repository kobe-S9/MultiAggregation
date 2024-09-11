from scapy.all import *
from scapy.packet import Packet
from scapy.fields import BitField, IntField
import sys
import threading

class multi(Packet):
    name = "Multi"
    fields_desc = [
        IntField("bitmap", 0),
        BitField("overflow", 0, 1),
        BitField("isResend", 0, 1),
        BitField("ECN", 0, 1),
        BitField("types", 0, 4),
        BitField("isACK", 0, 1),
        IntField("index", 0)
    ]


class Data(Packet):
    name = "data"
    fields_desc = [
        IntField("d00", 0),
        IntField("d01", 0),
        IntField("d02", 0),
        IntField("d03", 0)
    ]

bind_layers(UDP, multi)
bind_layers(multi, Data)

class receiver(object):
    def __init__(self, interface="eth0"):
        self.interface = interface
        self.stop_event = threading.Event()  # 用于停止监听

    def packet_callback(self, packet):
        if packet.haslayer(multi):
            print("Received Multi packet:")
            packet.show()
            multi_layer = packet.getlayer(multi)
            data_layer = packet.getlayer(Data)
            if multi_layer.bitmap == 3:
                data_layer.d00 = data_layer.d00 // 2
                data_layer.d01 = data_layer.d01 // 2
                data_layer.d02 = data_layer.d02 // 2
                data_layer.d03 = data_layer.d03 // 2
                multi_layer.isACK = 1
                print("Modified Data packet:")
                packet.show()
                sendp(packet)
                # 触发停止事件以结束当前监听
                self.stop_event.set()
            else:
                print("Aggregation not completed")
      

    def run(self):
        while True:
            self.stop_event.clear()  # 清除停止事件
            print("Listening...")
            sniff(iface=self.interface, filter="udp", prn=self.packet_callback, stop_filter=lambda p: self.stop_event.is_set())
            print("Listening stopped, restarting...")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Using default interface\n")
        receiver1 = receiver()
    else:
        receiver1 = receiver(interface=sys.argv[1])
    receiver1.run()
