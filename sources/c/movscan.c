/** movscan.c:
 ***********************************************************************
 *	Simple code generates SIGUSR1 signal to raspistill job when
 *        faling edge occures on defined digital input
 *      It is part of my movie scan project:
 *        (http://butyi.mooo.com/redmine/projects/mfd)
 *
 * Copyright (c) 2013-2014 Janos Bencsik. <moveiscan@butyi.hu>  www.butyi.hu
 ***********************************************************************
 *
 ***********************************************************************
 */

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wiringPi.h>

// Input Pin - wiringPi pin 0 is BCM_GPIO 17.
#define	TRIGGER	0

int main (void)
{
  int i,p,edgenum;

  char buf[512];
  FILE *cmd_pipe = popen("pidof -s raspistill", "r");
  fgets(buf, 512, cmd_pipe);
  pid_t pid = strtoul(buf, NULL, 10);

  i=p=edgenum=0;
  printf ("SIGUSR1 signal sender at rising edge digital input %d\n",TRIGGER);

  if((int)pid <= 0){
    printf("WARNING! raspistill is not running to get PID of that!\nSIGUSR1 will not be sent.\n");
  }

  wiringPiSetup () ;
  pinMode (TRIGGER, INPUT) ;

  for (;;)
  {
    i=digitalRead (TRIGGER);
    if( i==0 && p==1 ){
      edgenum++;
      printf("Faling edges %d\n",edgenum);
      if((int)pid > 0){
        kill(pid,SIGUSR1);
      }
      delay(20);
    }
    p=i;
  }
  return 0 ;
}
