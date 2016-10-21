VIRTUALENV = .venv
WORKON = $(VIRTUALENV)/bin/activate
VENV_COMMAND := $(shell which virtualenv 2>/dev/null)
DOC_FORMAT := html

all : install
all-venv : install-venv

# Configure virtualenv for this project.
$(VIRTUALENV) :
ifdef VENV_COMMAND
	$(VENV_COMMAND) -p python3 $(VIRTUALENV)
else
	$(error "Virtualenv is required but not installed.\
	Try: sudo pip install virtualenv")
endif

# Install
.PHONY: install
install:
	pip install numpy
	pip install -e .[dev]
	pip install git+https://github.com/dask/dask.git
	pip install git+https://github.com/dask/distributed.git
	pip install python-hostlist
	pip install jupyter

# Install into a virtual environment
.PHONY: install-venv
install-venv: $(VIRTUALENV)
	. $(WORKON)
	pip install numpy
	pip install -e .[dev]
	pip install git+https://github.com/dask/dask.git
	pip install git+https://github.com/dask/distributed.git
	pip install python-hostlist
	pip install jupyter

.PHONY: clean-venv
clean-venv:
	rm -rf .venv

.PHONY: clean
clean: clean-venv
