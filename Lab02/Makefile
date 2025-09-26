CC = aarch64-linux-gnu-g++
CXXFLAGS = -std=c++11
SRC = GPIO.cpp
TARGET = GPIO

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CXXFLAGS) -o $@ $(SRC)

clean:
	rm -f $(TARGET)