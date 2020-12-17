from django.http import HttpResponseRedirect
from django.shortcuts import render
from .models import Entry


def index(request):
    return render(
        request,
        "guestbook/index.html",
        {"guestbook_entries": Entry.objects.order_by("-date")},
    )


def submit(request):
    if (
        request.method == "POST"
        and request.POST.get("spam", "1") == "0"
        and request.POST.get("message")
    ):
        Entry.objects.create(
            message=request.POST["message"], name=request.POST.get("name", "")
        )
    return HttpResponseRedirect("../")
