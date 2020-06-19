CXX = g++
CXXFLAGS = -Wall -Werror -Wextra -lboost_thread -pthread -std=c++17 -ggdb3 -fsanitize=address
LDFLAGS =  -fsanitize=address

SRC = *.cpp
OBJ = $(SRC:.cc=.o)
EXEC = aisrelay

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJ) $(LBLIBS)

clean:
	rm -rf $(OBJ) $(EXEC)