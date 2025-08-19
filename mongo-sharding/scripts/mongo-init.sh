#!/bin/bash

echo Инициализация сервера конфигурации

mongosh --host configSrv:27017 --eval '
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);'

echo Инициализация Shard 1

mongosh --host shard1:27018 --eval '
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1:27018" },
    ]
  }
);'

echo Инициализация Shard 2

mongosh --host shard2:27019 --eval '
rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2:27019" },
    ]
  }
);'

echo Инициализация роутера и заливка данных

sleep 10

mongosh --host mongos_router:27020 --eval '
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})'

