CXX = g++
CXXFLAGS = -Wall -lboost_system -pthread
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
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $(OBJ) $(LBLIBS)

clean:
	rm -rf $(EXEC)

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(DESTDIR)$(EXEC) "$(PREFIX)/bin/"
