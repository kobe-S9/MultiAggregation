from scapy.all import *
from scapy.packet import Packet
from scapy.fields import BitField, IntField
import ast
import sys
import json
import random


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
        BitField("d00", 8),
        BitField("d01", 8),
        BitField("d02", 8),
        BitField("d03", 8)
    ]

bind_layers(UDP, multi)
bind_layers(multi, Data)

class sender(object):
    def __init__(self,src_ip,interface, bitmap,payload = [], src_port = 12345, dst_port = 12345,  dst_ip = "10.0.0.3"):
        self.src_ip = src_ip
        self.dst_ip = dst_ip
        self.src_port = src_port
        self.dst_port = dst_port
        self.payload = payload
        self.bitmap = bitmap
        
        dataArray = get_random_data_from_file("/home/yxy/MultiAggregation/dataArray.txt")
        dataArray = ast.literal_eval(dataArray)
        self.payload = dataArray
        
        self.interface = interface
    def send_udp_packet(self):
        # 构建以太网帧04
        ethernet = Ether( dst="08:00:00:00:03:33",type=0x0800)

        # 构建IP层
        ip = IP(src=self.src_ip, dst=self.dst_ip)
        # 构建UDP层
        udp = UDP(sport=self.src_port, dport=self.dst_port)

        # 构建Multi层
        Multi = multi(bitmap=self.bitmap)

        # 转换payload为列表
        #payload = ast.literal_eval(payload)

        # 构建data层
        data = Data(
            d00=self.payload[0],
            d01=self.payload[1],
            d02=self.payload[2],
            d03=self.payload[3]
        )

        #bytes(Multi)
        #bytes(data)
        # 构建完整的数据包
        packet = ethernet / ip / udp / Multi / data
        # 显示数据包内容
        packet.show()
        # 发送数据包
        sendp(packet)



    def run(self):
        self.send_udp_packet()
       
#随机获得梯度
def get_random_data_from_file(file_path):
    with open(file_path, 'r') as file:
        data_lines = file.readlines()
    data_lines = [line.strip() for line in data_lines if line.strip()]
    return random.choice(data_lines)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("请提供发送主机器的序号")
        sys.exit(1)
    bitmap = sys.argv[1]
    bitmap = ast.literal_eval(bitmap)
    if bitmap == 1:
        src_ip = "10.0.0.1"
        interface = "eth0"
    else:
        src_ip = "10.0.0.2"
        interface = "eth0"
    sender1 = sender(src_ip=src_ip,bitmap=bitmap,interface=interface)
    sender1.run()
