CPPCHECKFLAGS = --enable=all --inconclusive --std=posix --std=c++14 --platform=unspecified --error-exitcode=1 --quiet
CXXFLAGS = -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror

OLD_VERS = 1.14.2 1.12.2 1.10.3 1.8.1 1.6.3 1.4.7 1.2.9 1.0.15
NEW_VERS = 1.16.0 1.15.12
ALL_VERS = $(NEW_VERS) $(OLD_VERS)

CHECK_VERS = $(NEW_VERS)
LINT_VERS = $(ALL_VERS)
TEST_VERS = $(ALL_VERS)
BUILD_VERS = $(NEW_VERS)

nginx-%.tar.gz.asc ::
	curl -LO https://nginx.org/download/nginx-$*.tar.gz.asc

nginx-%.tar.gz: nginx-%.tar.gz.asc
	curl -LO https://nginx.org/download/nginx-$*.tar.gz
	gpg --verify nginx-$*.tar.gz.asc 2>&1 | tee /dev/stderr | grep --quiet "gpg: Good signature from \"Maxim Dounin <mdounin@mdounin.ru>\""

nginx-%/Makefile: nginx-%.tar.gz
	tar zxf nginx-$*.tar.gz
	touch nginx-$*/Makefile

nginx-%/objs/Makefile: nginx-%/Makefile
	cd nginx-$* && \
	if bash ../vercmp.bash $* 1.10.0; then \
		./configure --with-cc-opt=-Wno-error --add-module=..; \
	elif bash ../vercmp.bash $* 1.12.0; then \
		./configure --with-cc-opt=-Wno-error --add-dynamic-module=..; \
	else \
		./configure --with-cc-opt=-Wno-error --add-dynamic-module=.. --with-compat; \
	fi
	touch nginx-$*/objs/Makefile

download-%: nginx-%/Makefile ;

configure-%: download-% nginx-%/objs/Makefile ;

nginx-%-uaparser-module.so: configure-%
	@if bash ./vercmp.bash $* 1.10.0; then \
		echo -e \\nerror: nginx before version 1.10 does not support dynamic modules\\n; \
		false; \
	fi
	cd nginx-$* && make modules
	cp nginx-$*/objs/ngx_http_uaparser_module.so nginx-$*-uaparser-module.so

nginx-%-bin: configure-%
	cd nginx-$* && make build
	cp nginx-$*/objs/nginx nginx-$*-bin

lint-cppcheck:
	cppcheck ngx_http_uaparser_module.cpp $(CPPCHECKFLAGS)

lint-eclint:
	eclint check

lint-clang-%: configure-%
	clang++ -o /dev/null -c ngx_http_uaparser_module.cpp $(CXXFLAGS) $(addprefix -Inginx-$*/,src/core src/event src/event/modules src/os/unix src/http src/http src/http/modules objs)

lint-gcc-%: configure-%
	gcc -o /dev/null -c ngx_http_uaparser_module.cpp $(CXXFLAGS) $(addprefix -Inginx-$*/,src/core src/event src/event/modules src/os/unix src/http src/http src/http/modules objs)

lint-%: lint-eclint lint-cppcheck lint-gcc-% lint-clang-% ;

lint-clang: $(addprefix download-,$(LINT_VERS)) $(addprefix configure-,$(LINT_VERS)) $(addprefix lint-clang-,$(LINT_VERS)) ;

lint-gcc: $(addprefix download-,$(LINT_VERS)) $(addprefix configure-,$(LINT_VERS)) $(addprefix lint-gcc-,$(LINT_VERS)) ;

lint: lint-eclint lint-cppcheck lint-clang lint-gcc ;

quick-lint-clang: $(addprefix download-,$(CHECK_VERS)) $(addprefix configure-,$(CHECK_VERS)) $(addprefix lint-clang-,$(CHECK_VERS)) ;

quick-lint-gcc: $(addprefix download-,$(CHECK_VERS)) $(addprefix configure-,$(CHECK_VERS)) $(addprefix lint-gcc-,$(CHECK_VERS)) ;

quick-lint: lint-eclint lint-cppcheck $(addprefix download-,$(CHECK_VERS)) $(addprefix configure-,$(CHECK_VERS)) $(addprefix lint-,$(CHECK_VERS)) ;

test-%: nginx-%-bin ;

test: $(addprefix download-,$(TEST_VERS)) $(addprefix configure-,$(TEST_VERS)) $(addsuffix -bin,$(addprefix nginx-,$(TEST_VERS))) $(addprefix test-,$(TEST_VERS)) ;

build-%: nginx-%-uaparser-module.so ;

build: $(addprefix download-,$(BUILD_VERS)) $(addprefix configure-,$(TEST_VERS)) $(addsuffix -bin,$(addprefix nginx-,$(TEST_VERS))) $(addprefix build-,$(BUILD_VERS)) ;

.PRECIOUS: nginx-%/Makefile nginx-%/objs/Makefile nginx-%-uaparser-module.so nginx-%-bin nginx-%.tar.gz nginx-%.tar.gz.asc ;
