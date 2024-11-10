# gcloud dataproc clusters create ${CLUSTER_NAME} --enable-component-gateway \
# 	--region ${REGION} --subnet default --public-ip-address \
# 	--master-machine-type n2-standard-4 --master-boot-disk-size 50 \
# 	--num-workers 2 --worker-machine-type n2-standard-2 --worker-boot-disk-size 50 \
# 	--image-version 2.2-debian12 \
# 	--project ${PROJECT_ID} --max-age=3h
#
# gcloud dataproc clusters create ${CLUSTER_NAME} \
# --enable-component-gateway --bucket ${BUCKET_NAME} \
# --region ${REGION} --subnet default \
# --master-machine-type n1-standard-4 --master-boot-disk-size 50 \
# --num-workers 2 \
# --worker-machine-type n1-standard-2 --worker-boot-disk-size 50 \
# --image-version 2.1-debian11 \
# --optional-components DOCKER \
# --project ${PROJECT_ID} --max-age=3h

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
BUCKET_NAME="pbd-23-tl-fr"

# gs://pbd-23-tl-fr/projekt1/input
PROJECT_PATH="gs://$BUCKET_NAME/projekt1"
INPUT_DIR="$PROJECT_PATH/input"

MAPREDUCE_INPUT="$INPUT_DIR/datasource1"
MAPREDUCE_OUTPUT="$PROJECT_PATH/output-mapreduce"

HIVE_MR_INPUT="$PROJECT_PATH/output-mapreduce"
HIVE_DS_INPUT="$INPUT_DIR/datasource4"
HIVE_OUTPUT="$PROJECT_PATH/final"

# DATA google cloude bucket 
echo "---------------[ DATA: bucket ]---------------"
if ! hdfs dfs -test -d $INPUT_DIR || [ "$GENERATE_NEW" = true ]; then
  echo "The input directory does not exist in HDFS or the GENERATE_NEW variable is true."
  wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
  unzip zestaw7
  rm zestaw7.zip
  hadoop fs -rm -r $INPUT_DIR
  hadoop fs -mkdir -p $INPUT_DIR
  hadoop fs -put ./input/* $INPUT_DIR
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
mapred streaming \
	-files mapper.py,reducer.py \
	-input $MAPREDUCE_INPUT \
	-output $MAPREDUCE_OUTPUT \
	-mapper \"python3 mapper.py\" \
	-reducer \"python3 reducer.py\"
" > mapreduce.sh
sudo chmod +x mapreduce.sh
if [ "$RUN_MR" == true ]; then
	hadoop fs -rm -r output
  	hadoop fs -rm -r $HIVE_MR_INPUT	 
	./mapreduce.sh
fi

#save mapreduce in bucket
# hadoop fs -rm -r gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT
# hadoop fs -mkdir -p gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT
# hadoop fs -copyToLocal $MAPREDUCE_OUTPUT .
# hadoop fs -put ./$MAPREDUCE_OUTPUT gs://$BUCKET_NAME/$MAPREDUCE_OUTPUT

# HIVE
echo "---------------[ HIVE ]---------------"
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/top_manufacturers_by_state.hql

echo "
beeline \
	-n \${USER} \
	-u jdbc:hive2://localhost:10000/default \
    -f top_manufacturers_by_state.hql \
    --hiveconf input_dir1='$HIVE_MR_INPUT' \
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

export AIRFLOW_HOME=~/airflow
pip install apache-airflow
export PATH=$PATH:~/.local/bin
airflow db migrate

mkdir -p ~/airflow/dags/project_files
cp projekt1.py ~/airflow/dags/
cp *.* ~/airflow/dags/project_files
airflow standalone

