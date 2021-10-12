# client.py

from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, wait, ALL_COMPLETED
import socket
import random
import time

# Global Data
host = '127.0.0.1'
port = 11111
nameList = ['Jack', 'Tom', 'Jerry']


# Func
def SendMsg(skt,myName):
	skt.send(myName.encode('utf-8'))

def RecvMsg(skt):
	recvmsg = skt.recv(1024).decode('utf-8')	# 最多接收1024B数据
	# print(recvmsg)
	return recvmsg

def ThreadTask(myName="Jack"):
	serverSkt = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	serverSkt.connect((host,port))
	SendMsg(serverSkt,myName)
	RecvMsg(serverSkt)
	serverSkt.close()

def main(threadNum=5):
	pool = ThreadPoolExecutor(threadNum)

	# start
	startTime = datetime.utcnow()
	
	allTask = [pool.submit(ThreadTask,random.choice(nameList)+str(i)) for i in range(threadNum)]

	wait(allTask, return_when=ALL_COMPLETED)
	#end
	endTime = datetime.utcnow()
	runTime = (endTime-startTime).microseconds
	print("总响应时间：",runTime,"ms")
	print("平均每请求响应时间：",runTime/threadNum,"ms")

if __name__ == '__main__':
	for i in range(1,21):
		print(i,": ")
		main(i)
		time.sleep(i+1)
		print()
