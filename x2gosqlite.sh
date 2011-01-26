#!/bin/bash

DATABASE=/var/db/x2go/x2go_sessions

#rm $DATABASE

echo "create table sessions(
		session_id varchar(500) primary key,
                display integer not null, 
		uname varchar(100) not null, 
		server varchar(100) not null,
		client inet,
		status char(1) not null default 'R',
		init_time timestamp not null default CURRENT_TIMESTAMP,
		last_time timestamp not null default CURRENT_TIMESTAMP,
		cookie char(33),
		agent_pid int,
		gr_port int,
		sound_port int,
		fs_port int,
		unique(display)
		);" | sqlite $DATABASE


echo "create table messages(mess_id varchar(20) primary key, message text);" | sqlite $DATABASE

echo "create table user_messages(
                mess_id varchar(20) not null, 
		uname varchar(100) not null
		);" | sqlite $DATABASE


echo "create table used_ports(
                server varchar(100) not null,
		session_id varchar(500) references sessions on delete cascade, 
		port integer primary key
		);" | sqlite $DATABASE

echo "create table mounts(
                session_id varchar(500) references sessions on delete restrict,
		path varchar(512) not null, 
		client inet not null, 
		primary key(path,client)
		);" | sqlite $DATABASE

echo "CREATE TRIGGER fkd_mounts_session_id
BEFORE DELETE ON sessions
FOR EACH ROW BEGIN 
  SELECT CASE
    WHEN ((SELECT session_id FROM mounts WHERE session_id = OLD.session_id) IS NOT NULL)
    THEN RAISE(ABORT, 'delete on table \"sessions\" violates foreign key on table \"mounts\"')
  END;
END;" | sqlite $DATABASE
            
