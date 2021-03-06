#!/usr/bin/ruby

require 'rubygems'
require 'sqlite3'

def get_hostnum(db)
hostnum=0
begin
	db.transaction(mode=:exclusive) do
		sql="select value from cluster where prop='instances_num';"
		hostnum=db.get_first_value(sql)
		sql="update cluster set value=(select value from cluster where prop='instances_num')+1 where prop='instances_num';"
		db.execute(sql)
	end
rescue => e
end
puts hostnum
end

def add_hostinfo(db)
begin
	settings = Hash.new
	open(ARGV.shift+"/host_settings.sh").read.split.each do |line|
		settings["#{$1}"] = $2 if line =~ /(.*)="(.*)"/
	end
	db.transaction do
		sql = "insert into instances values (?, ?, ?, ?)"
		db.execute(sql, nil, settings["instance_id"], "hostname", settings["hostname"])
		db.execute(sql, nil, settings["instance_id"], "hostnum", settings["hostnum"])
		db.execute(sql, nil, settings["instance_id"], "vpn_address", settings["vpn_addr"])
		db.execute(sql, nil, settings["instance_id"], "inst_pubip", settings["inst_pubip"])
		if settings["hostnum"] == "1"
			sql = "insert into cluster values (?, ?, ?)"
			db.execute(sql, nil, "vpn_address_master", settings["vpn_addr"])
		end
	end
rescue => e
	puts e.inspect
end
end

if ARGV.size < 2
	exit 0
end

dbpath = ARGV.shift
operation = ARGV.shift

while true
	begin
		$db = SQLite3::Database.new(dbpath)
		$db.busy_handler do |retries|
			(retries<=10)
		end
		$db.busy_timeout(1000+(rand * 100).ceil/100.0)
		break
	rescue => e
		puts e.inspect
		sleep 1+(rand * 100).ceil/100.0
	end
end

case operation
	when 'get_hostnum'
		get_hostnum($db)
	when 'add_hostinfo'
		add_hostinfo($db)
end
$db.close if $db

