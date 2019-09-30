#!/bin/bash


##########################################################################
##   This script will used to create a master BOM file of given prouct  ##
##   pack.      														##
##########################################################################

read -p "Enter product ZIP file path: " pack_zip_path
read -p "Enter output folder name: " output_dir

temp_dir=$(mktemp -d)
cp -R $pack_zip_path $temp_dir
cd $temp_dir

# --------------------------------------
# Unzip source
# --------------------------------------

zip_file_name=$(ls )
mkdir working_dir
unzip $temp_dir/$zip_file_name -d $temp_dir/working_dir

#command to unzip jar recursively

cd $temp_dir/working_dir
src_file_name=$(ls )
cd $temp_dir/working_dir/$src_file_name

# Unzip jar files
for JAR_FILE in $(find -name *.jar)
	do
		jar -xf $JAR_FILE
		echo $JAR_FILE " is extracted"
	done

# executes `mvn clean install` in any directory where pom.xml was found
find . -name pom.xml -execdir mvn org.owasp:dependency-check-maven:5.2.1:aggregate \;

#------------------------------------optional--------------------------------------#
# cyclonedx-maven-plugin:1.4.2-SNAPSHOT contains the modifications to remove transitive 
# dependencies of third party dependency when execute cyclonedx. Following command is to
# create bom file using modified cyclonedx artifact.
# find . -name pom.xml -execdir mvn org.cyclonedx:cyclonedx-maven-plugin:1.4.2-SNAPSHOT:makeAggregateBom \;

# Aggregate all bom file to master bom file
find -name "bom.xml" >> bomFileList.txt
head -n 3 $(head -n 1 bomFileList.txt) >> $output_dir/bom.xml
for file in $(cat $temp_dir/working_dir/$src_file_name/bomFileList.txt)
do 
	echo -------------------------------------------------------------
	echo $file
	# Retrieve all components in bom.xml
	sed -n '/<component /,/<\/component/p' $file >> $output_dir/bom.xml
done

# Generate master bom file in given out put directory
tail -n 2 $(head -n 1 bomFileList.txt) >> $output_dir/bom.xml
