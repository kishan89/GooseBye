#include <iostream>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <time.h>
#include <string>
using namespace std;

//int gooseLocation = 0;
bool geese = true;
char droneCommand[5] = "0000";
char lastMSG[5] =  "0000";

void error(char *msg)
{
    perror(msg);
    exit(1);
}

void startServer(int portNum)
{		
     unsigned int sockfd, newsockfd, portno, clilen;
     char buffer[5];
     struct sockaddr_in serv_addr, cli_addr;
     int n;
     if (portNum < 2) {
         fprintf(stderr,"ERROR, no port provided\n");
         exit(1);
     }
	
		 sockfd = socket(AF_INET, SOCK_STREAM, 0);
		 if (sockfd < 0) 
		    cout << ("ERROR opening socket") << endl;
		 bzero((char *) &serv_addr, sizeof(serv_addr));
		 portno = portNum;
		 serv_addr.sin_family = AF_INET;
		 serv_addr.sin_addr.s_addr = INADDR_ANY;
		 serv_addr.sin_port = htons(portno);
		 
		 if (bind(sockfd, (struct sockaddr *) &serv_addr,
		          sizeof(serv_addr)) < 0) 
		          cout << ("ERROR on binding") << endl;
	while(1)
	{	 
	      	
		 listen(sockfd,5);
		 clilen = sizeof(cli_addr);
		 newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
		
		 if (newsockfd < 0) 
		      cout << ("ERROR on accept") << endl;
		 bzero(buffer,5);
		 
		write(newsockfd,lastMSG,4);
		
		//for testing: it generates a 4 bit binary number indicating where geese are on the field(example: 0101 means that geese are on the second and forth quadrant) 
		for(int i = 0;i<5;i++)
		{
			int s = rand()%2;
			char aChar = '0' + s;
			droneCommand[i] = aChar;
			//cout << where2Go[i]<< endl;
		}
		
		if(geese) 
    		{
			write(newsockfd,lastMSG,4);
    			//write(newsockfd,droneCommand,4);
			//write(newsockfd,where2Go,4);
   		 } 
   		 
		 if (n < 0) cout << ("ERROR writing to socket") << endl;
		
		
		 n = read(newsockfd,buffer,4);
		for(int i=0; i < 5; i++)
		{
			lastMSG[i] = buffer[i];
		}
		
		 if (n < 0) cout << ("ERROR reading from socket") << endl;
		printf("Message from iPhone: %s\n",buffer);
     }
}

int main(int argc, char *argv[])
{
	int portNumber = atoi(argv[1]);
	startServer(portNumber);

	return 0; 
}
