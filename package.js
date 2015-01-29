Package.describe({
  summary: 'CQRS and Event Sourcing Infrastructure for Meteor.',
  name: 'space:cqrs',
  version: '2.3.0',
  git: 'https://github.com/CodeAdventure/space-cqrs.git',
});

Package.onUse(function(api) {

  api.versionsFrom("METEOR@1.0");

  api.use([
    'coffeescript',
    'ejson',
    'space:base@1.2.6'
  ]);

  api.addFiles(['source/client.coffee'], 'client');
  api.addFiles(['source/server.coffee'], 'server');

  // ========= SHARED =========

  api.addFiles([
    'source/configuration.coffee',
    'source/infrastructure/serializable.coffee',
    // DOMAIN
    'source/domain/command.coffee',
    'source/domain/value_object.coffee',
    // INFRASTRUCTURE
    'source/infrastructure/command_bus.coffee'
  ]);

  // ========= server =========

  api.addFiles([
    // INFRASTRUCTURE
    'source/infrastructure/aggregate_repository.coffee',
    'source/infrastructure/process_manager_repository.coffee',
    'source/infrastructure/event_bus.coffee',
    'source/infrastructure/commit_collection.coffee',
    'source/infrastructure/commit_store.coffee',
    'source/infrastructure/commit_publisher.coffee',
    'source/infrastructure/message_handler.coffee',
    // DOMAIN
    'source/domain/event.coffee',
    'source/domain/aggregate.coffee',
    'source/domain/process_manager.coffee',

  ], 'server');

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'space:cqrs',
    'practicalmeteor:munit@2.0.2',
    'space:testing@1.3.0'
  ]);

  api.addFiles([
    // DOMAIN
    'tests/domain/aggregate.unit.coffee',
    'tests/domain/event.unit.coffee',
    'tests/domain/process_manager.unit.coffee',
    // INFRASTRUCTURE
    'tests/infrastructure/commit_collection.unit.coffee',
    'tests/infrastructure/commit_store.unit.coffee',
    'tests/infrastructure/commit_publisher.unit.coffee',
    // MODULE
    'tests/server_module.unit.coffee',
    'tests/server_module.integration.coffee',
  ], 'server');

});
