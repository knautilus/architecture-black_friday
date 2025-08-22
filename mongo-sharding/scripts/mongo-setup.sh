#!/bin/bash

echo Инициализация сервера конфигурации

mongosh --host configSrv:27017 --eval "
rs.initiate(
  {
    _id : 'config_server',
    configsvr: true,
    members: [
      { _id : 0, host : 'configSrv:27017' }
    ]
  }
);"

echo Инициализация Shard 1

mongosh --host shard1:27018 --eval "
    rs.initiate(
      {
        _id : 'shard1',
        members: [
          { _id : 0, host : 'shard1:27018' },
        ]
      }
    );
"

echo Инициализация Shard 2

mongosh --host shard2:27021 --eval "
    rs.initiate(
      {
        _id : 'shard2',
        members: [
          { _id : 1, host : 'shard2:27021' },
        ]
      }
    );
"

echo Инициализация роутера и заливка данных

mongosh --host mongos_router:27024 --eval "
    sh.addShard('shard1/shard1:27018');
    sh.addShard('shard2/shard2:27021');
    sh.enableSharding('somedb');
    sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' } );
"

mongosh --host mongos_router:27024 --eval "
    db = db.getSiblingDB('somedb');
    for(var i = 0; i < 1000; i++)
    {
      db.helloDoc.insertOne({age:i, name:'ly'+i});
    }
    print('Total:', db.helloDoc.countDocuments())
"

mongosh --host shard1:27018 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard1:', db.helloDoc.countDocuments())
"

mongosh --host shard2:27021 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard2:', db.helloDoc.countDocuments())
"