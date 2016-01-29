Space.Struct.extend('Space.eventSourcing.Snapshot', {

  mixin: [
    Space.messaging.Ejsonable
  ],

  fields() {
    return {
      id: Match.OneOf(String, Guid),
      version: Match.Integer,
      state: Match.OneOf(null, String),
      meta: Match.Optional(Object)
    };
  }
});
