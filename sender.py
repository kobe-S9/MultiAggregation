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

class sender(object):
    def __init__(self,src_ip,interface,types, bitmap,payload = [],fanIndegree = 2,index = 0,src_port = 12345, dst_port = 12345,  dst_ip = "10.0.0.3"):
        self.src_ip = src_ip
        self.dst_ip = dst_ip
        self.src_port = src_port
        self.dst_port = dst_port
        self.payload = payload
        self.bitmap = bitmap
        self.index = index
        self.types = types
        self.fanIndegree = fanIndegree
        self.interface = interface
        
    def send_udp_packet(self):
        # 构建以太网帧04
        ethernet = Ether( dst="08:00:00:00:03:33",type=0x0800)

        # 构建IP层
        ip = IP(src=self.src_ip, dst=self.dst_ip)
        # 构建UDP层
        udp = UDP(sport=self.src_port, dport=self.dst_port)

        # 构建Multi层
        
        Multi = multi(types = self.types,bitmap=self.bitmap,fanIndegree = self.fanIndegree)

        # 转换payload为列表
        #payload = ast.literal_eval(payload)

        # 构建data层
        data = Data(
            d00=self.payload[0],
            d01=self.payload[1],
            d02=self.payload[2],
            d03=self.payload[3],
            d04=self.payload[4]
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

def split_32bit_to_8bit(binary_random_group):
    """
    将32位二进制字符串的数组中的每个元素按每8位一组切割。

    :param binary_random_group: 包含32位二进制字符串的列表
    :return: 每个元素切割为8位的列表，形式为二维数组
    """
    result = []
    
    for binary_str in binary_random_group:
        # 按8位切割
        split_result = [binary_str[i:i+8] for i in range(0, len(binary_str), 8)]
        result.append(split_result)
    
    return result

def process_random_vector_group(data):
    # 随机选择一个向量组
    random_group = random.choice(data)
        # 处理选中的向量组
    factor = 1000000
    for i in range( len(random_group) ):
        random_group[i] = int(random_group[i] * factor)
    print(random_group)
    binary_random_group = [format(num, '032b') for num in random_group]
    print(binary_random_group)
    binary_8bit_array = split_32bit_to_8bit(binary_random_group)
    
    return binary_8bit_array   
    
def split():
    # 从JSON文件中读取数据
    with open('gradients.json', 'r') as file:
        gradients_json = json.load(file)

    # 处理数据
    split_8bit_2d_result = process_random_vector_group(gradients_json)
    print("split_8bit_2d_result",split_8bit_2d_result)
    int_2d_array = [[int(b, 2) for b in row] for row in split_8bit_2d_result]
    print("int_2d_array",int_2d_array)          
    return int_2d_array


def get_set_bits_positions(decimal_number):
    # Get binary representation of the number
    binary_representation = bin(decimal_number)[2:]
    print("binary_representation",binary_representation)
    # Find positions of '1's, and exclude position 0
    positions = [i for i, bit in enumerate(binary_representation) if bit == '1' and i != 0]
    print("positions",positions)

    return positions

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("请提供发送主机器的序号和最高位的types")
        sys.exit(1)
    bitmap = sys.argv[1]
    types = int(sys.argv[2])
    bitmap = ast.literal_eval(bitmap)
    split_result=split()
    ##需要发的序号组
    index = get_set_bits_positions(types)
    if bitmap == 1:
        src_ip = "10.0.0.1"
        interface = "eth0"
    else:
        src_ip = "10.0.0.2"
        interface = "eth0"

    payload= [row[0] for row in split_result]
    print("payload",payload)
    senderHigh = sender(payload = payload,types= types,index = 0,src_ip=src_ip,bitmap=bitmap,interface=interface)
    senderHigh.run()

    for item in index:
        print("item",item)
        payload= [row[item] for row in split_result]
        print("payload",payload)
        if(item == 3):
            types = 1
        if(item == 2):
            types = 2   
        if(item == 1):
            types = 4               
        sender1 = sender(payload = payload,types= types,index = 0,src_ip=src_ip,bitmap=bitmap,interface=interface)
        sender1.run()
