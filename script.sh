wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
unzip zestaw7
rm zestaw7.zip
hadoop fs -mkdir -p input
hadoop fs -put ./input/* input

wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/mapper.py
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/reducer.py
sudo chmod +x mapper.py
sudo chmod +x reducer.py

echo '
hadoop fs -rm -r output
mapred streaming -files mapper.py,reducer.py -input input/datasource1 -output output -mapper "python3 mapper.py" -reducer "python3 reducer.py"
' > mapreduce.sh
sudo chmod +x mapreduce.sh
./mapreduce.sh

wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/top_manufacturers_by_state.hql

echo "
beeline -n \${USER} -u jdbc:hive2://localhost:10000/default -f top_manufacturers_by_state.hql
" > hive.sh
sudo chmod +x hive.sh
./hive	
