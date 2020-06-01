from django.db import models


class Entry(models.Model):
    message = models.CharField(blank=False, max_length=1024)
    name = models.CharField(blank=True, max_length=256)
    date = models.DateTimeField(auto_now_add=True)
