from email.message import EmailMessage
import logging
import secrets
import smtplib
from django.db import models
from django.dispatch import receiver
from hamsterdance import settings


class Tag(models.Model):
    name = models.CharField(blank=False, max_length=128, unique=True)

    def __str__(self):
        return self.name


class Article(models.Model):
    title = models.CharField(blank=True, max_length=256)
    description = models.CharField(max_length=256)
    body = models.TextField(blank=False)
    slug = models.SlugField(max_length=32, unique=True)
    tags = models.ManyToManyField(Tag)
    published = models.DateTimeField(null=False)
    modified = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.slug


class Comment(models.Model):
    article = models.ForeignKey(Article, on_delete=models.CASCADE)
    body = models.CharField(blank=False, max_length=5096)
    name = models.CharField(blank=True, max_length=256)
    approved = models.BooleanField(default=False)
    token = models.CharField(blank=False, max_length=256, default=secrets.token_urlsafe)
    created = models.DateTimeField(auto_now_add=True)


@receiver(models.signals.post_save, sender=Comment)
def email_on_comment(sender, instance, created, **kwargs):
    if (not created) or instance.approved:
        return
    msg = EmailMessage()
    msg["From"] = f"{settings.HOST_DOMAIN} <no-reply@{settings.HOST_DOMAIN}>"
    msg["To"] = "Dominique Cyprès <lunasspecto@hamster.dance>"
    msg["Subject"] = "New comment awaiting approval"
    msg.set_content(
        "Someone has left a comment on a blog article.\n"
        f"article: {instance.article.title}\n"
        f"name: {instance.name}\n"
        f"body: {instance.body}\n\n"
        "To approve this comment, visit\n"
        f"https://{settings.HOST_DOMAIN}/blog/approve-comment/{instance.id}/?token={instance.token}"
    )
    try:
        with smtplib.SMTP("localhost", 1025 if settings.DEBUG else 25) as smtp:
            smtp.send_message(msg)
    except Exception:
        log = logging.getLogger()
        log.warning(
            "Unable to send email notification of comment creation", exc_info=True
        )
