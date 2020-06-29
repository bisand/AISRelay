CXX = g++
CXXFLAGS = -v -O3 -lboost_program_options -lboost_system -lboost_regex -pthread
LDFLAGS =

ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif
UNAME := $(shell uname)
ifeq ($(UNAME),Linux)
#Conditional for Linux
endif

SRC = *.cpp
OBJ = $(SRC:.cc=.o)
EXEC = aisrelay

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CXX) $(OBJ) $(LBLIBS) -o $@ $(CXXFLAGS) $(LDFLAGS)

clean:
	rm -rf $(EXEC)

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(DESTDIR)$(EXEC) "$(PREFIX)/bin/"
