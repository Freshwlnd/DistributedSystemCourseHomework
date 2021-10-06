# server.py

import socket

host = '127.0.0.1'
port = 11111

def RecvMsg(skt,addr):
	recvmsg = skt.recv(1024).decode('utf-8')	# 最多接收1024B数据
	print("Client地址：", addr, "\t名称：",recvmsg)
	return recvmsg

def SendMsg(skt,clientName):
	sendmsg = "连接成功！你好，"+str(clientName)+"！"
	skt.send(sendmsg.encode('utf-8'))

def main():
	skt = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	skt.bind((host,port))
	skt.listen(30)	# 最大连接数量为10，超过后排队
	while True:
		clientSkt,addr = skt.accept()
		recvmsg = RecvMsg(clientSkt,addr)
		SendMsg(clientSkt,recvmsg)
		clientSkt.close()

if __name__ == '__main__':
	main()
	