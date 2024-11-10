# gcloud dataproc clusters create ${CLUSTER_NAME} --enable-component-gateway \
# 	--region ${REGION} --subnet default --public-ip-address \
# 	--master-machine-type n2-standard-4 --master-boot-disk-size 50 \
# 	--num-workers 2 --worker-machine-type n2-standard-2 --worker-boot-disk-size 50 \
# 	--image-version 2.2-debian12 \
# 	--project ${PROJECT_ID} --max-age=3h

# export PROJECT=bigdata-2024-10-tl;export HOSTNAME=pbd-cluster-m;export ZONE=europe-west4-a

# PORT1=8080
# PORT2=8080

# gcloud compute ssh ${HOSTNAME} \
# 	--project=${PROJECT} --zone=${ZONE}  -- \
# 	-4 -N -L ${PORT1}:${HOSTNAME}:${PORT2}

GENERATE_NEW=true
RUN_MR=true
RUN_HIVE=true

USER="lawicki02"
MAPREDUCE_INPUT="input/datasource1"
MAPREDUCE_OUTPUT="output-mapreduce"
HIVE_MR_INPUT="/user/$USER/$MAPREDUCE_OUTPUT"
HIVE_DS_INPUT="/user/$USER/input/datasource4"
HIVE_OUTPUT="/user/$USER/final"

# DATA google cloude bucket 
echo "---------------[ DATA: bucket ]---------------"
BUCKET_NAME="pbd-23-tl-fr"
if ! hdfs dfs -test -d /path/to/hdfs/directory || [ "$GENERATE_NEW" = true ]; then
  echo "The input directory does not exist in HDFS or the GENERATE_NEW variable is true."
  wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
  unzip zestaw7
  rm zestaw7.zip
  hadoop fs -rm -r gs://$BUCKET_NAME/input
  hadoop fs -mkdir -p gs://$BUCKET_NAME/input
  hadoop fs -put ./input/* gs://$BUCKET_NAME/input
else 
  echo "The input directory aleardy exist in hadoop"
fi

# DATA hadoop fs
# echo "---------------[ DATA: hadoop ]---------------"
# wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
# unzip zestaw7
# rm zestaw7.zip
# hadoop fs -mkdir -p input
# hadoop fs -put ./input/* input

# MAPREDUCE
echo "---------------[ MAPREDUCE ]---------------"
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
if [ "$RUN_MR" == true ]; then
	./mapreduce.sh
fi

#save mapreduce in bucket
hadoop fs -rm -r gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT
hadoop fs -mkdir -p gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT
hadoop fs -put ./input/* gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT

# HIVE
echo "---------------[ HIVE ]---------------"
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
if [ "$RUN_HIVE" == true ]; then
	./hive.sh
fi

# APACHE-AIRFLOW
echo "------------[ APACHE-AIRFLOW ]------------"
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/projekt1.py

pip install apache-airflow
export PATH=$PATH:~/.local/bin
airflow db migrate

mkdir -p ~/airflow/dags/project_files
cp projekt1.py ~/airflow/dags/
cp *.* ~/airflow/dags/project_files
airflow standalone

