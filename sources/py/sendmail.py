#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright: BENCSIK Janos <copyright@butyi.hu>
# License : WTFPL v2 <http://www.wtfpl.net/txt/copying/>

# parameter 1: password from the gmail account
# parameter 2: name of video file (should be talkative)
# parameter 3: youtube link to video

import os, re
import sys
import smtplib
 
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.MIMEText import MIMEText

 
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587

 
sender = 'butyi.hu@gmail.com'
password = sys.argv[1]
recipient = 'butyi.hu@gmail.com'
subject = 'MovScan report'
message = 'Hello,\n'\
          '\n'\
          'The MovScan has digitalized a new cine film: '+sys.argv[2]+'\n'\
          'The film has been uploaded to YouTube, but it is most probable still in processing by YouTube.\n'\
          'Link to the film: '+sys.argv[3]+'\n'\
          '\n'\
          'Content:\n'+sys.argv[4]+'\n'\
          '\n'\
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
