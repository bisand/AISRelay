CXX = g++
CXXFLAGS = -Wall -Werror -Wextra -lboost_system -pthread
LDFLAGS =  -fsanitize=address

SRC = *.cpp
OBJ = $(SRC:.cc=.o)
EXEC = aisrelay

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJ) $(LBLIBS)

clean:
	rm -rf $(OBJ) $(EXEC)
