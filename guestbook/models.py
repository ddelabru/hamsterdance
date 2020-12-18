from email.message import EmailMessage
import logging
import smtplib
from django.db import models
from django.dispatch import receiver
from hamsterdance import settings


class Entry(models.Model):
    message = models.CharField(blank=False, max_length=1024)
    name = models.CharField(blank=True, max_length=256)
    date = models.DateTimeField(auto_now_add=True)


@receiver(models.signals.post_save, sender=Entry)
def email_on_signing(sender, instance, created, **kwargs):
    if not created:
        return
    msg = EmailMessage()
    msg["From"] = f"{settings.HOST_DOMAIN} <no-reply@{settings.HOST_DOMAIN}>"
    msg["To"] = "Dominique Cyprès <lunasspecto@hamster.dance>"
    msg["Subject"] = "New guestbook entry"
    msg.set_content(
        "Someone has signed the guestbook.\n"
        f"name: {instance.name}\n"
        f"message: {instance.message}"
    )
    try:
        with smtplib.SMTP("localhost", 1025 if settings.DEBUG else 25) as smtp:
            smtp.send_message(msg)
    except Exception:
        log = logging.getLogger()
        log.warning(
            "Unable to send email notification of comment creation", exc_info=True
        )
