# Paths definitions (without quotes in variables)
WIN_SDK_VERSION = 10.0.26100.0
WIN_SDK_PATH = C:\Program Files (x86)\Windows Kits\10
VS_PATH = C:\Program Files (x86)\Microsoft Visual Studio\2017\Community
VS_TOOLS_PATH = $(VS_PATH)\VC\Tools\MSVC\14.16.27023
JAVA_PATH = C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot

# Compiler and linker (with quotes)
CL = "$(VS_TOOLS_PATH)\bin\Hostx64\x64\cl.exe"
LINK = "$(VS_TOOLS_PATH)\bin\Hostx64\x64\link.exe"

# Include paths (with quotes in the definitions)
INCLUDES = -I"$(WIN_SDK_PATH)\Include\$(WIN_SDK_VERSION)\ucrt" \
          -I"$(WIN_SDK_PATH)\Include\$(WIN_SDK_VERSION)\um" \
          -I"$(WIN_SDK_PATH)\Include\$(WIN_SDK_VERSION)\shared" \
          -I"$(WIN_SDK_PATH)\Include\$(WIN_SDK_VERSION)\winrt" \
          -I"$(VS_TOOLS_PATH)\include" \
          -I"../src/include" \
          -I"../src" \
          -I"$(JAVA_PATH)\include" \
          -I"$(JAVA_PATH)\include\win32"

# SWIG include paths
SWIG_INCLUDES = -I../src/include -I../src

# Library paths (with quotes in the definitions)
LIB_PATHS = /LIBPATH:"$(WIN_SDK_PATH)\Lib\$(WIN_SDK_VERSION)\ucrt\x64" \
            /LIBPATH:"$(WIN_SDK_PATH)\Lib\$(WIN_SDK_VERSION)\um\x64" \
            /LIBPATH:"$(VS_TOOLS_PATH)\lib\x64"

# Standard Windows libraries
WIN_LIBS = kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib \
           advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib \
           odbc32.lib odbccp32.lib ws2_32.lib msvcrt.lib \
           libvcruntime.lib libucrt.lib

# Compiler flags
CFLAGS = /c /EHsc /DWIN32 /O2 /MD /I"../src/include" /I"../src"

# Java related variables
CLASSES = org/freeswitch/esl/*

# Default target
all: setup esl.jar

# Generate wrapper from SWIG interface
esl_wrap.cpp: 
	swig -module esl -java -c++ $(SWIG_INCLUDES) -package org.freeswitch.esl -outdir org/freeswitch/esl -o esl_wrap.cpp ../ESL.i

# Compile wrapper and cJSON
esl_wrap.obj: esl_wrap.cpp
	$(CL) $(CFLAGS) $(INCLUDES) esl_wrap.cpp

cJSON.obj: ../src/cJSON.c
	$(CL) $(CFLAGS) /TC ../src/cJSON.c

cJSON_Utils.obj: ../src/cJSON_Utils.c
	$(CL) $(CFLAGS) /TC ../src/cJSON_Utils.c

# Link DLL
libesljni.dll: esl_wrap.obj cJSON.obj cJSON_Utils.obj
	$(LINK) /DLL /OUT:libesljni.dll /VERBOSE:LIB $(LIB_PATHS) \
	esl_wrap.obj cJSON.obj cJSON_Utils.obj "$(MAKEDIR)\libesl.lib" $(WIN_LIBS) \
	/RELEASE /INCLUDE:??0ESLevent@@QEAA@PEBD0@Z \
	/NODEFAULTLIB:libcmt.lib /FORCE:MULTIPLE

# Create JAR file
esl.jar: libesljni.dll
	javac -sourcepath org -d classes $(CLASSES)
	jar cf esl.jar -C classes org

# Clean target
clean:
	-del /Q esl_wrap.cpp esl_wrap.obj cJSON.obj cJSON_Utils.obj libesljni.dll esl.jar 2>nul
	-del /Q org\freeswitch\esl\*.java 2>nul
	-del /Q org\freeswitch\esl\*.class 2>nul
	-rmdir /S /Q classes 2>nul
	-rmdir /S /Q org\freeswitch\esl 2>nul
	-rmdir /S /Q org\freeswitch 2>nul
	-rmdir /S /Q org 2>nul

# Create necessary directories
setup:
	-mkdir classes 2>nul
	-mkdir org\freeswitch\esl 2>nul

.PHONY: all clean setup
