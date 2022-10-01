# pg-fdw-demo <!-- omit in toc -->

- [prerequisites](#prerequisites)
- [setup](#setup)
  - [namespace](#namespace)
  - [postgresql](#postgresql)
    - [create instances](#create-instances)
    - [on local instance](#on-local-instance)
- [operations](#operations)
  - [on local instance](#on-local-instance-1)
- [cleanup](#cleanup)
- [references](#references)

A **foreign data wrapper(fdw)** is an extension available in **PostgreSQL** that allows you to access a table or schema in one database from another.

In this repo, we are using the [Kubernetes](https://kubernetes.io/) to deploy the Postgresql instances.

## prerequisites

- [Rancher Desktop](https://github.com/rancher-sandbox/rancher-desktop): `1.4.1`
- Kubernetes: `v1.24.3`
- kubectl `v1.23.3`
- Helm: `v3.9.0`

## setup

tl;dr: `./scripts/up.sh`

### namespace

```sh
kubectl create namespace pg-dfw-demo --dry-run=client -o yaml | kubectl apply -f -
```

### postgresql

follow the [bitnami postgresql chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) to install postgresql

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami
```

#### create instances

```sh
helm upgrade --install local-postgresql bitnami/postgresql -n pg-dfw-demo -f postgresql/local.yaml
helm upgrade --install foreign-postgresql bitnami/postgresql -n pg-dfw-demo -f postgresql/foreign.yaml
```

#### on local instance

login to the postgresql

```sh
kubectl run local-postgresql-client --rm --tty -i --restart='Never' --namespace pg-dfw-demo --image docker.io/bitnami/postgresql:14.5.0-debian-11-r21 --env="PGPASSWORD=demo_password" --command -- psql --host local-postgresql -U postgres -d postgres -p 5432
```

create a FDW extension and a postgresql foreign server

```sql
CREATE EXTENSION postgres_fdw;
CREATE SERVER foreign_pg_svr FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'foreign-postgresql', port '5432', dbname 'postgres');
```

create the user mapping

```sql
CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_pg_svr OPTIONS (user 'foreign_user', password 'foreign_user_password');
```

create the schema

```sql
CREATE SCHEMA foreign_pg;
```

import the foreign schema

```sql
IMPORT FOREIGN SCHEMA "public" FROM SERVER foreign_pg_svr INTO foreign_pg;
```

## operations

### on local instance

login to the postgresql

```sh
kubectl run local-postgresql-client --rm --tty -i --restart='Never' --namespace pg-dfw-demo --image docker.io/bitnami/postgresql:14.5.0-debian-11-r21 --env="PGPASSWORD=demo_password" --command -- psql --host local-postgresql -U postgres -d postgres -p 5432
```

list all foreign tables

```sql
SET search_path=foreign_pg;
\det;

          List of foreign tables
   Schema   |   Table    |     Server
------------+------------+----------------
 foreign_pg | test_table | foreign_pg_svr
 foreign_pg | users      | foreign_pg_svr
(2 rows)
```

read from foreign tables

```sql
select count(*) from foreign_pg.users;
 count
-------
 10000
(1 row)
```

write into the foreign tables

```sql
insert into foreign_pg.test_table(id) values (42);
```

## cleanup

tl;dr: `./scripts/down.sh`

```sh
helm uninstall local-postgresql -n pg-dfw-demo
helm uninstall foreign-postgresql -n pg-dfw-demo
kubectl delete pvc --all -n pg-dfw-demo
kubectl delete namespace pg-dfw-demo
```

## references

- [F.35. postgres_fdw](https://www.postgresql.org/docs/current/postgres-fdw.html)
