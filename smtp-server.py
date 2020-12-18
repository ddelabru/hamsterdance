# Helper script to run a dummy SMTP server on port 1025

import asyncore
import smtpd

server = smtpd.DebuggingServer(("localhost", 1025), None)
asyncore.loop()
