##/*************************************************************************************
##                           The MIT License
##
##   BWA-MEM2  (Sequence alignment using Burrows-Wheeler Transform),
##   Copyright (C) 2019  Vasimuddin Md, Sanchit Misra, Intel Corporation, Heng Li.
##
##   Permission is hereby granted, free of charge, to any person obtaining
##   a copy of this software and associated documentation files (the
##   "Software"), to deal in the Software without restriction, including
##   without limitation the rights to use, copy, modify, merge, publish,
##   distribute, sublicense, and/or sell copies of the Software, and to
##   permit persons to whom the Software is furnished to do so, subject to
##   the following conditions:
##
##   The above copyright notice and this permission notice shall be
##   included in all copies or substantial portions of the Software.
##
##   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
##   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
##   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
##   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
##   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##   SOFTWARE.
##
##Contacts: Vasimuddin Md <vasimuddin.md@intel.com>; Sanchit Misra <sanchit.misra@intel.com>;
##                                Heng Li <hli@jimmy.harvard.edu> 
##*****************************************************************************************/

EXE=		bwa-mem2
#CXX=		icpc
ARCH_FLAGS=	-msse4.1
SWA_FLAGS=	-DDEB=0 -DRDT=0 -DMAXI=0 -DNEW=1 -DSORT_PAIRS=0
MEM_FLAGS=	-DPAIRED_END=1 -DMAINY=0 -DSAIS=1
CPPFLAGS=	-DENABLE_PREFETCH $(MEM_FLAGS) $(SWA_FLAGS) 
LIBS=		-lpthread -lm -lz -L. -lbwa ##-lnuma
OBJS=		src/fastmap.o src/bwtindex.o src/utils.o src/kthread.o \
			src/kstring.o src/ksw.o src/bntseq.o src/bwamem.o src/profiling.o src/bandedSWA.o \
			src/FMI_search.o src/read_index_ele.o src/bwamem_pair.o src/kswv.o src/bwa.o \
			src/bwamem_extra.o src/bwtbuild.o
BWA_LIB=    libbwa.a

ifneq ($(portable),)
	LIBS+=-static-libgcc -static-libstdc++
endif

ifeq ($(arch),sse)
		ARCH_FLAGS=-msse4.1
else ifeq ($(arch),avx2)
	ifeq ($(CXX), icpc)
		ARCH_FLAGS=-xCORE-AVX2
	else	
		ARCH_FLAGS=-mavx2
	endif
else ifeq ($(arch),avx512)
	ifeq ($(CXX), icpc)
		ARCH_FLAGS=-xCORE-AVX512
	else	
		ARCH_FLAGS=-mavx512bw
	endif
else ifeq ($(arch),native)
	ARCH_FLAGS=-march=native
else
# To provide a different architecture flag like -march=core-avx2.
	ARCH_FLAGS=$(arch)
endif

CXXFLAGS=	-g -O3 -fpermissive $(ARCH_FLAGS) #-Wall ##-xSSE2

.PHONY:all clean depend multi
.SUFFIXES:.cpp .o

.cpp.o:
	$(CXX) -c $(CXXFLAGS) $(CPPFLAGS) $(INCLUDES) $< -o $@

all:$(EXE)

multi:
	rm -f src/*.o $(BWA_LIB); $(MAKE) arch=sse    EXE=bwa-mem2.sse41    CXX=$(CXX) all
	rm -f src/*.o $(BWA_LIB); $(MAKE) arch=avx2   EXE=bwa-mem2.avx2     CXX=$(CXX) all
	rm -f src/*.o $(BWA_LIB); $(MAKE) arch=avx512 EXE=bwa-mem2.avx512bw CXX=$(CXX) all
	$(CXX) -Wall -O3 src/runsimd.cpp -o bwa-mem2

$(EXE):$(BWA_LIB) src/main.o
	$(CXX) $(CXXFLAGS) $(BWA_LIB) src/main.o -o $@ $(LIBS)

$(BWA_LIB):$(OBJS)
	ar rcs $(BWA_LIB) $(OBJS)

clean:
	rm -fr src/*.o $(BWA_LIB) $(EXE) bwa-mem2.sse41 bwa-mem2.avx2 bwa-mem2.avx512bw

depend:
	(LC_ALL=C; export LC_ALL; makedepend -Y -- $(CXXFLAGS) $(CPPFLAGS) -I. -- src/*.cpp)

# DO NOT DELETE

src/FMI_search.o: src/FMI_search.h src/bntseq.h src/read_index_ele.h
src/FMI_search.o: src/utils.h src/macro.h src/bwa.h src/bwt.h
src/bandedSWA.o: src/bandedSWA.h src/macro.h
src/bntseq.o: src/bntseq.h src/utils.h src/macro.h src/kseq.h src/khash.h
src/bwa.o: src/bntseq.h src/bwa.h src/bwt.h src/macro.h src/ksw.h src/utils.h
src/bwa.o: src/kstring.h src/kvec.h src/kseq.h
src/bwamem.o: src/bwamem.h src/bwt.h src/bntseq.h src/bwa.h src/macro.h
src/bwamem.o: src/kthread.h src/bandedSWA.h src/kstring.h src/ksw.h
src/bwamem.o: src/kvec.h src/ksort.h src/utils.h src/profiling.h
src/bwamem.o: src/FMI_search.h src/read_index_ele.h src/kbtree.h
src/bwamem_extra.o: src/bwa.h src/bntseq.h src/bwt.h src/macro.h src/bwamem.h
src/bwamem_extra.o: src/kthread.h src/bandedSWA.h src/kstring.h src/ksw.h
src/bwamem_extra.o: src/kvec.h src/ksort.h src/utils.h src/profiling.h
src/bwamem_extra.o: src/FMI_search.h src/read_index_ele.h
src/bwamem_pair.o: src/kstring.h src/bwamem.h src/bwt.h src/bntseq.h
src/bwamem_pair.o: src/bwa.h src/macro.h src/kthread.h src/bandedSWA.h
src/bwamem_pair.o: src/ksw.h src/kvec.h src/ksort.h src/utils.h
src/bwamem_pair.o: src/profiling.h src/FMI_search.h src/read_index_ele.h
src/bwamem_pair.o: src/kswv.h
src/bwtbuild.o: src/sais.h src/utils.h src/bntseq.h
src/bwtindex.o: src/bntseq.h src/bwa.h src/bwt.h src/macro.h src/utils.h
src/bwtindex.o: src/bwtbuild.h
src/fastmap.o: src/fastmap.h src/bwa.h src/bntseq.h src/bwt.h src/macro.h
src/fastmap.o: src/bwamem.h src/kthread.h src/bandedSWA.h src/kstring.h
src/fastmap.o: src/ksw.h src/kvec.h src/ksort.h src/utils.h src/profiling.h
src/fastmap.o: src/FMI_search.h src/read_index_ele.h src/kseq.h
src/kstring.o: src/kstring.h
src/ksw.o: src/ksw.h src/macro.h
src/kswv.o: src/kswv.h src/macro.h src/ksw.h src/bandedSWA.h
src/kthread.o: src/kthread.h src/macro.h src/bwamem.h src/bwt.h src/bntseq.h
src/kthread.o: src/bwa.h src/bandedSWA.h src/kstring.h src/ksw.h src/kvec.h
src/kthread.o: src/ksort.h src/utils.h src/profiling.h src/FMI_search.h
src/kthread.o: src/read_index_ele.h
src/main.o: src/main.h src/kstring.h src/utils.h src/macro.h src/bandedSWA.h
src/main.o: src/profiling.h
src/profiling.o: src/macro.h
src/read_index_ele.o: src/read_index_ele.h src/utils.h src/bntseq.h
src/read_index_ele.o: src/macro.h
src/utils.o: src/utils.h src/ksort.h src/kseq.h
