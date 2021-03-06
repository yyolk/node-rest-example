REPORTER?=spec
DOCS=docs/*.md
HTMLDOCS=$(DOCS:.md=.html)
DIST=dist
ARCHIVE=$(DIST).tar.gz
REST_URL=http://localhost:8000
CERT=cert

all: build mongodb-start

build: lint

lint:
	@yeoman lint

docs: docs-coverage docs-tests docs-docco docs-dot

docs-tests: test-md $(patsubst %.md,%.html,$(wildcard docs/*.md))

docs-dot:
	@dot -T png -O docs/dot/*.dot
	@for file in docs/dot/*.dot.png; do mv $$file $${file%.dot.png}.png; done

docs-report: docs-dot
	@$(MAKE) -C docs/report

test-md:
	@$(MAKE) -s test REPORTER=markdown > docs/tests.md

docs-coverage:
	@rm -rf app-cov
	@jscoverage app app-cov
	@INNEBANDY_COV=1 $(MAKE) -s test REPORTER=html-cov > docs/coverage.html

%.html: %.md
	@cat docs/layout/head.html > $@
	@./node_modules/marked/bin/marked --gfm $< >> $@
	@cat docs/layout/foot.html >> $@

docs-docco:
	@cat app/*.js > docs/docco.js
	@./node_modules/docco/bin/docco docs/*.js
	@rm -f docs/docco.js

server:
	@./bin/server &

mongodb-start:
	@if [[ -z `ps -A | grep mongod` ]]; then \
		echo 'MongoDB is not running'; \
		if [[ -z `which mongod` ]]; then \
			echo 'MongoDB is not installed!'; \
			sudo apt-get install mongodb \
				&& sudo service mongodb start \
				&& echo "MongoDB is now running!"; \
		else \
			sudo service mongodb start && echo "MongoDB is now running!"; \
		fi \
	fi

install: build mongodb-start server

clean:
	@rm -rf app-cov *.tar.gz
	@$(MAKE) -C docs/report clean

package: docs clean
	@tar czf package.tar.gz --exclude=.git ./*

test: test-spec

test-spec:
	@./node_modules/.bin/mocha \
			--timeout 2000 \
			--reporter $(REPORTER) \
			test/*.js

test-all: lint
	@$(MAKE) test REPORTER=dot

.PHONY: test test-all test-spec mongodb-start docs clean package
