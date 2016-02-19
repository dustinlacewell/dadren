docs:
	rm -fr ./gh_pages
	mkdir ./gh_pages
	cd dadren && find . -name '*.nim' -exec nim --index:on -p=.. doc2 '{}' \;
	cd dadren && nim buildIndex .
	mv dadren/*.html gh_pages
	rm dadren/*.idx
	cd docs && nim rst2html index.rst
	mv docs/*.html gh_pages

deploy:
	cd gh_pages && rm -fr .git
	cd gh_pages && git init
	cd gh_pages && git remote add origin "git@github.com:dadren/dadren.github.io.git"
	cd gh_pages && git add ./* && git commit -am "Automatic commit"
	cd gh_pages && git push --force origin master

.PHONY: docs deploy
