CC = aarch64-linux-gnu-g++
CXXFLAGS = -std=c++11
SRC = circular_sector.cpp ellipse.cpp main.cpp sort.cpp triangle.cpp
OBJ = $(SRC:.cpp=.o)
TARGET = main

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CXXFLAGS) -o $@ $(OBJ)

%.o: %.cpp
	$(CC) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)