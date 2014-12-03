Package.describe({
  summary: 'CQRS and Event Sourcing Infrastructure for Meteor.',
  name: 'space:cqrs',
  version: '2.1.6',
  git: 'https://github.com/CodeAdventure/space-cqrs.git',
});

Package.onUse(function(api) {

  api.versionsFrom("METEOR@0.9.4");

  api.use([
    'coffeescript',
    'space:base@1.1.0'
  ]);

  // ========= server =========

  api.addFiles([

    'source/server.coffee',

    // DOMAIN
    'source/domain/event.coffee',
    'source/domain/aggregate_root.coffee',
    'source/domain/saga.coffee',

    // INFRASTRUCTURE
    'source/infrastructure/aggregate_repository.coffee',
    'source/infrastructure/saga_repository.coffee',
    'source/infrastructure/event_bus.coffee',
    'source/infrastructure/commit_collection.coffee',
    'source/infrastructure/commit_store.coffee',
    'source/infrastructure/commit_publisher.coffee',
    'source/infrastructure/message_handler.coffee',

  ], 'server');

  // ========= client =========

  api.addFiles([
    'source/client.coffee',
  ], 'client');

  // ========= shared =========

  api.addFiles([
    'source/configuration.coffee',
    // DOMAIN
    'source/domain/command.coffee',
    // INFRASTRUCTURE
    'source/infrastructure/command_bus.coffee'
  ]);

});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'space:cqrs',
    'spacejamio:munit@2.0.2',
    'space:testing@1.1.0'
  ]);

  api.addFiles([

    // DOMAIN
    'tests/domain/aggregate_root.unit.coffee',
    'tests/domain/event.unit.coffee',
    'tests/domain/saga.unit.coffee',

    // INFRASTRUCTURE
    'tests/infrastructure/commit_collection.unit.coffee',
    'tests/infrastructure/commit_store.unit.coffee',
    'tests/infrastructure/commit_publisher.unit.coffee',

    // MODULE
    'tests/server_module.unit.coffee',
    'tests/server_module.integration.coffee',

  ], 'server');

});