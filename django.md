### Getting started
https://docs.djangoproject.com/en/4.0/intro/<br>
https://docs.djangoproject.com/en/4.0/intro/tutorial01/<br>

### samples
- views.py
~~~python
from django.http import HttpResponse

def index(request):
    name = request.GET.get("name") or "world"
    return HttpResponse(f"<h1>Hello, {name}!!</h1>")
~~~

~~~
http://127.0.0.1:8000?name=Obi
~~~

~~~
xxx.GET["name"]
xxx.GET.get("name")
xxx.GET.getlist("name")
~~~

- settings

~~~python
from django.conf import settings

if settings.DEBUG:
    do_some_logging()
~~~
