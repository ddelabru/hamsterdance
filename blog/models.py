from datetime import datetime

from django.db import models


class Tag(models.Model):
    name = models.CharField(blank=False, max_length=128, unique=True)

    def __str__(self):
        return self.name


class Article(models.Model):
    title = models.CharField(blank=True, max_length=256)
    body = models.TextField(blank=False)
    slug = models.SlugField(max_length=32, unique=True)
    tags = models.ManyToManyField(Tag)
    published = models.DateTimeField(default=datetime.now)
    modified = models.DateTimeField(auto_now=True)

    def __str__(self):
        if self.title:
            return self.slug
