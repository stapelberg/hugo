#!/bin/sh
for i in `ls -1`; do
	echo "Handling ${i}..."	
	sed 's///g' ${i} > wol${i}
	rm ${i}
	mv wol${i} ${i}
done
