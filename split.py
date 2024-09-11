import json
import random

def split_32bit_to_8bit(hex_value):
    # 将32-bit的十六进制数转换为整数
    num = int(hex_value, 16)
    # 通过位移操作切分成4个8-bit的整数，并格式化为十六进制字符串
    return [f'0x{(num >> (24 - i * 8)) & 0xFF:02x}' for i in range(4)]

def process_random_vector_group(data):
    # 随机选择一个向量组
    random_group = random.choice(data)
    print(random_group)
    # 处理选中的向量组
    result = []
    for hex_value in random_group:
        # 将每个32-bit的十六进制数切分成4个8-bit的整数
        bytes_8bit = split_32bit_to_8bit(hex_value)
        result.append(bytes_8bit)
    return result

def main():
    # 从JSON文件中读取数据
    with open('gradients.json', 'r') as file:
        data = json.load(file)

    # 处理数据
    processed_result = process_random_vector_group(data)
    
    # 打印结果
    for item in processed_result:
        print(item)

if __name__ == "__main__":
    main()
