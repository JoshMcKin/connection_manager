ConnectionManager Changelog
=====================

HEAD
=======
BREAKING CHANGE - Code has been organized to mirror as much a possible their ActiveRecord 4 counter parts. API remains relatively they same
but ConnectManager modules were not where their were.
BREAKING CHANGE - Drop support for forced readonly, should be enforced by DMS and #readonly ActiveRecord::Relation
BREAKING CHANGE - create AR::Relation for :slaves and :masters, replication methods are no longer customizable
- Make sure all connections are checked in to managed_connections
- Use thread-safe for managed_connections
- Don't try and fetch schema, too slow and buggy, we want a light weight implementation

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