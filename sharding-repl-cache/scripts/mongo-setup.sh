#!/bin/bash

echo Инициализация сервера конфигурации

until mongosh --host configSrv:27017 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done 
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

until mongosh --host shard1_r1:27018 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
until mongosh --host shard1_r2:27019 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
until mongosh --host shard1_r3:27020 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
mongosh --host shard1_r1:27018 --eval "
    rs.initiate(
      {
        _id : 'shard1',
        members: [
          { _id : 0, host : 'shard1_r1:27018', priority : 3 },
          { _id : 1, host : 'shard1_r2:27019', priority : 2 },
          { _id : 2, host : 'shard1_r3:27020', priority : 1 }
        ]
      }
    );
"

echo Инициализация Shard 2

until mongosh --host shard2_r1:27021 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
until mongosh --host shard2_r2:27022 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
until mongosh --host shard2_r3:27023 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done
mongosh --host shard2_r1:27021 --eval "
    rs.initiate(
      {
        _id : 'shard2',
        members: [
          { _id : 0, host : 'shard2_r1:27021', priority : 3 },
          { _id : 1, host : 'shard2_r2:27022', priority : 2 },
          { _id : 2, host : 'shard2_r3:27023', priority : 1 }
        ]
      }
    );
"

echo Инициализация роутера и заливка данных

until mongosh --host mongos_router:27024 --eval 'db.adminCommand("ping")' | grep 'ok'; do sleep 2; done

mongosh --host mongos_router:27024 --eval "
    sh.addShard('shard1/shard1_r1:27018,shard1_r2:27019,shard1_r3:27020');
    sh.addShard('shard2/shard2_r1:27021,shard2_r2:27022,shard2_r3:27023');
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

mongosh --host shard1_r1:27018 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard1-1:', db.helloDoc.countDocuments())
"

mongosh --host shard1_r2:27019 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard1-2:', db.helloDoc.countDocuments())
"

mongosh --host shard1_r3:27020 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard1-3:', db.helloDoc.countDocuments())
"

mongosh --host shard2_r1:27021 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard2-1:', db.helloDoc.countDocuments())
"

mongosh --host shard2_r2:27022 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard2-2:', db.helloDoc.countDocuments())
"

mongosh --host shard2_r3:27023 --eval "
    db = db.getSiblingDB('somedb');
    print('Shard2-3:', db.helloDoc.countDocuments())
"