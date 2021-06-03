NAME = edge-impulse-standalone

CC ?= gcc
CXX ?= g++

CFLAGS += -Wall -g -DTF_LITE_DISABLE_X86_NEON=1 -Wno-strict-aliasing
CFLAGS += -DEIDSP_SIGNAL_C_FN_POINTER=1 -DEI_C_LINKAGE=1
CFLAGS += -I.
CFLAGS += -Os
CFLAGS += -DNDEBUG
CFLAGS += -g
CFLAGS += -fPIC
CXXFLAGS += -std=c++11
LDFLAGS += -lm -lstdc++

CSOURCES = edge-impulse-sdk/tensorflow/lite/c/common.c $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/BasicMathFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/FastMathFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/StatisticsFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*fft*.c) $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/CommonTables/*.c) $(wildcard edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*bit*.c)
CXXSOURCES = $(wildcard tflite-model/*.cpp) $(wildcard edge-impulse-sdk/dsp/kissfft/*.cpp) $(wildcard edge-impulse-sdk/dsp/dct/*.cpp) $(wildcard ./edge-impulse-sdk/dsp/memory.cpp) $(wildcard ./edge-impulse-sdk/classifier/*.cpp) $(wildcard edge-impulse-sdk/porting/posix/*.c*) $(wildcard edge-impulse-sdk/porting/mingw32/*.c*)
CCSOURCES = $(wildcard edge-impulse-sdk/tensorflow/lite/kernels/*.cc) $(wildcard edge-impulse-sdk/tensorflow/lite/kernels/internal/*.cc) $(wildcard edge-impulse-sdk/tensorflow/lite/micro/kernels/*.cc) $(wildcard edge-impulse-sdk/tensorflow/lite/micro/*.cc) $(wildcard edge-impulse-sdk/tensorflow/lite/micro/memory_planner/*.cc) $(wildcard edge-impulse-sdk/tensorflow/lite/core/api/*.cc)
APP_CSOURCES = $(wildcard source/*.c)

ifeq (${CMSIS_NN},1)
CFLAGS += -Wno-unknown-attributes
CFLAGS += -DEI_CLASSIFIER_TFLITE_ENABLE_CMSIS_NN=1 -D__ARM_FEATURE_DSP=1 -D__GNUC_PYTHON__=1
CFLAGS += -Iedge-impulse-sdk/CMSIS/NN/Include/
CFLAGS += -Iedge-impulse-sdk/CMSIS/DSP/PrivateInclude/
CSOURCES += $(wildcard edge-impulse-sdk/CMSIS/NN/Source/ActivationFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/BasicMathFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/ConcatenationFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/ConvolutionFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/FullyConnectedFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/NNSupportFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/PoolingFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/ReshapeFunctions/*.c) $(wildcard edge-impulse-sdk/CMSIS/NN/Source/SoftmaxFunctions/*.c)
endif

COBJECTS := $(patsubst %.c,%.o,$(CSOURCES))
CXXOBJECTS := $(patsubst %.cpp,%.o,$(CXXSOURCES))
CCOBJECTS := $(patsubst %.cc,%.o,$(CCSOURCES))
APP_COBJECTS = $(patsubst %.c,%.o,$(APP_CSOURCES))

ifeq ($(OS),Windows_NT)
	MKDIR_BUILD = if not exist build mkdir build
else
	MKDIR_BUILD = mkdir -p build
	LDFLAGS += -ldl
endif

all: app

.PHONY: app clean

$(COBJECTS) : %.o : %.c
$(CXXOBJECTS) : %.o : %.cpp
$(CCOBJECTS) : %.o : %.cc
$(APP_COBJECTS) : %.o : %.c

%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

%.o: %.cc
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $^ -o $@

%.o: %.cpp
	$(CXX) $(CFLAGS) $(CXXFLAGS) -c $^ -o $@

build/libedgeimpulse.so: $(COBJECTS) $(CXXOBJECTS) $(CCOBJECTS)
	$(MKDIR_BUILD)
	$(CXX) $(COBJECTS) $(CXXOBJECTS) $(CCOBJECTS) -shared -o build/libedgeimpulse.so $(LDFLAGS)

app: $(APP_COBJECTS) build/libedgeimpulse.so
	$(MKDIR_BUILD)
	$(CXX) $(APP_COBJECTS) build/libedgeimpulse.so -o build/$(NAME) $(LDFLAGS)

clean:
ifeq ($(OS),Windows_NT)
	del /Q $(subst /,\,$(patsubst %.c,%.o,$(CSOURCES))) >nul 2>&1 || exit 0
	del /Q $(subst /,\,$(patsubst %.cpp,%.o,$(CXXSOURCES))) >nul 2>&1 || exit 0
	del /Q $(subst /,\,$(patsubst %.cc,%.o,$(CCSOURCES))) >nul 2>&1 || exit 0
	del /Q $(subst /,\,$(patsubst %.c,%.o,$(APP_COBJECTS))) >nul 2>&1 || exit 0
	del /Q build\libedgeimpulse.so >nul 2>&1 || exit 0
else
	rm -f $(COBJECTS)
	rm -f $(CCOBJECTS)
	rm -f $(CXXOBJECTS)
	rm -f $(APP_COBJECTS)
	rm -f build/libedgeimpulse.so
endif
