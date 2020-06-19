CXX = g++
CXXFLAGS = -Wall -Werror -Wextra -lboost_system -pthread -pedantic -std=c++17 -g
LDFLAGS =  -fsanitize=address

SRC = *.cpp
OBJ = $(SRC:.cc=.o)
EXEC = aisrelay

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $(OBJ) $(LBLIBS)

clean:
	rm -rf $(EXEC)