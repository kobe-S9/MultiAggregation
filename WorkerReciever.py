from scapy.all import *
from scapy.packet import Packet
from scapy.fields import BitField, IntField
import sys
import threading


class multi(Packet):
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

class Data(Packet):
    name = "data"
    fields_desc = [
        BitField("d00",0,8),
        BitField("d01",0,8),
        BitField("d02",0,8),
        BitField("d03",0,8),
        BitField("d04",0,8)
    ]
bind_layers(UDP, multi)
bind_layers(multi, Data)

class receiver(object):
    def __init__(self, interface="eth0"):
        self.interface = interface
        self.stop_event = threading.Event()  # 用于停止监听

    def packet_callback(self, packet):
        if packet.haslayer(multi):
            data_layer = packet.getlayer(Data)
            data_layer.d00 = data_layer.d00 / 10000000.0
            data_layer.d01 = data_layer.d01 / 10000000.0
            data_layer.d02 = data_layer.d02 / 10000000.0
            data_layer.d03 = data_layer.d03 / 10000000.0
            print("Received Multi packet:")
            packet.show()
      

    def run(self):
        while True:
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
