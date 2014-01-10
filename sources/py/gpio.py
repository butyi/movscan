import RPi.GPIO as GPIO ## Import GPIO library
GPIO.setmode(GPIO.BOARD) ## Use board pin numbering
GPIO.setup(11, GPIO.IN, pull_up_down=GPIO.PUD_UP) ## Setup GPIO Pin 11 to IN
while True:
  GPIO.wait_for_edge(11, GPIO.FALLING)
  GPIO.wait_for_edge(11, GPIO.RISING)
  print "RISING EDGE"
