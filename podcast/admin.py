from django.contrib import admin
from .models import Episode


class EpisodeAdmin(admin.ModelAdmin):
    list_display = ("season", "number", "title")
    list_display_links = ("title",)
    prepopulated_fields = {"slug": ("title",)}


admin.site.register(Episode, EpisodeAdmin)
