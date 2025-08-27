.PHONY: test
test: test_vim test_nvim

.PHONY: test_vim
test_vim:
	./test/run.sh

.PHONY: test_nvim
test_nvim:
	THEMIS_VIM=$(shell which nvim) ./test/run.sh
