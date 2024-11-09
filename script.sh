
USER="lawicki02"
MAPREDUCE_INPUT="input/datasource1"
MAPREDUCE_OUTPUT="output-mapreduce"
HIVE_MR_INPUT="/user/$USER/$MAPREDUCE_OUTPUT"
HIVE_DS_INPUT="/user/$USER/input/datasource4"
HIVE_OUTPUT="/user/$USER/final"

# DATA google cloude bucket 
BUCKET_NAME="pbd-23-tl-fr"
wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
unzip zestaw7
rm zestaw7.zip
hadoop fs -rm -r gs://$BUCKET_NAME/input
hadoop fs -mkdir -p gs://$BUCKET_NAME/input
hadoop fs -put ./input/* gs://$BUCKET_NAME/input

# DATA hadoop fs
# wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
# unzip zestaw7
# rm zestaw7.zip
# hadoop fs -mkdir -p input
# hadoop fs -put ./input/* input

# MAPREDUCE
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/mapper.py
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/reducer.py
sudo chmod +x mapper.py
sudo chmod +x reducer.py

echo "
hadoop fs -rm -r output
mapred streaming \
	-files mapper.py,reducer.py \
	-input $MAPREDUCE_INPUT \
	-output $MAPREDUCE_OUTPUT \
	-mapper \"python3 mapper.py\" \
	-reducer \"python3 reducer.py\"
" > mapreduce.sh
sudo chmod +x mapreduce.sh
./mapreduce.sh

# HIVE
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/top_manufacturers_by_state.hql

echo "
beeline \
	-n \${USER} \
	-u jdbc:hive2://localhost:10000/default \
    -f top_manufacturers_by_state.hql \
    --hiveconf input_dir3='$HIVE_MR_INPUT' \
    --hiveconf input_dir4='$HIVE_DS_INPUT' \
    --hiveconf output_dir6='$HIVE_OUTPUT'
" > hive.sh
sudo chmod +x hive.sh
./hive.sh

wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/project1.py

pip install apache-airflow
export PATH=$PATH:~/.local/bin
airflow db migrate

mkdir -p ~/airflow/dags/project_files
cp projekt1.py ~/airflow/dags/
cp *.* ~/airflow/dags/project_files


