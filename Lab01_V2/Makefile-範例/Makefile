# 範例格式 可以自行撰寫Makefile
CXX=g++
CXXFLAGS=-std=c++11
OBJ=hellofuc.o hellomake.o
SRC=hellofuc.cpp hellomake.cpp
EXE=hellomake
all:$(EXE)
$(EXE):$(OBJ)
	$(CXX) -o $@ $(OBJ)
$(OBJ):$(SRC)
	$(CXX) $(CXXFLAGS) -c $(SRC)
clean:
	rm -f $(EXE)
	rm -f $(OBJ)