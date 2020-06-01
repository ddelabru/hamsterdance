from django.http import HttpResponseRedirect
from django.shortcuts import render
from .models import Entry

# Create your views here.
def index(request):
    return render(
        request,
        "guestbook/index.html",
        {"guestbook_entries": Entry.objects.order_by("-date")},
    )


def submit(request):
    if request.POST["spam"] == "0":
        Entry.objects.create(message=request.POST["message"], name=request.POST["name"])
    return HttpResponseRedirect("../")
