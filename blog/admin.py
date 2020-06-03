from django.contrib import admin
from .models import Article, Tag


class ArticleAdmin(admin.ModelAdmin):
    list_display = ("published", "title")
    prepopulated_fields = {"slug": ("published", "title")}


class TagAdmin(admin.ModelAdmin):
    list_display = ("name",)


admin.site.register(Article, ArticleAdmin)
admin.site.register(Tag, TagAdmin)
