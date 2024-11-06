wget http://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/zestaw7.zip
unzip zestaw7
rm zestaw7.zip
hadoop fs -mkdir -p input
hadoop fs -put ./input/* input

wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/mapper.py
wget https://raw.githubusercontent.com/Free-Rat/big-data-project-1/refs/heads/main/reducer.py
sudo chmod +x mapper.py
sudo chmod +x reducer.py

mapred streaming -files mapper.py,reducer.py -input input/datasource1 -output output -mapper mapper.py -reducer reducer.py

