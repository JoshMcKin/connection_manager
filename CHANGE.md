ConnectionManager Changelog
=====================

HEAD
=======
- None yet!

1.0.3
=======
- Fix issue where ActiveRecord::ConnectionNotEstablished error is raised in Rails app with Engine that requires delayed/backend/active_record

1.0.2
=======
- ActiveRecord 4.1 compatibility
- Refactor Using to make use of active record relations
- Better cross schema patching, make sure AR < 3.2 loads