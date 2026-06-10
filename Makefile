CXX ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall
INCLUDES := -Iinclude
TARGET := smus2midi
SRC := main.cpp

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)
