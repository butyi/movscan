#!/usr/bin/python
import os, re
import sys
import smtplib
 
#from email.mime.image import MIMEImage
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.MIMEText import MIMEText

 
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587

 
sender = sys.argv[1]
password = sys.argv[2]
recipient = 'butyi.hu@gmail.com; movscan@butyi.hu'
subject = 'MovScan report'
message = 'Hello,\n'\
          '\n'\
          'The MovScan has been digitalized a new cine film: '+sys.argv[3]+'\n'\
          'The film has been uploaded to YouTube, but it is most probable still in processing by YouTube.\n'\
          'Link to the film: '+sys.argv[4]+'\n'\
          'Enjoy! :-)\n'\
          '\n'\
          'Butyi\n'\
          'https://github.com/butyi/movscan/wiki/Movie-Scanner\n'\
          'http://butyi.hu'
 
def main():
    msg = MIMEMultipart()
    msg['Subject'] = subject
    msg['To'] = recipient
    msg['From'] = sender
    
    
    part = MIMEText('text', "plain")
    part.set_payload(message)
    msg.attach(part)
    
    session = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
 
    session.ehlo()
    session.starttls()
    session.ehlo
    
    session.login(sender, password)

    qwertyuiop = msg.as_string()

    session.sendmail(sender, recipient, qwertyuiop)
    
    session.quit()
    print "Email has been sent."
 
if __name__ == '__main__':
    main()
