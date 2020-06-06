FROM docker.io/python:3

COPY ./hamsterdance /opt/hamsterdance/hamsterdance
COPY ./blog /opt/hamsterdance/blog
COPY ./guestbook /opt/hamsterdance/guestbook
COPY ./manage.py /opt/hamsterdance/manage.py
COPY ./requirements.txt /opt/hamsterdance/requirements.txt

WORKDIR /opt/hamsterdance
RUN python -m pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["daphne","-b0.0.0.0","-p8000","hamsterdance.asgi:application"]
