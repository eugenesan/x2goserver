#!/usr/bin/make -f

%:
	cd x2goserver && make $@
	cd x2goserver-extras && make $@
