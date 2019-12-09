rm -rf tmp1.txt
rm -rf tmp2.txt
rm -rf tmp3.txt
touch tmp1.txt
touch tmp2.txt
touch tmp3.txt

if [[ $3 == "lib" ]]
then
	PARAM=".a"
else
	PARAM=""
fi

#libs
if [[ $(echo $2 | grep "r") != "" ]]
then
for i in $(ls -d */)
do
	if [[ $i != "src/" && $i != "inc/" && $i != "test/" && $i != "tests/" ]]
	then
		echo $i | tr '/' ' ' | sed 's/ //' >> tmp2.txt
	fi
done
fi

#include
cd src
INC=$(ls -1 *.c)
cd ..
echo $INC | tr ' ' '\n' | sed 's/.$//' | sed 's/.$//' >> tmp1.txt


if [[ $(echo $2 | grep "h") != "" ]]
then
FILE="inc/${1}.h"
if [[ -e $FILE ]]
then
	IND="0"
	while read LINE
	do  
		temp=$(echo $LINE | grep "//") 
		if [[ $temp != "" ]]
		then
			IND="1"
		fi

		temp=$(echo $LINE | grep "typedef") 
		if [[ $temp != "" ]]
		then
			IND="1"
		fi

		temp2=$(echo $LINE | grep "}") 
		if [[ $temp2 != "" ]]
		then
			if [[ $IND == "1" ]]
			then
				echo "$LINE\n"  >> tmp3.txt
				IND="0"
	        else
				IND="0"
			fi
		fi	

		if [[ $IND == "1" ]]
		then
			echo $LINE  >> tmp3.txt
		fi
	done < $FILE
fi


mv inc/$1.h inc/$1_old.h
rm -rf inc/$1.h
touch inc/$1.h
echo "#ifndef ${1}_h\n#define ${1}_h\n\n#include <stdlib.h>\n#include <unistd.h>\n#include <stdbool.h>\n#include <fcntl.h>\n\n" >> "inc/${1}.h"
cat tmp3.txt >> "inc/${1}.h"
for i in $(cat tmp1.txt)
do
    cat "src/${i}.c" | grep "${i}" | head -1| tr '{' ';' | sed 's/ ;/;/'  >> "inc/${1}.h"
done

if [[ $(echo $2 | grep "r") != "" ]]
then
LIBS=""
for i in $(cat tmp2.txt)
do
	LIBS="$LIBS $i.a"
	FILE="$i/inc/$i.h"
	if [[ -e $FILE ]]
	then
		echo "\n\n//$i" >> "inc/${1}.h"
		while read LINE
			do  
			temp=$(echo $LINE | grep "$i") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    temp=$(echo $LINE | grep "#ifndef") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    temp=$(echo $LINE | grep "#ifdef") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    temp=$(echo $LINE | grep "#endif") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    temp=$(echo $LINE | grep "#include") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    temp=$(echo $LINE | grep "#pragma") 
			if [[ $temp != "" ]]
			then
				continue
		    fi

		    echo $LINE >> "inc/${1}.h"
		done < $FILE
	fi
done
fi
echo "#endif\n" >> "inc/${1}.h"
fi


#Makefile

if [[ $(echo $2 | grep "m") != "" ]]
then
cp -f Makefile Makefile_old.txt
rm -rf Makefile
touch Makefile
echo "NAME = ${1}${PARAM}\n\nCFLAG = -std=c11 -Wall -Wextra -Werror -Wpedantic\n\nLIBS = $(cat tmp2.txt | tr '\n' ' '| sed 's/ /.a /')\n\nINC = inc/${1}.h\n\nINCS = ${1}.h\n" >> Makefile

SRCS=""
SRC=""
OBJS=""
OBJ=""

for i in $(cat tmp1.txt)
do
	SRCS="$SRCS $i.c"
	SRC="$SRC src/$i.c"
   	if [[ $3 == "lib" ]]
   	then
		OBJS="$OBJS $i.o"
		OBJ="$OBJ obj/$i.o"
	fi
done
echo "SRC = ${SRC}\n" >> Makefile
echo "SRCS = ${SRCS}\n" >> Makefile
if [[ $3 == "lib" ]] 
then
	echo "OBJ_DIR = obj\n" >> Makefile
	echo "OBJ = ${OBJ}\n" >> Makefile
	echo "OBJS = ${OBJS}\n" >> Makefile
fi

#all
echo "\nall: install uninstall" >> Makefile

#install
echo "install:" >> Makefile
if [[ $3 == "lib" ]]
then
	echo "\t@mkdir -p \$(OBJ_DIR)\n\t@cp \$(SRC) .\n\t@cp \$(INC) .\n\t@clang \$(CFLAG) -c \$(SRCS) -I \$(INCS)\n\t@cp \$(OBJS) \$(OBJ_DIR)\n\t@rm -rf \$(OBJS)\n\t@ar -cq \$(NAME) \$(OBJ)" >> Makefile
else
	for i in $(cat tmp2.txt)
	do
		echo "\t@make -C $i install\n\t@cp $i/$i.a ." >> Makefile
	done
	echo "\t@cp \$(SRC) .\n\t@cp \$(INC) .\n\t@clang \$(CFLAG) -o \$(NAME) \$(SRCS) -I \$(INCS) \$(LIBS)" >> Makefile
fi

#uninstall
echo "uninstall:\n\t@rm -rf \$(SRCS)\n\t@rm -rf \$(INCS)\n\t@rm -rf \$(OBJ_DIR)\n\t@rm -rf \$(LIBS)" >> Makefile
for i in $(cat tmp2.txt)
	do
		echo "\t@make -C $i uninstall" >> Makefile
	done

#clean
echo "clean: uninstall\n\t@rm -rf \$(NAME)" >> Makefile
for i in $(cat tmp2.txt)
	do
		echo "\t@make -C $i clean" >> Makefile
	done

#reinstall
echo "reinstall: uninstall install\n" >> Makefile
fi
rm -rf tmp1.txt
rm -rf tmp2.txt
rm -rf tmp3.txt