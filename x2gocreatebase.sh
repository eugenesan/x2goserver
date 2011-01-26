#!/bin/bash

su postgres -c "dropdb x2go_sessions"
su postgres -c "createdb x2go_sessions"
su postgres -c "echo \"create table sessions(
		session_id varchar(500) primary key, 
                display integer not null, 
		uname varchar(100) not null, 
		server varchar(100) not null,
		client inet,
		status char(1) not null default 'R',
		init_time timestamp not null default now(),
		last_time timestamp not null default now(),
		cookie char(33),
		agent_pid int,
		gr_port int,
		sound_port int,
		fs_port int,
		unique(display)
		)\" | psql x2go_sessions"

su postgres -c "echo \"create table messages(mess_id varchar(20) primary key, message text)\" | psql x2go_sessions"

su postgres -c "echo \"create table user_messages(
                mess_id varchar(20) not null, 
		uname varchar(100) not null
		)\" | psql x2go_sessions"

su postgres -c "echo \"create table used_ports(
                server varchar(100) not null,
		session_id varchar(500) references sessions on delete cascade, 
		port integer primary key
		)\" | psql x2go_sessions"

su postgres -c "echo \"create table mounts(
                session_id varchar(500) references sessions on delete restrict,
		path varchar(512) not null, 
		client inet not null, 
		primary key(path,client)
		)\" | psql x2go_sessions"


