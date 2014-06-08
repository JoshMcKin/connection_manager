ConnectionManager Changelog
=====================

HEAD
=======
- Nothing yet!

1.1.0
=======
- BREAKING CHANGE - Code has been organized to mirror as much a possible their ActiveRecord 4 counter parts.
- BREAKING CHANGE - creates AR::Relation for :slaves and :masters, replication method names are no longer customizable
- BREAKING CHANGE - Drop support for forced readonly, should be enforced by DMS and or using #readonly ActiveRecord::Relation
- BREAKING CHANGE - Drop use_schema in favor of schema_name=
- BREAKING CHANGE - Drop current_database_name in favor of schema_name
- Make sure all connections are checked in to managed_connections by patch establish_connection
- Use thread-safe for managed_connections
- Don't try and fetch schema using query, too slow and buggy, we want a light weight implementation, but still get it from database.yml if Mysql and not set

1.0.4
=======
- Stop duping classes for using, use proxy that returns instance of Class query is called on.

1.0.3
=======
- Fix issue where ActiveRecord::ConnectionNotEstablished error is raised in Rails app with Engine that requires delayed/backend/active_record

1.0.2
=======
- ActiveRecord 4.1 compatibility
- Refactor Using to make use of active record relations
- Better cross schema patching, make sure AR < 3.2 loads