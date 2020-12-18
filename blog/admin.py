from django.contrib import admin
from .models import Article, Comment, Tag


class ArticleAdmin(admin.ModelAdmin):
    list_display = ("title", "published")
    ordering = ("-published", "title")
    prepopulated_fields = {"slug": ("title",)}


class TagAdmin(admin.ModelAdmin):
    list_display = ("name",)


class CommentAdmin(admin.ModelAdmin):
    list_display = ("article", "created")
    ordering = ("-created",)


admin.site.register(Article, ArticleAdmin)
admin.site.register(Tag, TagAdmin)
admin.site.register(Comment, CommentAdmin)
