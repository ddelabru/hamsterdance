from django.db import models


class Episode(models.Model):
    season = models.IntegerField()
    number = models.IntegerField()
    title = models.CharField(max_length=256)
    audio_url = models.CharField(max_length=256)
    description = models.CharField(max_length=256)
    published = models.DateTimeField(null=False)
    slug = models.SlugField(max_length=32, unique=True)
    transcript = models.TextField(blank=False)

    class Meta:
        ordering = ("-season", "-number")

    def __str__(self):
        return self.slug
