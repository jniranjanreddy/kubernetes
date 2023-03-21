## postgresql check connection
```
kubectl exec -it postgres-5d46b88759-ldlcc -- psql -h localhost -U admin --password -p 5432 postgresdb
Password for user admin:
psql (10.1)
Type "help" for help.

postgresdb=#
```
