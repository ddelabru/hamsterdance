from django.contrib import admin
from .models import Entry


class EntryAdmin(admin.ModelAdmin):
    list_display = ("date", "name", "message")


admin.site.register(Entry, EntryAdmin)
