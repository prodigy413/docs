### Super Liner
https://github.com/github/super-linter

### Shellscript Lint
https://github.com/koalaman/shellcheck<br>

~~~
sudo apt install shellcheck
shellcheck xxx.sh
~~~

https://github.com/mvdan/sh<br>

~~~
sudo snap install shfmt

or

curl -sS https://webinstall.dev/shfmt | bash

or

go install mvdan.cc/sh/v3/cmd/shfmt@latest

shfmt -l -w xxxx.sh
~~~

### Python Lint
https://www.pylint.org/<br>

~~~
sudo apt-get install pylint
pylint xxx.py
~~~

https://flake8.pycqa.org/en/latest/<br>

~~~
python3 -m pip install flake8
flake8 xxxx.py
~~~

https://github.com/psf/black<br>

~~~
pip install git+git://github.com/psf/black
black xxxx.py
~~~

https://pypi.org/project/isort/<br>

~~~
pip3 install isort
isort xxxx.py
~~~
